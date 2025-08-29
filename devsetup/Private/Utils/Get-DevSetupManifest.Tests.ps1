BeforeAll {
    . $PSScriptRoot\Get-DevSetupManifest.ps1
}

Describe "Get-DevSetupManifest" {
    BeforeEach {
        Mock Get-Module { 
            return @{
                ModuleBase = "$PSScriptRoot\..\..\..\DevSetup"
            }
        }
    }
    It "should return the manifest file and not null" {
        $manifest = Get-DevSetupManifest
        $manifest | Should -Not -BeNullOrEmpty
    }

    It "should contain the RootModule" {
        $manifest = Get-DevSetupManifest
        $manifest.RootModule | Should -Not -BeNullOrEmpty
    }
}