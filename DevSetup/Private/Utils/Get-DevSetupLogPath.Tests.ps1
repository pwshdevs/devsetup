BeforeAll {
    . (Join-Path $PSScriptRoot "Get-DevSetupLogPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupPath.ps1")
}

Describe "Get-DevSetupLogPath" {
    Context "When the logs directory does not exist" {
        It "should create the logs directory and return its path" {
            $script:mockDevSetupPath = Join-Path $TestDrive "DevSetup"
            $script:mockLogPath = Join-Path $script:mockDevSetupPath "logs"

            Mock Get-DevSetupPath { $script:mockDevSetupPath }
            Mock Test-Path { $false }
            Mock New-Item { }

            $result = Get-DevSetupLogPath
            $result | Should -Be $script:mockLogPath
            Assert-MockCalled Get-DevSetupPath -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $script:mockLogPath }
            Assert-MockCalled New-Item -Exactly 1 -Scope It -ParameterFilter { $Path -eq $script:mockLogPath -and $ItemType -eq "Directory" }
        }
    }

    Context "When the logs directory already exists" {
        It "should return the existing logs directory path" {
            $script:mockDevSetupPath = Join-Path $TestDrive "DevSetup"
            $script:mockLogPath = Join-Path $script:mockDevSetupPath "logs"

            Mock Get-DevSetupPath { $script:mockDevSetupPath }
            Mock Test-Path { $true }
            Mock New-Item { }

            $result = Get-DevSetupLogPath
            $result | Should -Be $script:mockLogPath
            Assert-MockCalled Get-DevSetupPath -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $script:mockLogPath }
            Assert-MockCalled New-Item -Exactly 0 -Scope It  # Directory should not be created
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            $script:mockDevSetupPath = Join-Path $TestDrive "DevSetup"
            $script:mockLogPath = Join-Path $script:mockDevSetupPath "logs"

            Mock Get-DevSetupPath { $script:mockDevSetupPath }
            Mock Test-Path { $true }
            Mock New-Item { }

            $result = Get-DevSetupLogPath
            $result | Should -Be $script:mockLogPath
        }

        It "should work on Linux" {
            $script:mockDevSetupPath = Join-Path $TestDrive "DevSetup"
            $script:mockLogPath = Join-Path $script:mockDevSetupPath "logs"

            Mock Get-DevSetupPath { $script:mockDevSetupPath }
            Mock Test-Path { $true }
            Mock New-Item { }

            $result = Get-DevSetupLogPath
            $result | Should -Be $script:mockLogPath
        }

        It "should work on macOS" {
            $script:mockDevSetupPath = Join-Path $TestDrive "DevSetup"
            $script:mockLogPath = Join-Path $script:mockDevSetupPath "logs"

            Mock Get-DevSetupPath { $script:mockDevSetupPath }
            Mock Test-Path { $true }
            Mock New-Item { }

            $result = Get-DevSetupLogPath
            $result | Should -Be $script:mockLogPath
        }
    }
}