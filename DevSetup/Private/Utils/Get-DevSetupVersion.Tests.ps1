BeforeAll {
    . $PSScriptRoot\Get-DevSetupVersion.ps1
    . $PSScriptRoot\Get-DevSetupManifest.ps1
}

Describe "Get-DevSetupVersion" {
    BeforeEach {
        Mock Get-DevSetupManifest { 
            return @{
                ModuleVersion = '1.0.0'
                PrivateData = @{
                    PSData = @{
                        ProjectUri = 'https://github.com/your/repo'
                    }
                }
            }
        }

        function Get-GitHubRelease {}

        Mock Get-GitHubRelease {
            return @{
                tag_name = '1.0.0'
            }
        }
    }
    It "should return the correct version when looking locally" {
        $version = Get-DevSetupVersion -Local
        $version | Should -Be "1.0.0"
    }

    It "should return the correct version when looking remotely" {
        $version = Get-DevSetupVersion -Remote
        $version | Should -Be "1.0.0"
    }
}