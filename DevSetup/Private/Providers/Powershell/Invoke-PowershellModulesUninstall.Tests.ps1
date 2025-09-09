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
}

Describe "Invoke-PowershellModulesUninstall" {

    Context "When YAML configuration is missing PowerShell modules" {
        It "Should return false and warn" {
            $yamlData = @{ devsetup = @{ dependencies = @{ powershell = @{ } } } }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When YAML configuration is missing dependencies" {
        It "Should return false and warn" {
            $yamlData = @{ devsetup = @{ } }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When AllUsers scope is specified but not running as admin" {
        It "Should return false" {
            Mock Test-RunningAsAdmin { return $false }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            scope = "AllUsers"
                            modules = @("posh-git")
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When modules are uninstalled successfully (string format)" {
        It "Should uninstall all modules and return true" {
            $script:uninstallCalls = @()
            Mock Uninstall-PowershellModule -MockWith {
                param($ModuleName)
                $script:uninstallCalls += $ModuleName
                return $true
            }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @("posh-git", "PSReadLine")
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            $uninstallCalls | Should -Contain "posh-git"
            $uninstallCalls | Should -Contain "PSReadLine"
        }
    }

    Context "When modules are uninstalled successfully (object format)" {
        It "Should uninstall all modules and return true" {
            $script:uninstallCalls = @()
            Mock Uninstall-PowershellModule -MockWith {
                param($ModuleName)
                $script:uninstallCalls += $ModuleName
                return $true
            }
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
            $uninstallCalls | Should -Contain "posh-git"
            $uninstallCalls | Should -Contain "PSReadLine"
        }
    }

    Context "When some modules fail to uninstall" {
        It "Should continue and return true" {
            $script:uninstallCalls = @()
            Mock Uninstall-PowershellModule -MockWith {
                param($ModuleName)
                $script:uninstallCalls += $ModuleName
                if ($ModuleName -eq "PSReadLine") { return $false }
                return $true
            }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @("posh-git", "PSReadLine", "PowerShellGet")
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            $uninstallCalls | Should -Contain "posh-git"
            $uninstallCalls | Should -Contain "PSReadLine"
            $uninstallCalls | Should -Contain "PowerShellGet"
        }
    }

    Context "When module entry is empty or missing name" {
        It "Should skip invalid entries and return true" {
            $script:uninstallCalls = @()
            Mock Uninstall-PowershellModule -MockWith {
                param($ModuleName)
                $script:uninstallCalls += $ModuleName
                return $true
            }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                $null,
                                @{ minimumVersion = "1.0.0" },
                                "posh-git"
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $true
            $uninstallCalls | Should -Contain "posh-git"
            $uninstallCalls.Count | Should -Be 1
        }
    }

    Context "When an exception occurs during uninstallation" {
        It "Should catch and return false" {
            Mock Uninstall-PowershellModule { throw "Unexpected error" }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @("posh-git")
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesUninstall -YamlData $yamlData
            $result | Should -Be $false
        }
    }
}