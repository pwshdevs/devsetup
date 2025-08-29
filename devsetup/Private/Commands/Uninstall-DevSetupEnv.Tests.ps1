BeforeAll {
    . $PSScriptRoot\Uninstall-DevSetupEnv.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Providers\Scoop\Uninstall-ScoopComponents.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Providers\Chocolatey\Uninstall-ChocolateyPackages.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Providers\PowerShell\Uninstall-PowershellModules.ps1
    Mock Get-DevSetupEnvPath { "TestDrive:\DevSetupEnvs" }
    Mock Test-Path { $true }
    Mock Read-ConfigurationFile { }
    Mock Uninstall-PowershellModules { $true }
    Mock Uninstall-ChocolateyPackages { $true }
    Mock Uninstall-ScoopComponents { $true }
    Mock Write-Host { }
    Mock Write-Error { }
}

Describe "Uninstall-DevSetupEnv" {

    Context "When environment file does not exist" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            $result = Uninstall-DevSetupEnv -Name "missing-env"
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file not found" }
        }
    }

    Context "When YAML parsing fails" {
        It "Should write error and return" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { $null }
            $result = Uninstall-DevSetupEnv -Name "bad-yaml"
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to parse YAML" }
        }
    }

    Context "When all uninstallers succeed" {
        It "Should call all uninstallers and write status" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            $result = Uninstall-DevSetupEnv -Name "basic-env"
            $result | Should -Be $null
            Assert-MockCalled Uninstall-PowershellModules -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Uninstall-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Uninstalling DevSetup environment from:" }
        }
    }

    Context "When a component uninstaller fails" {
        It "Should continue calling other uninstallers" {
            $script:callCount = 0
            Mock Uninstall-PowershellModules { $script:callCount++; $false }
            Mock Uninstall-ChocolateyPackages { $script:callCount++; $true }
            Mock Uninstall-ScoopComponents { $script:callCount++; $true }
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            $result = Uninstall-DevSetupEnv -Name "partial-fail"
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
            Assert-MockCalled Write-Error -Scope It
        }
    }
}