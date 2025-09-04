BeforeAll {
    . $PSScriptRoot\Get-DevSetupPath.ps1
    . $PSScriptRoot\Get-EnvironmentVariable.ps1
    . $PSScriptRoot\Test-OperatingSystem.ps1
    Mock Test-OperatingSystem { $true }
}

Describe "Get-DevSetupPath" {
    BeforeEach {
        Mock Get-EnvironmentVariable { return 'TestDrive:\Users\Test User' }
    }
    It "should return the correct devsetup for the current user" {
        $envPath = Get-DevSetupPath
        $envPath | Should -Be "TestDrive:\Users\Test User\devsetup"
    }
}