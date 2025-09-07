BeforeAll {
    . $PSScriptRoot\Get-ChocolateyCacheFile.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-DevSetupCachePath.ps1
    Mock Write-Error { }
}

Describe "Get-ChocolateyCacheFile" {
    Context "When Get-DevSetupCachePath returns a valid path" {
        It "Should return the correct cache file path" {
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-DevSetupCachePath { return "$TestDrive\Users\Test\devsetup\.cache" }
                $result = Get-ChocolateyCacheFile
                $result | Should -Be "$TestDrive\Users\Test\devsetup\.cache\chocolatey.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-DevSetupCachePath { return "$TestDrive/home/testuser/devsetup/.cache" }
                $result = Get-ChocolateyCacheFile
                $result | Should -Be "$TestDrive/home/testuser/devsetup/.cache/chocolatey.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-DevSetupCachePath { return "$TestDrive/Users/TestUser/devsetup/.cache" }
                $result = Get-ChocolateyCacheFile
                $result | Should -Be "$TestDrive/Users/TestUser/devsetup/.cache/chocolatey.cache"
            }
        }
    }

    Context "When Get-DevSetupCachePath returns a different path" {
        It "Should append chocolatey.cache to the returned path" {
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-DevSetupCachePath { return "$TestDrive\DevSetupCache" }
                $result = Get-ChocolateyCacheFile
                $result | Should -Be "$TestDrive\DevSetupCache\chocolatey.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-DevSetupCachePath { return "$TestDrive/home/testuser/devsetupcache/.cache" }
                $result = Get-ChocolateyCacheFile
                $result | Should -Be "$TestDrive/home/testuser/devsetupcache/.cache/chocolatey.cache"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-DevSetupCachePath { return "$TestDrive/Users/TestUser/devsetupcache/.cache" }
                $result = Get-ChocolateyCacheFile
                $result | Should -Be "$TestDrive/Users/TestUser/devsetupcache/.cache/chocolatey.cache"
            }
        }
    }

    Context "When Get-DevSetupCachePath returns an empty string" {
        It "Should write error and return null" {
            Mock Get-DevSetupCachePath { return "" }
            $result = Get-ChocolateyCacheFile
            $result | Should -Be $null
        }
    }
}