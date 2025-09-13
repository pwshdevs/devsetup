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
    Mock Install-PowershellModule { return $true }
}

Describe "Invoke-PowershellModulesInstall" {

    Context "When YAML configuration is missing PowerShell modules" {
        It "Should return true (handles empty module list gracefully)" {
            $yamlData = @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @() } } } }
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When YAML configuration is missing dependencies" {
        It "Should return true (handles missing dependencies gracefully)" {
            $yamlData = @{ devsetup = @{ } }
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When AllUsers scope is specified but not running as admin" {
        It "Should return false and show admin error" {
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq "Error" -and $Message -match "Failed to validate administrator privileges" }
        }
    }

    Context "When modules are installed successfully (object format)" {
        It "Should install all modules and return true" {
            Mock Install-PowershellModule -MockWith {
                param($ModuleName, $Force, $AllowClobber, $Scope, $Version, $WhatIf)
                return $true
            } -ParameterFilter { $ModuleName }
            
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
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "posh-git" }
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "PSReadLine" }
        }
    }

    Context "When modules use default scope and settings" {
        It "Should use global scope and default force/allowClobber settings" {
            Mock Install-PowershellModule -MockWith {
                param($ModuleName, $Force, $AllowClobber, $Scope, $Version, $WhatIf)
                return $true
            } -ParameterFilter { $ModuleName }
            
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-PowershellModule -ParameterFilter { 
                $ModuleName -eq "posh-git" -and 
                $Scope -eq "CurrentUser" -and 
                $Force -eq $true -and 
                $AllowClobber -eq $true 
            }
        }
    }

    Context "When module has no version specified" {
        It "Should install latest version" {
            Mock Install-PowershellModule { return $true }
            
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -match "latest version" }
        }
    }

    Context "When some modules fail to install" {
        It "Should continue and return true" {
            Mock Install-PowershellModule -MockWith {
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "posh-git" }
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "PSReadLine" }
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "PowerShellGet" }
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red" }
        }
    }

    Context "When module entry is null" {
        It "Should skip null entries and return true" {
            Mock Install-PowershellModule { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        powershell = @{
                            modules = @(
                                $null,
                                @{ name = "posh-git" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-PowershellModule -Times 1
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "posh-git" }
        }
    }

    Context "When an exception occurs during installation" {
        It "Should catch exception, continue, and return true" {
            Mock Install-PowershellModule { 
                param($ModuleName)
                if ($ModuleName -eq "ErrorModule") { throw "Installation error" }
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq "Error" -and $Message -match "Error installing PowerShell module ErrorModule" }
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "ErrorModule" }
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $ModuleName -eq "GoodModule" }
        }
    }

    Context "When DryRun is specified" {
        It "Should pass WhatIf to Install-PowershellModule" {
            Mock Install-PowershellModule { return $true }
            
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
            $result = Invoke-PowershellModulesInstall -YamlData $yamlData -DryRun
            $result | Should -Be $true
            Assert-MockCalled Install-PowershellModule -ParameterFilter { $WhatIf -eq $true }
        }
    }
}