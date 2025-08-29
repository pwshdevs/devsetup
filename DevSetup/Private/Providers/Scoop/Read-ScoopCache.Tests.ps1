BeforeAll {
    . $PSScriptRoot\Read-ScoopCache.ps1
    . $PSScriptRoot\Get-ScoopCacheFile.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
}

Describe "Read-ScoopCache" {

    Context "When cache file exists and contains valid JSON" {
        It "Should return deserialized object" {
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            Mock Test-Path { return $true }
            $json = '{"apps":[{"name":"git","version":"2.42.0"}]}'
            Mock Get-Content { $json }
            $result = Read-ScoopCache
            $result.apps[0].name | Should -Be "git"
            $result.apps[0].version | Should -Be "2.42.0"
        }
    }

    Context "When cache file does not exist and Write-ScoopCache succeeds" {
        It "Should create cache and return deserialized object" {
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            $testPathCallCount = 0
            Mock Test-Path -MockWith {
                $testPathCallCount++
                if ($testPathCallCount -eq 1) { return $false }
                else { return $true }
            }
            Mock Write-ScoopCache { return $true }
            $json = '{"apps":[{"name":"git","version":"2.42.0"}]}'
            Mock Get-Content { $json }
            # Do NOT mock ConvertFrom-Json here!
            $result = Read-ScoopCache
            $result.apps[0].name | Should -Be "git"
        }
    }

    Context "When cache file does not exist and Write-ScoopCache fails" {
        It "Should throw an exception" {
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            Mock Test-Path { return $false }
            Mock Write-ScoopCache { return $false }
            { Read-ScoopCache } | Should -Throw "Failed to create Scoop cache file: C:\fakepath\scoop.cache"
        }
    }

    Context "When cache file contains invalid JSON" {
        It "Should return null and write error" {
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            Mock Test-Path { return $true }
            Mock Get-Content { return "not-json" }
            Mock ConvertFrom-Json { throw "Invalid JSON" }
            $result = Read-ScoopCache
            $result | Should -Be $null
        }
    }

    Context "When Get-Content throws an exception" {
        It "Should return null and write error" {
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            Mock Test-Path { return $true }
            Mock Get-Content { throw "File read error" }
            $result = Read-ScoopCache
            $result | Should -Be $null
        }
    }
}