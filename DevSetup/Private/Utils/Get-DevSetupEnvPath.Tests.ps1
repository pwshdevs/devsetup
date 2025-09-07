BeforeAll {
    . $PSScriptRoot\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\Get-DevSetupPath.ps1
    . $PSScriptRoot\Test-OperatingSystem.ps1
}

Describe "Get-DevSetupEnvPath" {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Context "When running on Pwsh 5.1" {
            BeforeEach {
                Mock Get-DevSetupPath { return "$TestDrive\Users\Test User\devsetup" }
            }
            It "should return the correct environment path for a valid user" {
                $envPath = Get-DevSetupEnvPath
                $envPath | Should -Be "$TestDrive\Users\Test User\devsetup\environments"
            }
        }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        if($IsWindows) {
            Context "When running on Pwsh 6+" {
                BeforeEach {
                    Mock Get-DevSetupPath { return "$TestDrive\Users\Test User\devsetup" }
                }
                It "should return the correct environment path for a valid user" {
                    $envPath = Get-DevSetupEnvPath
                    $envPath | Should -Be "$TestDrive\Users\Test User\devsetup\environments"
                }
            }
        } elseif ($IsLinux) {
            Context "When running on Linux" {
                BeforeEach {
                    Mock Get-DevSetupPath { return "$TestDrive/home/testuser/devsetup" }
                }
                It "should return the correct environment path for a valid user" {
                    $envPath = Get-DevSetupEnvPath
                    $envPath | Should -Be "$TestDrive/home/testuser/devsetup/environments"
                }
            }
        } elseif ($IsMacOS) {
            Context "When running on MacOS" {
                BeforeEach {
                    Mock Get-DevSetupPath { return "$TestDrive/Users/TestUser/devsetup" }
                }
                It "should return the correct environment path for a valid user" {
                    $envPath = Get-DevSetupEnvPath
                    $envPath | Should -Be "$TestDrive/Users/TestUser/devsetup/environments"
                }
            }
        }
    }
}