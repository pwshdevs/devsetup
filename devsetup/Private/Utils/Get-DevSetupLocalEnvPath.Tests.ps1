BeforeAll {
    . $PSScriptRoot\Get-DevSetupLocalEnvPath.ps1
    . $PSScriptRoot\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\Get-DevSetupPath.ps1
    Mock Get-DevSetupEnvPath { "$TestDrive\Users\Test User\.devsetup\environments" }
    Mock Get-DevSetupPath { return "$TestDrive\Users\Test User\.devsetup" }
    Mock Join-Path { Param($Path, $ChildPath) "$Path\$ChildPath" }
}

Describe "Get-DevSetupLocalEnvPath" {
    It "Should call Get-DevSetupEnvPath and Join-Path, and return the correct path" {
        $result = Get-DevSetupLocalEnvPath
        $result | Should -Be "$TestDrive\Users\Test User\.devsetup\environments\local"
        Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
        Assert-MockCalled Join-Path -Exactly 1 -Scope It
    }

    It "Should handle different base paths" {
        Mock Get-DevSetupEnvPath { "$TestDrive\CustomPath" }
        $result = Get-DevSetupLocalEnvPath
        $result | Should -Be "$TestDrive\CustomPath\local"
    }
}