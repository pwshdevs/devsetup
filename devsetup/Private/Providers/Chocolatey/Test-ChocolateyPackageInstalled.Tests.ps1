BeforeAll {
    . $PSScriptRoot\Test-ChocolateyPackageInstalled.ps1
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    . $PSScriptRoot\Read-ChocolateyCache.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1     
    Mock Test-ChocolateyInstalled { $true }
    Mock Read-ChocolateyCache { }
    Mock Write-Warning { }
}

Describe "Test-ChocolateyPackageInstalled" {

    Context "When Chocolatey is not installed" {
        It "Should return NotInstalled and write a warning" {
            Mock Test-ChocolateyInstalled { $false }
            $result = Test-ChocolateyPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::NotInstalled)
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "not installed" }
        }
    }

    Context "When package is not in cache" {
        It "Should return NotInstalled" {
            Mock Test-ChocolateyInstalled { $true }
            Mock Read-ChocolateyCache { @("nodejs|20.10.0") }
            $result = Test-ChocolateyPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::NotInstalled)
        }
    }

    Context "When package is in cache (any version)" {
        It "Should return Installed, GlobalVersionMet, MinimumVersionMet, RequiredVersionMet" {
            Mock Test-ChocolateyInstalled { $true }
            Mock Read-ChocolateyCache { @("git|2.42.0") }
            $result = Test-ChocolateyPackageInstalled -PackageName "git"
            $result.HasFlag([InstalledState]::Installed) | Should -Be $true
            $result.HasFlag([InstalledState]::GlobalVersionMet) | Should -Be $true
            $result.HasFlag([InstalledState]::MinimumVersionMet) | Should -Be $true
            $result.HasFlag([InstalledState]::RequiredVersionMet) | Should -Be $true
        }
    }

    Context "When package is in cache but version does not match" {
        It "Should not set MinimumVersionMet or RequiredVersionMet" {
            Mock Test-ChocolateyInstalled { $true }
            Mock Read-ChocolateyCache { @("git|2.42.0") }
            $result = Test-ChocolateyPackageInstalled -PackageName "git" -Version "2.41.0"
            $result.HasFlag([InstalledState]::Installed) | Should -Be $true
            $result.HasFlag([InstalledState]::GlobalVersionMet) | Should -Be $true
            $result.HasFlag([InstalledState]::MinimumVersionMet) | Should -Be $false
            $result.HasFlag([InstalledState]::RequiredVersionMet) | Should -Be $false
        }
    }

    Context "When package is in cache and version matches" {
        It "Should set all flags" {
            Mock Test-ChocolateyInstalled { $true }
            Mock Read-ChocolateyCache { @("git|2.42.0") }
            $result = Test-ChocolateyPackageInstalled -PackageName "git" -Version "2.42.0"
            $result.HasFlag([InstalledState]::Installed) | Should -Be $true
            $result.HasFlag([InstalledState]::GlobalVersionMet) | Should -Be $true
            $result.HasFlag([InstalledState]::MinimumVersionMet) | Should -Be $true
            $result.HasFlag([InstalledState]::RequiredVersionMet) | Should -Be $true
        }
    }

    Context "When Read-ChocolateyCache throws an error" {
        It "Should return NotInstalled" {
            Mock Test-ChocolateyInstalled { $true }
            Mock Read-ChocolateyCache { throw "cache error" }
            $result = Test-ChocolateyPackageInstalled -PackageName "git"
            $result | Should -Be ([InstalledState]::NotInstalled)
        }
    }
}