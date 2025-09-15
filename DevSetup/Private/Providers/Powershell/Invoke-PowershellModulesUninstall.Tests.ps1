BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-PowershellModulesUninstall.ps1")
    . (Join-Path $PSScriptRoot "Uninstall-PowershellModule.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Write-StatusMessage { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Write-Host { }
    Mock Uninstall-PowershellModule { return $true }
}

Describe "Invoke-PowershellModulesUninstall" {

    Context "When YAML configuration is missing PowerShell modules" {
        It "Should return true (handles empty module list gracefully)" {
            $yamlData = @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @() } } } }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When YAML configuration is missing dependencies" {
        It "Should return true (handles missing dependencies gracefully)" {
            $yamlData = @{ devsetup = @{ } }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When AllUsers scope is specified but not running as admin" {
        It "Should return false and log admin error" {
            Mock Test-RunningAsAdmin { return $false }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            scope = "AllUsers"
                            modules = @(
                                @{ name = "posh-git" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq "Error" -and $Message -match "administrator privileges" }
        }
    }

    Context "When Test-RunningAsAdmin throws exception" {
        It "Should return false and log error" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            scope = "AllUsers"
                            modules = @(
                                @{ name = "posh-git" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq "Error" -and $Message -match "Failed to validate administrator privileges" }
        }
    }

    Context "When modules are uninstalled successfully (object format)" {
        It "Should uninstall all modules and return true" {
            Mock Uninstall-PowershellModule { return $true } -ParameterFilter { $ModuleName }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                @{ name = "posh-git"; minimumVersion = "1.0.0"; scope = "CurrentUser" },
                                @{ name = "PSReadLine"; minimumVersion = "2.2.6"; scope = "AllUsers" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "posh-git" }
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "PSReadLine" }
        }
    }

    Context "When modules use default scope" {
        It "Should use global scope setting" {
            Mock Uninstall-PowershellModule { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            scope = "CurrentUser"
                            modules = @(
                                @{ name = "posh-git" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "posh-git" }
        }
    }

    Context "When module has no version specified" {
        It "Should uninstall latest version" {
            Mock Uninstall-PowershellModule { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                @{ name = "posh-git" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -match "latest version" }
        }
    }

    Context "When some modules fail to uninstall" {
        It "Should continue and return true" {
            Mock Uninstall-PowershellModule -MockWith {
                param($ModuleName)
                if ($ModuleName -eq "PSReadLine") { return $false }
                return $true
            } -ParameterFilter { $ModuleName }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                @{ name = "posh-git" },
                                @{ name = "PSReadLine" },
                                @{ name = "PowerShellGet" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "posh-git" }
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "PSReadLine" }
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "PowerShellGet" }
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red" }
        }
    }

    Context "When an exception occurs during uninstallation" {
        It "Should catch exception, continue, and return true" {
            Mock Uninstall-PowershellModule { 
                param($ModuleName)
                if ($ModuleName -eq "ErrorModule") { throw "Uninstallation error" }
                return $true
            } -ParameterFilter { $ModuleName }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                @{ name = "ErrorModule" },
                                @{ name = "GoodModule" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq "Error" -and $Message -match "Error uninstalling module ErrorModule" }
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "ErrorModule" }
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $ModuleName -eq "GoodModule" }
        }
    }

    Context "When DryRun is specified" {
        It "Should pass WhatIf to Uninstall-PowershellModule" {
            Mock Uninstall-PowershellModule { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                @{ name = "posh-git" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData -DryRun
            $result | Should -Be $true
            Assert-MockCalled Uninstall-PowershellModule -ParameterFilter { $WhatIf -eq $true }
        }
    }
}