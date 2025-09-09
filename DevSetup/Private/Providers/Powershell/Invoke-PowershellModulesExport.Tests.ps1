BeforeAll {
    function ConvertTo-Yaml { }
    function Write-EZLog {}
    . (Join-Path $PSScriptRoot "Invoke-PowershellModulesExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Get-DevSetupManifest.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Test-RunningAsAdmin { $true }
    Mock Get-InstalledModule { @(
        @{ Name = "ModuleA"; Version = [version]"1.0.0" },
        @{ Name = "ModuleB"; Version = [version]"2.0.0" }
    ) }
    Mock Get-DevSetupManifest { @{ RequiredModules = @("ModuleA") } }
    Mock Get-Module { param($Name) @{ Name = $Name; ModuleBase = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$Name"; Version = [version]"1.0.0" } }
    Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @() } } } } }
    Mock ConvertTo-Yaml { "yaml-output" }
    Mock ConvertTo-Json { "json-output" }
    Mock Out-File { }
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
                @{ Name = "ModuleA"; Version = [version]"1.0.0" },
                @{ Name = "ModuleB"; Version = [version]"2.0.0" }
            ) }
            Mock Get-DevSetupManifest { @{ RequiredModules = @("ModuleA") } }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Adding module: ModuleB" }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -notmatch "Adding module: ModuleA" }
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
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; minimumVersion = "1.0.0"; scope = "CurrentUser" }) } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0" }) }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Updating module: ModuleB" }
        }
    }

    Context "When module exists but has no version" {
        It "Should add minimumVersion to the module" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; scope = "CurrentUser" }) } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0" }) }
            Invoke-PowershellModulesExport -Config "test.yaml"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Updating module version: ModuleB" }
        }
    }

    Context "When module is unchanged" {
        It "Should skip updating the module" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; minimumVersion = "2.0.0"; scope = "CurrentUser" }) } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0" }) }
            Invoke-PowershellModulesExport -Config "test.yaml"
            #Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Skipping module (No Change): ModuleB" }
        }
    }

    Context "When DryRun is used" {
        It "Should display YAML output and not write to file" {
            $result = Invoke-PowershellModulesExport -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Times 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Dry Run" }
        }
    }

    Context "When OutFile is specified" {
        It "Should write YAML output to the specified file" {
            $result = Invoke-PowershellModulesExport -Config "test.yaml" -OutFile "out.yaml"
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Scope It -ParameterFilter { $FilePath -eq "out.yaml" }
        }
    }

    Context "When YAML conversion fails" {
        It "Should fallback to JSON output" {
            Mock ConvertTo-Yaml { throw "YAML error" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Json -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Could not convert to YAML format" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When Out-File fails" {
        It "Should write error and return false" {
            Mock Out-File { throw "File error" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to save configuration" -and $Verbosity -eq "Error"}
        }
    }

    Context "When an unexpected error occurs" {
        It "Should write error and return false" {
            Mock Get-InstalledModule { throw "Unexpected error" }
            $result = Invoke-PowershellModulesExport -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Error converting PowerShell modules" -and $Verbosity -eq "Error"}
        }
    }
}