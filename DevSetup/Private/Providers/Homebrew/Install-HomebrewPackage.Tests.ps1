BeforeAll {
    . (Join-Path $PSScriptRoot "Install-HomebrewPackage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-HasSudoAccess.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Find-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Test-HomebrewPackageInstalled.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Invoke-ExternalCommand.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Install-HomebrewPackage" {
    Context "When sudo access is not available" {
        It "should return false" {
            Mock Test-HasSudoAccess { $false }
            Mock Write-StatusMessage { }

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It  # One for status, one for failure
        }
    }

    Context "When Homebrew is not installed" {
        It "should return false" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { $null }
            Mock Write-StatusMessage { }

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It
        }
    }

    Context "When package is already installed" {
        It "should return true without installing" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::Pass }
            Mock Write-StatusMessage { }
            Mock Invoke-ExternalCommand { $true }

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Test-HomebrewPackageInstalled -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 0 -Scope It  # No installation needed
        }
    }

    Context "When installation succeeds" {
        It "should install the package and return true" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::NotInstalled }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 0

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It
            Assert-MockCalled Test-HomebrewPackageInstalled -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }
    }

    Context "When installation fails" {
        It "should return false" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::NotInstalled }
            Mock Invoke-ExternalCommand { $false }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 1

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It
            Assert-MockCalled Test-HomebrewPackageInstalled -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }
    }

    Context "When -WhatIf is used" {
        It "should not perform the installation" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::Fail }
            Mock Write-StatusMessage { }
            Mock Invoke-ExternalCommand { $true }

            ($result = Install-HomebrewPackage -PackageName "git" -WhatIf) *> $null
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

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $false
        }

        It "should work on Linux" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/home/linuxbrew/.linuxbrew/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::NotInstalled }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 0

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
        }

        It "should work on macOS" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/opt/homebrew/bin/brew" }
            Mock Test-HomebrewPackageInstalled { [InstalledState]::NotInstalled }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            $global:LASTEXITCODE = 0

            $result = Install-HomebrewPackage -PackageName "git"
            $result | Should -Be $true
        }
    }
}