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
            
            # Mock ConvertFrom-Json to return PSCustomObject as it would in real usage
            Mock ConvertFrom-Json { 
                $obj = [PSCustomObject]@{ 
                    package1 = "version1"
                    package2 = "version2" 
                }
                return $obj
            }

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
            Mock ConvertFrom-Json { 
                $obj = [PSCustomObject]@{ git = "2.30.1" }
                return $obj
            }

            $result = Read-HomebrewCache
            $result["git"] | Should -Be "2.30.1"
        }

        It "should work on Linux" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $true }
            Mock Get-Content { '{"git": "2.30.1"}' }
            Mock ConvertFrom-Json { 
                $obj = [PSCustomObject]@{ git = "2.30.1" }
                return $obj
            }

            $result = Read-HomebrewCache
            $result["git"] | Should -Be "2.30.1"
        }

        It "should work on macOS" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $true }
            Mock Get-Content { '{"git": "2.30.1"}' }
            Mock ConvertFrom-Json { 
                $obj = [PSCustomObject]@{ git = "2.30.1" }
                return $obj
            }

            $result = Read-HomebrewCache
            $result["git"] | Should -Be "2.30.1"
        }

        It "should convert PSCustomObject to Hashtable correctly" {
            $mockCachePath = Join-Path $TestDrive "homebrew.cache"
            Mock Get-HomebrewCacheFile { $mockCachePath }
            Mock Test-Path { $true }
            Mock Get-Content { '{"node": "16.0.0", "npm": "7.10.0", "git": "2.30.1"}' }
            Mock ConvertFrom-Json { 
                $obj = [PSCustomObject]@{ 
                    node = "16.0.0"
                    npm = "7.10.0"
                    git = "2.30.1"
                }
                return $obj
            }

            $result = Read-HomebrewCache
            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 3
            $result.ContainsKey("node") | Should -Be $true
            $result.ContainsKey("npm") | Should -Be $true  
            $result.ContainsKey("git") | Should -Be $true
            $result["node"] | Should -Be "16.0.0"
            $result["npm"] | Should -Be "7.10.0"
            $result["git"] | Should -Be "2.30.1"
        }
    }
}