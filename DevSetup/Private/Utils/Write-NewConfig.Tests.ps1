BeforeAll {
    function ConvertTo-Yaml { }
    . (Join-Path $PSScriptRoot "Write-NewConfig.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-HostArchitecture.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-HostOperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-HostOperatingSystemVersion.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Chocolatey\Export-InstalledChocolateyPackages.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Scoop\Export-InstalledScoopPackages.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Homebrew\Invoke-HomebrewComponentsExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Powershell\Invoke-PowershellModulesExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\3rdParty\ConvertFrom-3rdPartyInstall.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Optimize-DevSetupEnvs.ps1")
}

Describe "Write-NewConfig" {
    Context "When not running as administrator" {
        It "should throw an exception and return false" {
            Mock Test-RunningAsAdmin { $false }
            Mock Write-StatusMessage { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error creating new configuration:" }
        }
    }

    Context "When creating a new configuration file" {
        It "should create base config and export packages" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Export-InstalledChocolateyPackages { $true }
            Mock Export-InstalledScoopPackages { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            Assert-MockCalled Test-RunningAsAdmin -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It
            Assert-MockCalled Export-InstalledChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Export-InstalledScoopPackages -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            $result | Should -Be $true
        }
    }

    Context "When updating an existing configuration file" {
        It "should merge with existing config and increment version" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ configuration = @{ version = "1.0.0"; description = "Existing config"; createdDate = "2022-01-01 12:00:00"; createdBy = "OldUser" }; dependencies = @{ chocolatey = @{ packages = @("git") } }; commands = @("echo hello") } } }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Export-InstalledChocolateyPackages { $true }
            Mock Export-InstalledScoopPackages { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-ConfigurationFile -Exactly 1 -Scope It
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It
            Assert-MockCalled Export-InstalledChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Export-InstalledScoopPackages -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
        }
    }

    Context "When reading existing config fails" {
        It "should fall back to new config" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { throw "Read failed" }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Export-InstalledChocolateyPackages { $true }
            Mock Export-InstalledScoopPackages { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-ConfigurationFile -Exactly 1 -Scope It
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It
        }
    }

    Context "When writing YAML fails" {
        It "should return false" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock ConvertTo-Yaml { throw "YAML conversion failed" }
            Mock Write-StatusMessage { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $false
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to create base configuration file" }
        }
    }

    Context "When DryRun is specified on non-Windows" {
        It "should pass DryRun to Homebrew export" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Get-HostOperatingSystemVersion { "Ubuntu 20.04" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { Write-Output $false }  # Not Windows
            Mock Invoke-HomebrewComponentsExport {
                Param($Config, $DryRun) 
                return $true 
            }
            Mock Invoke-PowershellModulesExport { return $true }
            Mock Export-InstalledChocolateyPackages { return $false }
            Mock Export-InstalledScoopPackages { return $false }
            Mock ConvertFrom-3rdPartyInstall { return $true }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml" -DryRun:$true
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It
            Assert-MockCalled Export-InstalledChocolateyPackages -Exactly 0 -Scope It
            Assert-MockCalled Export-InstalledScoopPackages -Exactly 0 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsExport -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            $result | Should -Be $true
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Export-InstalledChocolateyPackages { $true }
            Mock Export-InstalledScoopPackages { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Export-InstalledChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Export-InstalledScoopPackages -Exactly 1 -Scope It
        }

        It "should work on Linux" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Get-HostOperatingSystemVersion { "Ubuntu 20.04" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $false }  # Not Windows
            Mock Invoke-HomebrewComponentsExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Invoke-HomebrewComponentsExport -Exactly 1 -Scope It
        }

        It "should work on macOS" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "arm64" }
            Mock Get-HostOperatingSystem { "macOS" }
            Mock Get-HostOperatingSystemVersion { "12.0.1" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $false }  # Not Windows
            Mock Invoke-HomebrewComponentsExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Invoke-HomebrewComponentsExport -Exactly 1 -Scope It
        }
    }
}