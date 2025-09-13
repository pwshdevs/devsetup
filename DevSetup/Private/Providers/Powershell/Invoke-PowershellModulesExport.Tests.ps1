BeforeAll {
    function Write-EZLog {}
    . (Join-Path $PSScriptRoot "Invoke-PowershellModulesExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Update-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Get-DevSetupManifest.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "Get-PowershellModuleScopeMap.ps1")
    
    Mock Test-RunningAsAdmin { $true }
    Mock Get-InstalledModule { @(
        @{ Name = "ModuleA"; Version = [version]"1.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleA" },
        @{ Name = "ModuleB"; Version = [version]"2.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleB" }
    ) }
    Mock Get-DevSetupManifest { @{ RequiredModules = @("ModuleA") } }
    Mock Get-PowershellModuleScopeMap { @(
        @{ Path = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"; Scope = "CurrentUser" },
        @{ Path = "$env:ProgramFiles\WindowsPowerShell\Modules"; Scope = "AllUsers" }
    ) }
    Mock Get-Module { param($Name) @{ Name = $Name; ModuleBase = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$Name"; Version = [version]"1.0.0" } }
    Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(); scope = "CurrentUser" } } } } }
    Mock Update-DevSetupEnvFile { }
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Write-Debug { }
    Mock Write-Verbose { }
    Mock Write-StatusMessage {  }
}

Describe "Invoke-PowershellModulesExport" {

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-RunningAsAdmin { $false }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "requires administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Test-RunningAsAdmin throws an exception" {
        It "Should return false and log error" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to validate administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Get-DevSetupManifest throws an exception" {
        It "Should return false and log error" {
            Mock Get-DevSetupManifest { throw "Manifest read failed" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to read DevSetup manifest" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Get-PowershellModuleScopeMap throws an exception" {
        It "Should return false and log error" {
            Mock Get-PowershellModuleScopeMap { throw "Scope map failed" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to get PowerShell module scope map" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Get-PowershellModuleScopeMap returns empty" {
        It "Should warn and return true" {
            Mock Get-PowershellModuleScopeMap { @() }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "No PowerShell module install paths found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When Read-DevSetupEnvFile throws an exception" {
        It "Should return false and log error" {
            Mock Read-DevSetupEnvFile { throw "Config read failed" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to read configuration file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When no modules are found" {
        It "Should warn and return true" {
            Mock Get-InstalledModule { @() }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "No PowerShell modules found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When core dependency modules are present" {
        It "Should skip core dependency modules" {
            Mock Get-InstalledModule { @(
                @{ Name = "ModuleA"; Version = [version]"1.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleA" },
                @{ Name = "ModuleB"; Version = [version]"2.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleB" }
            ) }
            Mock Get-DevSetupManifest { @{ RequiredModules = @("ModuleA") } }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Adding module: ModuleB" }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -notmatch "Adding module: ModuleA" }
        }
    }

    Context "When core dependency modules are hashtable format" {
        It "Should skip hashtable format core dependency modules" {
            Mock Get-InstalledModule { @(
                @{ Name = "ModuleA"; Version = [version]"1.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleA" },
                @{ Name = "ModuleB"; Version = [version]"2.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleB" }
            ) }
            Mock Get-DevSetupManifest { @{ RequiredModules = @(@{ ModuleName = "ModuleA"; ModuleVersion = "1.0.0" }) } }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Adding module: ModuleB" }
        }
    }

    Context "When modules are found and added to config" {
        It "Should add new modules to YAML data" {
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Adding module: ModuleB" }
        }
    }

    Context "When module version changes" {
        It "Should update the module version in the config" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; minimumVersion = "1.0.0"; scope = "CurrentUser" }); scope = "CurrentUser" } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleB" }) }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Updating module: ModuleB" }
        }
    }

    Context "When module exists but has no version" {
        It "Should add minimumVersion to the module" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; scope = "CurrentUser" }); scope = "CurrentUser" } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleB" }) }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Updating module version: ModuleB" }
        }
    }

    Context "When module is unchanged" {
        It "Should skip updating the module" {
            Mock Read-DevSetupEnvFile { 
                @{ 
                    devsetup = @{ 
                        dependencies = @{ 
                            powershell = @{ 
                                modules = @(@{ 
                                    name = "ModuleB"; 
                                    minimumVersion = "2.0.0"; 
                                    scope = "CurrentUser" 
                                }); 
                                scope = "CurrentUser" 
                            } 
                        } 
                    } 
                } 
            }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleB" }) }
            Mock Get-DevSetupManifest { @{ RequiredModules = @() } }  # No core dependencies to exclude ModuleB
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Skipping module.*No Change.*ModuleB" }
        }
    }

    Context "When module exists with version property instead of minimumVersion" {
        It "Should use version property for comparison and detect change" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; version = "1.0.0"; scope = "CurrentUser" }); scope = "CurrentUser" } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0"; InstalledLocation = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\ModuleB" }) }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Updating module: ModuleB \(1\.0\.0 -> 2\.0\.0\)" }
        }
    }

    Context "When module has unknown scope" {
        It "Should skip module with unknown installation location" {
            Mock Get-InstalledModule { @(@{ Name = "UnknownModule"; Version = [version]"1.0.0"; InstalledLocation = "C:\Some\Unknown\Path\UnknownModule" }) }
            Mock Get-PowershellModuleScopeMap { @(
                @{ Path = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"; Scope = "CurrentUser" },
                @{ Path = "$env:ProgramFiles\WindowsPowerShell\Modules"; Scope = "AllUsers" }
            ) }
            Mock Get-DevSetupManifest { @{ RequiredModules = @() } }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(); scope = "UnknownScope" } } } } }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Skipping module with unknown scope: UnknownModule" -and $Verbosity -eq "Verbose" }
        }
    }

    Context "When DryRun is used" {
        It "Should call Update-DevSetupEnvFile with -WhatIf and not write to file" {
            $result = Invoke-PowershellModulesExport -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled Update-DevSetupEnvFile -Times 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Configuration saved successfully!" }
        }
    }



    Context "When Out-File fails" {
        It "Should write error and return false" {
            Mock Update-DevSetupEnvFile { throw "File error" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to save configuration" -and $Verbosity -eq "Error"}
        }
    }

    Context "When an unexpected error occurs during module retrieval" {
        It "Should write error and return false" {
            Mock Get-InstalledModule { throw "Unexpected error" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to retrieve installed PowerShell modules" -and $Verbosity -eq "Error"}
        }
    }
}