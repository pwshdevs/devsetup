BeforeAll {
    . (Join-Path $PSScriptRoot "Uninstall-HomebrewPackage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-HasSudoAccess.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Find-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Test-HomebrewPackageInstalled.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Invoke-ExternalCommand.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Uninstall-HomebrewPackage" {
    Context "When sudo access is not available" {
        It "should return false" {
            Mock Test-HasSudoAccess { $false }
            Mock Write-StatusMessage { }

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It  # Status, sudo message, failed
        }
    }

    Context "When Homebrew is not installed" {
        It "should return false" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { $null }
            Mock Write-StatusMessage { }

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It  # Status, homebrew message, failed
        }
    }

    Context "When package is not installed" {
        It "should return true" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::NotInstalled }
            Mock Write-StatusMessage { }
            Mock Invoke-ExternalCommand { $false }

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Test-HomebrewPackageInstalled -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 0 -Scope It  # No uninstall needed
        }
    }

    Context "When uninstallation succeeds" {
        It "should return true" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::Installed }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 0

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It
            Assert-MockCalled Test-HomebrewPackageInstalled -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }
    }

    Context "When uninstallation fails" {
        It "should return false" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::Installed }
            Mock Invoke-ExternalCommand { $false }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 1

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It
            Assert-MockCalled Test-HomebrewPackageInstalled -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }
    }

    Context "When -WhatIf is used" {
        It "should not perform the uninstallation" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::Installed }
            Mock Write-StatusMessage { }
            Mock Invoke-ExternalCommand { $false }

            $result = Uninstall-HomebrewPackage -PackageName "git" -WhatIf
            $result | Should -Be $null  # ShouldProcess returns null when WhatIf is used
            Assert-MockCalled Test-HasSudoAccess -Exactly 0 -Scope It  # Should not proceed
            Assert-MockCalled Find-Homebrew -Exactly 0 -Scope It
            Assert-MockCalled Test-HomebrewPackageInstalled -Exactly 0 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 0 -Scope It
        }
    }

    Context "Cross-platform compatibility" {
        It "should handle Windows (where Homebrew is unlikely)" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { $null }
            Mock Write-StatusMessage { }

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "should work on Linux" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/home/linuxbrew/.linuxbrew/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::Installed }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 0

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
        }

        It "should work on macOS" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/opt/homebrew/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::Installed }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 0

            $result = Uninstall-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
        }
    }
}