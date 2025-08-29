BeforeAll {
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Get-ScoopCacheFile.ps1
}

Describe "Write-ScoopCache" {

    Context "When Scoop is not installed" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $false }
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            $result = Write-ScoopCache
            $result | Should -Be $false
        }
    }

    Context "When Scoop command cannot be found" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            $result = Write-ScoopCache
            $result | Should -Be $false
        }
    }

    Context "When cache file is written successfully" {
        It "Should return true and debug" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            Mock Invoke-Expression { "exported data" }
            Mock Set-Content { param($Path, $Value, $Force) return $null }
            $result = Write-ScoopCache
            $result | Should -Be $true
        }
    }

    Context "When writing cache file fails" {
        It "Should return false and error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            Mock Invoke-Expression { "exported data" }
            Mock Set-Content { throw "Failed to write file" }
            $result = Write-ScoopCache
            $result | Should -Be $false
        }
    }

    Context "When scoop export throws an exception" {
        It "Should return false and error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopCacheFile { return "C:\fakepath\scoop.cache" }
            Mock Invoke-Expression { throw "export failed" }
            $result = Write-ScoopCache
            $result | Should -Be $false
        }
    }
}