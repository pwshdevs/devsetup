BeforeAll {
    . $PSScriptRoot\Get-ScoopCacheFile.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-DevSetupCachePath.ps1
}

Describe "Get-ScoopCacheFile" {
    Context "When scoop is found by Get-Command" {
        BeforeEach {
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-DevSetupCachePath { return "$TestDrive\Users\Test User\devsetup\.cache" }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-DevSetupCachePath { return "$TestDrive/home/testuser/devsetup/.cache" }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-DevSetupCachePath { return "$TestDrive/Users/TestUser/devsetup/.cache" }
            }
        }
        It "should return the correct scoop cache file path" {
            $scoopCacheFile = Get-ScoopCacheFile
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $scoopCacheFile | Should -Be "$TestDrive\Users\Test User\devsetup\.cache\scoop.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $scoopCacheFile | Should -Be "$TestDrive/home/testuser/devsetup/.cache/scoop.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $scoopCacheFile | Should -Be "$TestDrive/Users/TestUser/devsetup/.cache/scoop.cache"
            }
        }
    }
}