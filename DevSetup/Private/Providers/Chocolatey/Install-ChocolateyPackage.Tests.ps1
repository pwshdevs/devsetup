BeforeAll {
    . (Join-Path $PSScriptRoot "Install-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "Test-ChocolateyInstalled.ps1")
    . (Join-Path $PSScriptRoot "Test-ChocolateyPackageInstalled.ps1")
    . (Join-Path $PSScriptRoot "Uninstall-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "Find-Chocolatey.ps1")
    . (Join-Path $PSScriptRoot "Write-ChocolateyCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\Enums\InstalledState.ps1")
    
    Mock Write-StatusMessage { }
}

Describe "Install-ChocolateyPackage" {

    Context "When not running as administrator" {
        It "Should return false and write error message" {
            Mock Test-RunningAsAdmin { return $false }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "requires administrator privileges" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-RunningAsAdmin throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Chocolatey is not installed" {
        It "Should return false and write warning message" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $false }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey is not installed. Cannot install package git." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When Test-ChocolateyInstalled throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { throw "Installation check failed" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking if Chocolatey is installed" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-ChocolateyPackageInstalled throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { throw "Package check failed" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking if package git is installed" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When package already meets requirements" {
        It "Should return true immediately when package passes all checks" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::Pass
                return $result
            }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $true
            Assert-MockCalled Test-ChocolateyPackageInstalled -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "git" -and -not $PSBoundParameters.ContainsKey('Version')
            }
        }
        
        It "Should return true immediately when package with version passes all checks" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::Pass
                return $result
            }
            
            $result = Install-ChocolateyPackage -PackageName "nodejs" -Version "20.10.0"
            
            $result | Should -Be $true
            Assert-MockCalled Test-ChocolateyPackageInstalled -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "nodejs" -and $Version -eq "20.10.0"
            }
        }
    }

    Context "When package needs reinstallation due to version conflict" {
        It "Should uninstall existing package before reinstalling" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::Installed
                return $result
            }
            Mock Uninstall-ChocolateyPackage { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Install-ChocolateyPackage -PackageName "nodejs" -Version "18.17.0"
            
            $result | Should -Be $true
            Assert-MockCalled Uninstall-ChocolateyPackage -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "nodejs"
            }
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
        }
        
        It "Should handle uninstall failure and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::Installed
                return $result
            }
            Mock Uninstall-ChocolateyPackage { throw "Uninstall failed" }
            
            $result = Install-ChocolateyPackage -PackageName "nodejs" -Version "18.17.0"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error uninstalling existing package nodejs" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Find-Chocolatey throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { throw "Cannot locate chocolatey" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error locating Chocolatey command" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Find-Chocolatey returns null or invalid path" {
        It "Should return false when Find-Chocolatey returns null" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return $null }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot install package git." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return false when Find-Chocolatey returns empty string" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot install package git." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When Test-Path throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { throw "Path check failed" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error verifying Chocolatey command path" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Chocolatey command path does not exist" {
        It "Should return false when path does not exist" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "C:\invalid\path\choco.exe" }
            Mock Test-Path { return $false }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey command path 'C:\\invalid\\path\\choco.exe' does not exist. Cannot install package git." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When installing package without version" {
        It "Should install package with default parameters and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $true
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
            Assert-MockCalled Write-ChocolateyCache -Times 1 -Scope It
        }
    }

    Context "When installing package with version" {
        It "Should install package with version parameter and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Install-ChocolateyPackage -PackageName "nodejs" -Version "20.10.0"
            
            $result | Should -Be $true
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
            Assert-MockCalled Write-ChocolateyCache -Times 1 -Scope It
        }
    }

    Context "When installing package with custom parameters" {
        It "Should install package with params parameter and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Install-ChocolateyPackage -PackageName "googlechrome" -Param "/nogoogle"
            
            $result | Should -Be $true
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
            Assert-MockCalled Write-ChocolateyCache -Times 1 -Scope It
        }
        
        It "Should install package with version and params parameters" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Install-ChocolateyPackage -PackageName "vscode" -Version "1.84.2" -Param "/silent"
            
            $result | Should -Be $true
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
            Assert-MockCalled Write-ChocolateyCache -Times 1 -Scope It
        }
    }

    Context "When Invoke-Command throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { throw "Command execution failed" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error installing package git" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When installation command fails with non-zero exit code" {
        It "Should return false when LASTEXITCODE is non-zero" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 1
            }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "Failed to install: git" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Write-ChocolateyCache fails after successful installation" {
        It "Should return false when Write-ChocolateyCache returns false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $false }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to write Chocolatey cache." -and $Verbosity -eq "Error"
            }
        }
        
        It "Should handle Write-ChocolateyCache exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { throw "Cache write failed" }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error writing Chocolatey cache" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When using ShouldProcess with WhatIf" {
        It "Should skip installation and return true when WhatIf is specified" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { }
            
            $result = Install-ChocolateyPackage -PackageName "git" -WhatIf
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Skipping installation of Chocolatey package 'git'." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Invoke-Command -Times 0 -Scope It
        }
    }

    Context "When validating parameter validation" {
        It "Should throw when PackageName is null" {
            { Install-ChocolateyPackage -PackageName $null } | Should -Throw
        }
        
        It "Should throw when PackageName is empty string" {
            { Install-ChocolateyPackage -PackageName "" } | Should -Throw
        }
        
        It "Should throw when Version is empty string" {
            { Install-ChocolateyPackage -PackageName "git" -Version "" } | Should -Throw
        }
        
        It "Should throw when Param is empty string" {
            { Install-ChocolateyPackage -PackageName "git" -Param "" } | Should -Throw
        }
    }

    Context "When processing successful installation scenarios" {
        It "Should complete full installation flow successfully" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Install-ChocolateyPackage -PackageName "git" -Version "2.42.0" -Param "/VERYSILENT"
            
            $result | Should -Be $true
            Assert-MockCalled Test-RunningAsAdmin -Times 1 -Scope It
            Assert-MockCalled Test-ChocolateyInstalled -Times 1 -Scope It
            Assert-MockCalled Test-ChocolateyPackageInstalled -Times 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Times 1 -Scope It
            Assert-MockCalled Test-Path -Times 1 -Scope It
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
            Assert-MockCalled Write-ChocolateyCache -Times 1 -Scope It
        }
        
        It "Should handle minimal parameters correctly" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Test-ChocolateyPackageInstalled { 
                $result = [InstalledState]::NotInstalled
                return $result
            }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Test-Path { return $true }
            Mock Invoke-Command { 
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
            }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Install-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $true
            Assert-MockCalled Test-ChocolateyPackageInstalled -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "git" -and -not $PSBoundParameters.ContainsKey('Version')
            }
        }
    }
}