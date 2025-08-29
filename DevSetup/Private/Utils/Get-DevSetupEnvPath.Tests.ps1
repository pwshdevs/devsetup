BeforeAll {
    . $PSScriptRoot\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\Get-DevSetupPath.ps1
}

Describe "Get-DevSetupEnvPath" {
    BeforeEach {
        Mock Get-DevSetupPath { return 'TestDrive:\Users\Test User\.devsetup' }
    }
    It "should return the correct environment path for a valid user" {
        $envPath = Get-DevSetupEnvPath
        $envPath | Should -Be "TestDrive:\Users\Test User\.devsetup\environments"
    }
}