BeforeAll {
    . (Join-Path $PSScriptRoot "Read-HomebrewCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Get-HomebrewCacheFile.ps1")
}

Describe "Read-HomebrewCache" {
    Context "When cache file exists" {
        It "should read and return the cache data as hashtable" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $true }
            Mock Get-Content { '{"package1": "version1", "package2": "version2"}' }
            Mock ConvertFrom-Json { @{ package1 = "version1"; package2 = "version2" } }

            $result = Read-HomebrewCache
            $result | Should -BeOfType [hashtable]
            $result["package1"] | Should -Be "version1"
            $result["package2"] | Should -Be "version2"
            Assert-MockCalled Get-HomebrewCacheFile -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Get-Content -Exactly 1 -Scope It
            Assert-MockCalled ConvertFrom-Json -Exactly 1 -Scope It
        }
    }

    Context "When cache file does not exist" {
        It "should return an empty hashtable" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $false }
            Mock Get-Content { }
            Mock ConvertFrom-Json { }

            $result = Read-HomebrewCache
            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 0
            Assert-MockCalled Get-HomebrewCacheFile -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Get-Content -Exactly 0 -Scope It
            Assert-MockCalled ConvertFrom-Json -Exactly 0 -Scope It
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $true }
            Mock Get-Content { '{"git": "2.30.1"}' }
            Mock ConvertFrom-Json { @{ git = "2.30.1" } }

            $result = Read-HomebrewCache
            $result["git"] | Should -Be "2.30.1"
        }

        It "should work on Linux" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $true }
            Mock Get-Content { '{"git": "2.30.1"}' }
            Mock ConvertFrom-Json { @{ git = "2.30.1" } }

            $result = Read-HomebrewCache
            $result["git"] | Should -Be "2.30.1"
        }

        It "should work on macOS" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $true }
            Mock Get-Content { '{"git": "2.30.1"}' }
            Mock ConvertFrom-Json { @{ git = "2.30.1" } }

            $result = Read-HomebrewCache
            $result["git"] | Should -Be "2.30.1"
        }
    }
}