BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-PowershellModulesInstall.ps1")
    . (Join-Path $PSScriptRoot "Install-PowershellModule.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    Mock Write-StatusMessage { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Write-Error {}
    Mock Write-Warning {}
    Mock Write-Host {}
}

Describe "Invoke-PowershellModulesInstall" {

    Context "When YAML configuration is missing PowerShell modules" {
        It "Should return false" {
            $yamlData = @{ devsetup = @{ dependencies = @{ powershell = @{ } } } }
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When YAML configuration is missing dependencies" {
        It "Should return false" {
            $yamlData = @{ devsetup = @{ } }
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When modules are installed successfully (string format)" {
        It "Should install all modules and return true" {
            $script:installCalls = @()
            Mock Install-PowershellModule -MockWith {
                param($ModuleName)
                $script:installCalls += $ModuleName
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            $installCalls | Should -Contain "posh-git"
            $installCalls | Should -Contain "PSReadLine"
        }
    }

    Context "When modules are installed successfully (object format)" {
        It "Should install all modules and return true" {
            $script:installCalls = @()
            Mock Install-PowershellModule -MockWith {
                param($ModuleName)
                $script:installCalls += $ModuleName
                return $true
            }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                @{ name = "posh-git"; minimumVersion = "1.0.0"; scope = "CurrentUser"; force = $true; allowClobber = $true },
                                @{ name = "PSReadLine"; minimumVersion = "2.2.6"; scope = "AllUsers"; force = $false; allowClobber = $false }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            $installCalls | Should -Contain "posh-git"
            $installCalls | Should -Contain "PSReadLine"
        }
    }

    Context "When some modules fail to install" {
        It "Should continue and return true" {
            $script:installCalls = @()
            Mock Install-PowershellModule -MockWith {
                param($ModuleName)
                $script:installCalls += $ModuleName
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            $installCalls | Should -Contain "posh-git"
            $installCalls | Should -Contain "PSReadLine"
            $installCalls | Should -Contain "PowerShellGet"
        }
    }

    Context "When module entry is empty or missing name" {
        It "Should skip invalid entries and return true" {
            $script:installCalls = @()
            Mock Install-PowershellModule -MockWith {
                param($ModuleName)
                $script:installCalls += $ModuleName
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            $installCalls | Should -Contain "posh-git"
            $installCalls.Count | Should -Be 1
        }
    }

    Context "When an exception occurs during installation" {
        It "Should catch and return false" {
            Mock Install-PowershellModule { throw "Unexpected error" }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @("posh-git")
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $false
        }
    }
}