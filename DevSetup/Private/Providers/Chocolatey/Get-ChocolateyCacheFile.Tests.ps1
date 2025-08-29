BeforeAll {
    . $PSScriptRoot\Get-ChocolateyCacheFile.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-DevSetupCachePath.ps1
    Mock Write-Error { }
}

Describe "Get-ChocolateyCacheFile" {

    Context "When Get-DevSetupCachePath returns a valid path" {
        It "Should return the correct cache file path" {
            Mock Get-DevSetupCachePath { return "C:\Users\Test\.devsetup\.cache" }
            $result = Get-ChocolateyCacheFile
            $result | Should -Be "C:\Users\Test\.devsetup\.cache\chocolatey.cache"
        }
    }

    Context "When Get-DevSetupCachePath returns a different path" {
        It "Should append chocolatey.cache to the returned path" {
            Mock Get-DevSetupCachePath { return "D:\DevSetupCache" }
            $result = Get-ChocolateyCacheFile
            $result | Should -Be "D:\DevSetupCache\chocolatey.cache"
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