BeforeAll {
    . $PSScriptRoot\Initialize-DevSetup.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Providers\Core\Install-CoreDependencies.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Initialize-DevSetupEnvs.ps1
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
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to install core dependencies" }
        }
    }

    Context "When .devsetup directory already exists" {
        It "Should not create the directory and should log verbose" {
            Mock Test-Path { $true }
            $result = Initialize-DevSetup
            $result | Should -Be $true
            Assert-MockCalled New-Item -Exactly 0 -Scope It
            Assert-MockCalled Write-Verbose -Scope It -ParameterFilter { $Message -match "already exists" }
        }
    }

    Context "When environment path initialization fails" {
        It "Should write error and return false" {
            Mock Initialize-DevSetupEnvs { $null }
            $result = Initialize-DevSetup
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to initialize DevSetup environment path" }
        }
    }

    Context "When an exception occurs during initialization" {
        It "Should write error and return false" {
            Mock Install-CoreDependencies { throw "Unexpected error" }
            $result = Initialize-DevSetup
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to initialize DevSetup environment" }
        }
    }
}