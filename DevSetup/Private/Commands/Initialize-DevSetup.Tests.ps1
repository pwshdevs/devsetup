BeforeAll {
    . (Join-Path $PSScriptRoot "Initialize-DevSetup.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupLocalEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupCommunityEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Core\Install-CoreDependencies.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Initialize-DevSetupEnvs.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupCachePath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupLogPath.ps1")
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Write-Verbose { }
    Mock Install-CoreDependencies { $true }
    Mock Get-DevSetupPath { "TestDrive:\Users\Test\devsetup" }
    Mock Get-DevSetupEnvPath { "TestDrive:\Users\Test\devsetup\envs" }
    Mock Get-DevSetupLocalEnvPath { "TestDrive:\Users\Test\devsetup\envs\local" }
    Mock Get-DevSetupCommunityEnvPath { "TestDrive:\Users\Test\devsetup\envs\community" }
    Mock Test-Path { $false }
    Mock New-Item { }
    Mock Initialize-DevSetupEnvs { "TestDrive:\Users\Test\devsetup\envs" }
    Mock Write-StatusMessage { }
    Mock Get-DevSetupCachePath { "TestDrive:\Users\Test\devsetup\cache" }
    Mock Get-DevSetupLogPath { "TestDrive:\Users\Test\devsetup\logs" }
}

Describe "Initialize-DevSetup" {

    Context "When all steps succeed" {
        It "Should install dependencies, create directories, and return true" {
            $result = Initialize-DevSetup
            $result | Should -Be $true
            Assert-MockCalled Install-CoreDependencies -Exactly 1 -Scope It
            Assert-MockCalled New-Item -Exactly 1 -Scope It
            Assert-MockCalled Initialize-DevSetupEnvs -Exactly 1 -Scope It
            #Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "initialized at" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When core dependencies fail to install" {
        It "Should write error and return nothing" {
            Mock Install-CoreDependencies { $false }
            $result = Initialize-DevSetup
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to install core dependencies" -and $Verbosity -eq "Error" }
        }
    }

    Context "When .devsetup directory already exists" {
        It "Should not create the directory and should log verbose" {
            Mock Test-Path { $true }
            $result = Initialize-DevSetup
            $result | Should -Be $true
            Assert-MockCalled New-Item -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "already exists" -and $Verbosity -eq "Verbose" }
        }
    }

    Context "When environment path initialization fails" {
        It "Should write error and return false" {
            Mock Initialize-DevSetupEnvs { $null }
            $result = Initialize-DevSetup
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to initialize DevSetup environment path" -and $Verbosity -eq "Error" }
        }
    }

    Context "When an exception occurs during initialization" {
        It "Should write error and return false" {
            Mock Install-CoreDependencies { throw "Unexpected error" }
            $result = Initialize-DevSetup
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to initialize DevSetup environment" -and $Verbosity -eq "Error" }
        }
    }
}