BeforeAll {
    Function Write-EZLog { }
    . (Join-Path $PSScriptRoot "Uninstall-DevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Scoop\Uninstall-ScoopComponents.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Chocolatey\Uninstall-ChocolateyPackages.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Powershell\Uninstall-PowershellModules.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Homebrew\Invoke-HomebrewComponentsUninstall.ps1")
    Mock Get-DevSetupEnvPath { "$TestDrive\DevSetup\DevSetupEnvs" }
    Mock Test-Path { $true }
    Mock Read-ConfigurationFile { }
    Mock Uninstall-PowershellModules { Param($YamlData, $DryRun) $true }
    Mock Uninstall-ChocolateyPackages { Param($YamlData, $DryRun) $true }
    Mock Uninstall-ScoopComponents { Param($YamlData, $DryRun) $true }
    Mock Test-OperatingSystem { $true }
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Write-StatusMessage { }
    Mock Write-EZLog { }
    Mock Invoke-HomebrewComponentsUninstall { $true }
}

Describe "Uninstall-DevSetupEnv" {

    Context "When environment file does not exist" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            $result = Uninstall-DevSetupEnv -Name "missing-env" -DryRun:$false
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

    Context "When all uninstallers succeed" {
        It "Should call all uninstallers and write status" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $true } }
            $result = Uninstall-DevSetupEnv -Name "basic-env"
            $result | Should -Be $null
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-PowershellModules -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsUninstall -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Uninstalling DevSetup environment from:" }
        }
    }

    Context "When a component uninstaller fails" {
        It "Should continue calling other uninstallers" {
            Mock Test-OperatingSystem { return $true }
            $script:callCount = 0
            Mock Uninstall-PowershellModules { $script:callCount++; $false }
            Mock Uninstall-ChocolateyPackages { $script:callCount++; $true }
            Mock Uninstall-ScoopComponents { $script:callCount++; $true }
            Mock Invoke-HomebrewComponentsUninstall { $script:callCount++; $true }
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }

            $result = Uninstall-DevSetupEnv -Name "partial-fail"
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
            Assert-MockCalled Uninstall-PowershellModules -Exactly 1 -Scope It
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
}