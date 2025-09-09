BeforeAll {
    Function Write-EZLog { }
    . (Join-Path $PSScriptRoot "Uninstall-DevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Scoop\Uninstall-ScoopComponents.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Chocolatey\Uninstall-ChocolateyPackages.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Powershell\Invoke-PowershellModulesUninstall.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Homebrew\Invoke-HomebrewComponentsUninstall.ps1")
    Mock Get-DevSetupEnvPath { "$TestDrive\DevSetup\DevSetupEnvs" }
    Mock Test-Path { $true }
    Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
    Mock Invoke-PowershellModulesUninstall { Param($YamlData, $DryRun) $true }
    Mock Uninstall-ChocolateyPackages { Param($YamlData, $DryRun) $true }
    Mock Uninstall-ScoopComponents { Param($YamlData, $DryRun) $true }
    Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $true } }
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Write-StatusMessage { }
    Mock Write-EZLog { }
    Mock Invoke-HomebrewComponentsUninstall { Param($YamlData, $DryRun) $true }
}

Describe "Uninstall-DevSetupEnv" {

    Context "When environment file does not exist" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            $result = Uninstall-DevSetupEnv -Name "missing-env"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When YAML parsing fails" {
        It "Should write error and return" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { $null }
            $result = Uninstall-DevSetupEnv -Name "bad-yaml"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to parse YAML" -and $Verbosity -eq "Error" }
        }
    }

    Context "When all uninstallers succeed on Windows" {
        It "Should call all Windows uninstallers and write status" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $true } }
            $result = Uninstall-DevSetupEnv -Name "basic-env"
            $result | Should -Be $null
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Uninstalling DevSetup environment from:" }
        }
    }

    Context "When all uninstallers succeed on non-Windows" {
        It "Should call Homebrew uninstaller and write status" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Uninstall-DevSetupEnv -Name "basic-env"
            $result | Should -Be $null
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 0 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 0 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Uninstalling DevSetup environment from:" }
        }
    }

    Context "When a component uninstaller fails" {
        It "Should continue calling other uninstallers" {
            Mock Test-OperatingSystem { return $true }
            $script:callCount = 0
            Mock Invoke-PowershellModulesUninstall { $script:callCount++; $false }
            Mock Uninstall-ChocolateyPackages { $script:callCount++; $true }
            Mock Uninstall-ScoopComponents { $script:callCount++; $true }
            Mock Invoke-HomebrewComponentsUninstall { $script:callCount++; $true }
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }

            $result = Uninstall-DevSetupEnv -Name "partial-fail"
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 0 -Scope It
            $result | Should -Be $null
            $script:callCount | Should -Be 3
        }
    }

    Context "When an exception occurs during uninstall" {
        It "Should write error and return" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { throw "Unexpected error" }
            $result = Uninstall-DevSetupEnv -Name "exception-env"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When using Path parameter with valid path" {
        It "Should use the provided path and uninstall" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Uninstall-DevSetupEnv -Path "$TestDrive\valid.yaml"
            $result | Should -Be $null
            Assert-MockCalled Test-Path -Exactly 2 -Scope It -ParameterFilter { $Path -eq "$TestDrive\valid.yaml" }
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 1 -Scope It
        }
    }

    Context "When using Path parameter with invalid path" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            $result = Uninstall-DevSetupEnv -Path "$TestDrive\invalid.yaml"
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Invalid Path provided" }
        }
    }

    Context "When Name includes provider" {
        It "Should parse provider and name correctly" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Uninstall-DevSetupEnv -Name "custom:MyEnv"
            $result | Should -Be $null
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It
        }
    }

    Context "When Name does not include provider" {
        It "Should default to local provider" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Uninstall-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $null
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It
        }
    }

    Context "When DryRun is specified on Windows" {
        It "Should pass DryRun to uninstallers" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Uninstall-DevSetupEnv -Name "dry-run-env" -DryRun
            $result | Should -Be $null
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
            #Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
            #Assert-MockCalled Uninstall-ScoopComponents -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 0 -Scope It
        }
    }

    Context "When DryRun is specified on non-Windows" {
        It "Should pass DryRun to Homebrew uninstaller" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Uninstall-DevSetupEnv -Name "dry-run-env" -DryRun
            $result | Should -Be $null
            Assert-MockCalled Invoke-PowershellModulesUninstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 0 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 0 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Uninstall-DevSetupEnv -Name "win-env"
            $result | Should -Be $null
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It
        }

        It "Should work on Linux" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Uninstall-DevSetupEnv -Name "linux-env"
            $result | Should -Be $null
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 1 -Scope It
        }

        It "Should work on macOS" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Uninstall-DevSetupEnv -Name "mac-env"
            $result | Should -Be $null
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 1 -Scope It
        }
    }
}