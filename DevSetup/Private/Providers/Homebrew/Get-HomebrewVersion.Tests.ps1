BeforeAll {
    . (Join-Path $PSScriptRoot Get-HomebrewVersion.ps1)
    . (Join-Path $PSScriptRoot ..\..\..\..\DevSetup\Private\Providers\Homebrew\Test-HomebrewInstalled.ps1)
    . (Join-Path $PSScriptRoot ..\..\..\..\DevSetup\Private\Providers\Homebrew\Find-Homebrew.ps1)
    . (Join-Path $PSScriptRoot ..\..\..\..\DevSetup\Private\Utils\Invoke-ExternalCommand.ps1)
    . (Join-Path $PSScriptRoot ..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1)
}

Describe "Get-HomebrewVersion" {
    Context "When Homebrew is not installed" {
        It "should return null" {
            Mock Test-HomebrewInstalled { $false }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be $null
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Homebrew is not installed" }
        }
    }

    Context "When Homebrew path is not found" {
        It "should return null" {
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { $null }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be $null
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Homebrew installation not found" }
        }
    }

    Context "When version is successfully retrieved" {
        It "should return the version string" {
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand { "Homebrew 3.5.10" }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be "3.5.10"
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It -ParameterFilter { $Command -eq "/usr/local/bin/brew" -and $Arguments -contains "--version" }
        }
    }

    Context "When output does not contain a version" {
        It "should return null" {
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand { "Homebrew version not available" }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be $null
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }
    }

    Context "When Invoke-ExternalCommand throws an exception" {
        It "should return null" {
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand { throw "Command failed" }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be $null
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get Homebrew version" }
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows (where Homebrew is unlikely)" {
            Mock Test-HomebrewInstalled { $false }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be $null
        }

        It "should work on Linux" {
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/home/linuxbrew/.linuxbrew/bin/brew" }
            Mock Invoke-ExternalCommand { "Homebrew 3.5.10" }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be "3.5.10"
        }

        It "should work on macOS" {
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/opt/homebrew/bin/brew" }
            Mock Invoke-ExternalCommand { "Homebrew 3.5.10" }
            Mock Write-StatusMessage { }

            $result = Get-HomebrewVersion
            $result | Should -Be "3.5.10"
        }
    }
}