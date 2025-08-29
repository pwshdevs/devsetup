BeforeAll {
    . $PSScriptRoot\Get-ScoopCacheFile.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-DevSetupCachePath.ps1
}

Describe "Get-ScoopCacheFile" {
    Context "When scoop is found by Get-Command" {
        BeforeEach {
            Mock Get-DevSetupCachePath { return 'TestDrive:\Users\Test User\.devsetup\.cache' }
        }
        It "should return the correct scoop cache file path" {
            $scoopCacheFile = Get-ScoopCacheFile
            $scoopCacheFile | Should -Be "TestDrive:\Users\Test User\.devsetup\.cache\scoop.cache"
        }
    }
}