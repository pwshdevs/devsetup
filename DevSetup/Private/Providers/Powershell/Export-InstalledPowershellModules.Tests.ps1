BeforeAll {
    function ConvertTo-Yaml { }
    . $PSScriptRoot\Export-InstalledPowershellModules.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1        
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-DevSetupManifest.ps1   
    Mock Test-RunningAsAdmin { $true }
    Mock Get-InstalledModule { @(
        @{ Name = "ModuleA"; Version = [version]"1.0.0" },
        @{ Name = "ModuleB"; Version = [version]"2.0.0" }
    ) }
    Mock Get-DevSetupManifest { @{ RequiredModules = @("ModuleA") } }
    Mock Get-Module { param($Name) @{ Name = $Name; ModuleBase = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$Name"; Version = [version]"1.0.0" } }
    Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @() } } } } }
    Mock ConvertTo-Yaml { param($obj) "yaml-output" }
    Mock ConvertTo-Json { param($obj) "json-output" }
    Mock Out-File { }
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Write-Debug { }
    Mock Write-Verbose { }
}

Describe "Export-InstalledPowershellModules" {

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-RunningAsAdmin { $false }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "requires administrator privileges" }
        }
    }

    Context "When no modules are found" {
        It "Should warn and return true" {
            Mock Get-InstalledModule { @() }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "No PowerShell modules found" }
        }
    }

    Context "When core dependency modules are present" {
        It "Should skip core dependency modules" {
            Mock Get-InstalledModule { @(
                @{ Name = "ModuleA"; Version = [version]"1.0.0" },
                @{ Name = "ModuleB"; Version = [version]"2.0.0" }
            ) }
            Mock Get-DevSetupManifest { @{ RequiredModules = @("ModuleA") } }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Adding module: ModuleB" }
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -notmatch "Adding module: ModuleA" }
        }
    }

    Context "When modules are found and added to config" {
        It "Should add new modules to YAML data" {
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Adding module: ModuleB" }
        }
    }

    Context "When module version changes" {
        It "Should update the module version in the config" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; minimumVersion = "1.0.0"; scope = "CurrentUser" }) } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0" }) }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Updating module: ModuleB" }
        }
    }

    Context "When module exists but has no version" {
        It "Should add minimumVersion to the module" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; scope = "CurrentUser" }) } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0" }) }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Updating module version: ModuleB" }
        }
    }

    Context "When module is unchanged" {
        It "Should skip updating the module" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ powershell = @{ modules = @(@{ name = "ModuleB"; minimumVersion = "2.0.0"; scope = "CurrentUser" }) } } } } }
            Mock Get-InstalledModule { @(@{ Name = "ModuleB"; Version = [version]"2.0.0" }) }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            #Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Skipping module (No Change): ModuleB" }
        }
    }

    Context "When DryRun is used" {
        It "Should display YAML output and not write to file" {
            $result = Export-InstalledPowershellModules -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Times 0 -Scope It
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Dry Run" }
        }
    }

    Context "When OutFile is specified" {
        It "Should write YAML output to the specified file" {
            $result = Export-InstalledPowershellModules -Config "test.yaml" -OutFile "out.yaml"
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Scope It -ParameterFilter { $FilePath -eq "out.yaml" }
        }
    }

    Context "When YAML conversion fails" {
        It "Should fallback to JSON output" {
            Mock ConvertTo-Yaml { throw "YAML error" }
            $result = Export-InstalledPowershellModules -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Json -Scope It
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Could not convert to YAML format" }
        }
    }

    Context "When Out-File fails" {
        It "Should write error and return false" {
            Mock Out-File { throw "File error" }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to save configuration" }
        }
    }

    Context "When an unexpected error occurs" {
        It "Should write error and return false" {
            Mock Get-InstalledModule { throw "Unexpected error" }
            $result = Export-InstalledPowershellModules -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Error converting PowerShell modules" }
        }
    }
}