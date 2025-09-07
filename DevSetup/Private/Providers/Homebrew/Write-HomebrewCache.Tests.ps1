BeforeAll {
    . (Join-Path $PSScriptRoot "Write-HomebrewCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Get-HomebrewCacheFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Test-HomebrewInstalled.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Find-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Invoke-ExternalCommand.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Write-HomebrewCache" {
    Context "When Homebrew is not installed" {
        It "should not write anything" {
            Mock Get-HomebrewCacheFile { Join-Path $TestDrive "homebrew.cache" }
            Mock Test-HomebrewInstalled { $false }
            Mock Set-Content { }
            Mock Find-Homebrew { $null }
            Mock Invoke-ExternalCommand { $null }

            Write-HomebrewCache
            Assert-MockCalled Get-HomebrewCacheFile -Exactly 1 -Scope It
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 0 -Scope It  # Not called if not installed
            Assert-MockCalled Invoke-ExternalCommand -Exactly 0 -Scope It
            Assert-MockCalled Set-Content -Exactly 0 -Scope It  # No data to write
        }
    }

    Context "When Homebrew is installed and write succeeds" {
        It "should parse output and write JSON to cache file" {
            Mock Get-HomebrewCacheFile { Join-Path $TestDrive "homebrew.cache" }
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand { "git 2.30.1`nnode 14.17.0" }
            Mock Set-Content { }
            Mock Write-StatusMessage { }

            Write-HomebrewCache
            Assert-MockCalled Get-HomebrewCacheFile -Exactly 1 -Scope It
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
            Assert-MockCalled Set-Content -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It  # No errors
        }
    }

    Context "When Invoke-ExternalCommand throws an exception" {
        It "should handle the exception and write error message" {
            Mock Get-HomebrewCacheFile { Join-Path $TestDrive "homebrew.cache" }
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand { throw "Command failed" }
            Mock Set-Content { }
            Mock Write-StatusMessage { }

            Write-HomebrewCache
            Assert-MockCalled Get-HomebrewCacheFile -Exactly 1 -Scope It
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
            Assert-MockCalled Set-Content -Exactly 0 -Scope It  # Exception prevents writing
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It  # Error and stack trace
        }
    }

    Context "When Set-Content throws an exception" {
        It "should handle the exception and write error message" {
            Mock Get-HomebrewCacheFile { Join-Path $TestDrive "homebrew.cache" }
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand { "git 2.30.1" }
            Mock Set-Content { throw "Write failed" }
            Mock Write-StatusMessage { }

            Write-HomebrewCache
            Assert-MockCalled Get-HomebrewCacheFile -Exactly 1 -Scope It
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
            Assert-MockCalled Set-Content -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It  # Error and stack trace
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            Mock Get-HomebrewCacheFile { Join-Path $TestDrive "homebrew.cache" }
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand { "git 2.30.1" }
            Mock Set-Content { }
            Mock Write-StatusMessage { }

            Write-HomebrewCache
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }

        It "should work on Linux" {
            Mock Get-HomebrewCacheFile { Join-Path $TestDrive "homebrew.cache" }
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/home/linuxbrew/.linuxbrew/bin/brew" }
            Mock Invoke-ExternalCommand { "git 2.30.1" }
            Mock Set-Content { }
            Mock Write-StatusMessage { }

            Write-HomebrewCache
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }

        It "should work on macOS" {
            Mock Get-HomebrewCacheFile { Join-Path $TestDrive "homebrew.cache" }
            Mock Test-HomebrewInstalled { $true }
            Mock Find-Homebrew { "/opt/homebrew/bin/brew" }
            Mock Invoke-ExternalCommand { "git 2.30.1" }
            Mock Set-Content { }
            Mock Write-StatusMessage { }

            Write-HomebrewCache
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }
    }
}