BeforeAll {
    . $PSScriptRoot\Get-DevSetupCachePath.ps1
    . $PSScriptRoot\Get-DevSetupPath.ps1
}

Describe "Get-DevSetupCachePath" {
    BeforeEach {
        Mock Get-DevSetupPath { return 'TestDrive:\Users\Test User\.devsetup' }
    }
    It "should return the correct cache path for a valid user" {
        $cachePath = Get-DevSetupCachePath
        $cachePath | Should -Be "TestDrive:\Users\Test User\.devsetup\.cache"
    }
}