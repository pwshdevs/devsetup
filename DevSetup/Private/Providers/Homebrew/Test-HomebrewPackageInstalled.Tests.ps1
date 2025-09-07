BeforeAll {
    . (Join-Path $PSScriptRoot "Test-HomebrewPackageInstalled.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Test-HomebrewInstalled.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Read-HomebrewCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1")
}

Describe "Test-HomebrewPackageInstalled" {
    Context "When Homebrew is not installed" {
        It "should return NotInstalled" {
            Mock Test-HomebrewInstalled { $false }
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::NotInstalled)
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It
        }
    }

    Context "When package is not in cache" {
        It "should return NotInstalled" {
            Mock Test-HomebrewInstalled { $true }
            Mock Read-HomebrewCache { @{ "node" = "14.17.0" } }  # Package not in cache
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::NotInstalled)
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Read-HomebrewCache -Exactly 1 -Scope It
        }
    }

    Context "When package is in cache and no minimum version specified" {
        It "should return full installed status" {
            Mock Test-HomebrewInstalled { $true }
            Mock Read-HomebrewCache { @{ "git" = "2.30.1" } }
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet)
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Read-HomebrewCache -Exactly 1 -Scope It
        }
    }

    Context "When package is in cache and minimum version is met" {
        It "should return full installed status" {
            Mock Test-HomebrewInstalled { $true }
            Mock Read-HomebrewCache { @{ "git" = "2.30.1" } }
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git" -MinimumVersion "2.0.0"
            $result | Should -Be ([InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet)
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Read-HomebrewCache -Exactly 1 -Scope It
        }
    }

    Context "When package is in cache but minimum version is not met" {
        It "should return Installed but not version flags" {
            Mock Test-HomebrewInstalled { $true }
            Mock Read-HomebrewCache { @{ "git" = "1.0.0" } }
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git" -MinimumVersion "2.0.0"
            $result | Should -Be ([InstalledState]::Installed)  # Only Installed, no version flags
            Assert-MockCalled Test-HomebrewInstalled -Exactly 1 -Scope It
            Assert-MockCalled Read-HomebrewCache -Exactly 1 -Scope It
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            Mock Test-HomebrewInstalled { $true }
            Mock Read-HomebrewCache { @{ "git" = "2.30.1" } }
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet)
        }

        It "should work on Linux" {
            Mock Test-HomebrewInstalled { $true }
            Mock Read-HomebrewCache { @{ "git" = "2.30.1" } }
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet)
        }

        It "should work on macOS" {
            Mock Test-HomebrewInstalled { $true }
            Mock Read-HomebrewCache { @{ "git" = "2.30.1" } }
            Mock Write-StatusMessage { }

            $result = Test-HomebrewPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet)
        }
    }
}