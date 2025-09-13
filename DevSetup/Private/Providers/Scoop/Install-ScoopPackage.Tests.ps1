BeforeAll {
    . $PSScriptRoot\Install-ScoopPackage.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\Uninstall-ScoopPackage.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\..\..\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1    
}

Describe "Install-ScoopPackage" {
    BeforeEach {
        $global:LASTEXITCODE = 0
        Mock Write-StatusMessage { }
        Mock Invoke-Command { $global:LASTEXITCODE = 0 }
        Mock Find-Scoop { return "scoop" }
        Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
        Mock Uninstall-ScoopPackage { return $true }
        Mock Write-ScoopCache { return $true }
    }

    Context "When Test-ScoopInstalled returns false" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $false }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should not call Find-Scoop" {
            Install-ScoopPackage -PackageName "git"
            Should -Not -Invoke Find-Scoop
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { throw "Scoop check failed" }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should log error message and stack trace" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-StatusMessage -Times 2 -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When Find-Scoop returns null" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should not call Test-ScoopComponentInstalled" {
            Install-ScoopPackage -PackageName "git"
            Should -Not -Invoke Test-ScoopComponentInstalled
        }
    }

    Context "When Find-Scoop throws an exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { throw "Find Scoop failed" }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should log error message and stack trace" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-StatusMessage -Times 2 -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When Test-ScoopComponentInstalled throws an exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { throw "Component check failed" }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should log error message with package name" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Failed to check if Scoop package 'git' is installed*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When package is already installed correctly" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
        }

        It "Should return true without installing" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }

        It "Should not execute Invoke-Command" {
            Install-ScoopPackage -PackageName "git"
            Should -Not -Invoke Invoke-Command
        }

        It "Should not call Write-ScoopCache" {
            Install-ScoopPackage -PackageName "git"
            Should -Not -Invoke Write-ScoopCache
        }

        It "Should not call Uninstall-ScoopPackage" {
            Install-ScoopPackage -PackageName "git"
            Should -Not -Invoke Uninstall-ScoopPackage
        }
    }

    Context "When package is installed but needs reinstallation" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $script:callCount = 0
            Mock Test-ScoopComponentInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { [InstalledState]::Installed } 
                else { [InstalledState]::Pass }
            }
            Mock Uninstall-ScoopPackage { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }
        }

        It "Should uninstall and reinstall successfully" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }

        It "Should call Uninstall-ScoopPackage" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Uninstall-ScoopPackage -Times 1 -ParameterFilter { $PackageName -eq "git" }
        }

        It "Should call Test-ScoopComponentInstalled twice" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Test-ScoopComponentInstalled -Times 2
        }
    }

    Context "When uninstalling existing package fails" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Installed }
            Mock Uninstall-ScoopPackage { throw "Uninstall failed" }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should log uninstall error with package name" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Failed to uninstall existing Scoop package 'git'*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When fresh package installation is successful" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $script:callCount = 0
            Mock Test-ScoopComponentInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { [InstalledState]::NotInstalled } 
                else { [InstalledState]::Pass }
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }
        }

        It "Should install basic package successfully" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $true
            Should -Invoke Invoke-Command -Times 1
        }

        It "Should install package with version" {
            $result = Install-ScoopPackage -PackageName "nodejs" -Version "18.17.0"
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter { 
                $Package -eq $true -and $Name -eq "nodejs" -and $Version -eq "18.17.0"
            }
        }

        It "Should install package with bucket" {
            $result = Install-ScoopPackage -PackageName "firefox" -Bucket "extras"
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter { 
                $Package -eq $true -and $Name -eq "firefox"
            }
        }

        It "Should install package globally" {
            $result = Install-ScoopPackage -PackageName "7zip" -Global
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter { 
                $Package -eq $true -and $Name -eq "7zip" -and $Global -eq $true
            }
        }

        It "Should install package with all parameters" {
            $result = Install-ScoopPackage -PackageName "python" -Version "3.11.5" -Bucket "main" -Global
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter { 
                $Package -eq $true -and $Name -eq "python" -and $Version -eq "3.11.5" -and $Global -eq $true
            }
        }

        It "Should update cache after successful installation" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-ScoopCache -Times 1
        }
    }

    Context "When installation command fails" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command { $global:LASTEXITCODE = 1 }
            Mock Write-ScoopCache { return $true }
        }

        It "Should return false when exit code is non-zero" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should not call Write-ScoopCache when installation fails" {
            Install-ScoopPackage -PackageName "git"
            Should -Not -Invoke Write-ScoopCache
        }

        It "Should not verify installation when command fails" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Test-ScoopComponentInstalled -Times 1  # Only initial check
        }
    }

    Context "When installation command throws exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command { throw "Install command failed" }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should log installation error with package name" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Failed to install Scoop package 'git'*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When cache update fails after installation" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $false }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should attempt cache update" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-ScoopCache -Times 1
        }
    }

    Context "When installation verification fails" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $script:callCount = 0
            Mock Test-ScoopComponentInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { [InstalledState]::NotInstalled } 
                else { throw "Verification failed" }
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }
        }

        It "Should return false" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "Should log verification error with package name" {
            Install-ScoopPackage -PackageName "git"
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Failed to verify installation of Scoop package 'git'*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When using WhatIf parameter" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }
        }

        It "Should not execute install command when WhatIf is specified" {
            $result = Install-ScoopPackage -PackageName "git" -WhatIf
            $result | Should -Be $true
            Should -Invoke Invoke-Command -Times 0 -Exactly
        }

        It "Should return true and log debug message when WhatIf is used" {
            $result = Install-ScoopPackage -PackageName "git" -WhatIf
            $result | Should -Be $true
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Skipping installation of Scoop package 'git' due to ShouldProcess*" -and $Verbosity -eq "Debug"
            } -Times 1 -Exactly
        }

        It "Should not call Write-ScoopCache when WhatIf is used" {
            Install-ScoopPackage -PackageName "git" -WhatIf
            Should -Invoke Write-ScoopCache -Times 0 -Exactly
        }

        It "Should still check if package is already installed with WhatIf" {
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
            $result = Install-ScoopPackage -PackageName "git" -WhatIf
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -Times 1 -Exactly
        }

        It "Should handle reinstallation scenario with WhatIf" {
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Installed }
            Mock Uninstall-ScoopPackage { return $true }
            
            $result = Install-ScoopPackage -PackageName "git" -WhatIf
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopPackage -ParameterFilter {
                $PackageName -eq "git" -and $WhatIf -eq $true
            } -Times 1 -Exactly
            Should -Invoke Invoke-Command -Times 0 -Exactly
        }

        It "Should work with all parameters and WhatIf" {
            $result = Install-ScoopPackage -PackageName "python" -Version "3.11.5" -Bucket "main" -Global -WhatIf
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Package -eq $true -and $Name -eq "python" -and $Version -eq "3.11.5" -and $Global -eq $true
            } -Times 1 -Exactly
            Should -Invoke Invoke-Command -Times 0 -Exactly
        }
    }

    Context "ShouldProcess functionality" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }
        }

        It "Should have SupportsShouldProcess attribute" {
            $function = Get-Command Install-ScoopPackage
            $function.CmdletBinding | Should -Be $true
            $function.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $function.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It "Should execute normally when ShouldProcess returns true" {
            $result = Install-ScoopPackage -PackageName "git" -Confirm:$false
            $result | Should -Be $false  # Returns Test-ScoopComponentInstalled result (mocked as NotInstalled)
            Should -Invoke Invoke-Command -Times 1 -Exactly
        }
    }

    Context "Parameter validation and edge cases" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $script:callCount = 0
            Mock Test-ScoopComponentInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { [InstalledState]::NotInstalled } 
                else { [InstalledState]::Pass }
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }
        }

        It "Should handle package names with special characters" {
            $result = Install-ScoopPackage -PackageName "package-with-dashes"
            $result | Should -Be ([InstalledState]::Pass)
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Name -eq "package-with-dashes"
            }
        }

        It "Should handle version parameter correctly when not specified" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be ([InstalledState]::Pass)
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Name -eq "git"
            }
        }

        It "Should handle bucket parameter correctly when not specified" {
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be ([InstalledState]::Pass)
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Name -eq "git"
            }
        }

        It "Should pass correct parameters to Test-ScoopComponentInstalled" {
            Install-ScoopPackage -PackageName "test-package" -Version "1.0.0" -Global
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Package -eq $true -and $Name -eq "test-package" -and $Version -eq "1.0.0" -and $Global -eq $true
            }
        }
    }

    Context "Integration test scenarios" {
        It "Should handle complete successful installation flow" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "C:\Users\Test\scoop\shims\scoop" }
            $script:callCount = 0
            Mock Test-ScoopComponentInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { [InstalledState]::NotInstalled } 
                else { [InstalledState]::Pass }
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }

            $result = Install-ScoopPackage -PackageName "nodejs" -Version "18.17.0" -Bucket "main" -Global

            $result | Should -Be ([InstalledState]::Pass)
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Invoke Find-Scoop -Times 1
            Should -Invoke Test-ScoopComponentInstalled -Times 2
            Should -Invoke Invoke-Command -Times 1
            Should -Invoke Write-ScoopCache -Times 1
            Should -Not -Invoke Uninstall-ScoopPackage
        }

        It "Should handle complete reinstallation flow" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $script:callCount = 0
            Mock Test-ScoopComponentInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { [InstalledState]::Installed } 
                else { [InstalledState]::Pass }
            }
            Mock Uninstall-ScoopPackage { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }

            $result = Install-ScoopPackage -PackageName "python"

            $result | Should -Be ([InstalledState]::Pass)
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Invoke Find-Scoop -Times 1
            Should -Invoke Test-ScoopComponentInstalled -Times 2
            Should -Invoke Uninstall-ScoopPackage -Times 1
            Should -Invoke Invoke-Command -Times 1
            Should -Invoke Write-ScoopCache -Times 1
        }

        It "Should handle complete failure scenario with error logging" {
            Mock Test-ScoopInstalled { throw "Test failure" }

            $result = Install-ScoopPackage -PackageName "git"

            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -Times 2 -ParameterFilter { $Verbosity -eq "Error" }
            Should -Not -Invoke Find-Scoop
            Should -Not -Invoke Test-ScoopComponentInstalled
            Should -Not -Invoke Invoke-Command
            Should -Not -Invoke Write-ScoopCache
            Should -Not -Invoke Uninstall-ScoopPackage
        }

        It "Should handle early exit when scoop not installed" {
            Mock Test-ScoopInstalled { return $false }

            $result = Install-ScoopPackage -PackageName "git"

            $result | Should -Be $false
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Not -Invoke Find-Scoop
            Should -Not -Invoke Test-ScoopComponentInstalled
            Should -Not -Invoke Invoke-Command
            Should -Not -Invoke Write-ScoopCache
            Should -Not -Invoke Uninstall-ScoopPackage
        }
    }
}