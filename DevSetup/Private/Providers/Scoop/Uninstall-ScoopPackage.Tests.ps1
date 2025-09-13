BeforeAll {
    . $PSScriptRoot\Uninstall-ScoopPackage.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1
    . $PSScriptRoot\..\..\Utils\Write-StatusMessage.ps1
}

Describe "Uninstall-ScoopPackage" {
    BeforeEach {
        # Mock Write-StatusMessage to avoid console output during tests
        Mock Write-StatusMessage { }
    }

    Context "When Scoop is not installed" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $false }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Scoop is not installed*" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When Scoop command cannot be found" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Failed to find Scoop command*" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When package is not installed" {
        It "Should return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::NotInstalled) 
            }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }
    }

    Context "When uninstall succeeds" {
        It "Should return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }
    }

    Context "When uninstall fails" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 1 }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When uninstall throws an exception" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { throw "Unexpected error" }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Failed to execute uninstall command for Scoop package 'git'*" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When uninstalling a global package" {
        It "Should pass --global and return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command {
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
                # Optionally, you could inspect $ScriptBlock here
                return $null
            }
            $result = Uninstall-ScoopPackage -PackageName "git" -Global
            $result | Should -Be $true
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { throw "Scoop test failure" }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Could not verify Scoop installation*" -and $Verbosity -eq "Error"
            } -Times 1
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Verbosity -eq "Error"
            } -Times 2
        }
    }

    Context "When Find-Scoop throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { throw "Scoop not found" }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Error finding Scoop command*" -and $Verbosity -eq "Error"
            } -Times 1
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Verbosity -eq "Error"
            } -Times 2
        }
    }

    Context "When Test-ScoopComponentInstalled throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { throw "Component test failure" }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Could not verify if Scoop package 'git' is installed*" -and $Verbosity -eq "Error"
            } -Times 1
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Verbosity -eq "Error"
            } -Times 2
        }
    }

    Context "When using WhatIf parameter" {
        It "Should return true with WhatIf for installed package" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "git" -WhatIf
            $result | Should -Be $true
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Invoke Find-Scoop -Times 1
            Should -Invoke Test-ScoopComponentInstalled -Times 1
            Should -Invoke Invoke-Command -Times 0
        }

        It "Should return true with WhatIf for not installed package" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::NotInstalled) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "git" -WhatIf
            $result | Should -Be $true
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Invoke Find-Scoop -Times 1
            Should -Invoke Test-ScoopComponentInstalled -Times 1
            Should -Invoke Invoke-Command -Times 0
        }

        It "Should handle WhatIf with Global parameter" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "git" -Global -WhatIf
            $result | Should -Be $true
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Invoke Find-Scoop -Times 1
            Should -Invoke Test-ScoopComponentInstalled -Times 1
            Should -Invoke Invoke-Command -Times 0
        }
    }

    Context "Parameter validation and edge cases" {
        It "Should call Test-ScoopComponentInstalled with correct parameters for package check" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "nodejs"
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Package -eq $true -and $Name -eq "nodejs"
            }
        }

        It "Should handle package names with special characters" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "package-with-dashes"
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Name -eq "package-with-dashes"
            }
        }

        It "Should log debug messages appropriately" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::NotInstalled) 
            }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $true
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Package not installed, can not remove*" -and $Verbosity -eq "Debug"
            }
        }

        It "Should log successful uninstall messages" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $true
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Uninstalled Scoop package: git*" -and $Verbosity -eq "Debug"
            }
        }

        It "Should log failed uninstall messages" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return ([InstalledState]::Pass) 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 1 }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Failed to uninstall Scoop package: git*" -and $Verbosity -eq "Debug"
            }
        }
    }
}
