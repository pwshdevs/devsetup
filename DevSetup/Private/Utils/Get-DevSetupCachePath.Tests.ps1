BeforeAll {
    . $PSScriptRoot\Get-DevSetupCachePath.ps1
    . $PSScriptRoot\Get-DevSetupPath.ps1
}

Describe "Get-DevSetupCachePath" {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Context "When running on Pwsh 5.1" {    
            BeforeEach {
                Mock Get-DevSetupPath { return "$TestDrive\Users\Test User\devsetup" }
            }
            It "should return the correct cache path for a valid user" {
                $cachePath = Get-DevSetupCachePath
                $cachePath | Should -Be "$TestDrive\Users\Test User\devsetup\.cache"
            }
        }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IsWindows) {
            Context "When running on Pwsh 6+ on Windows" {
                BeforeEach {
                    Mock Get-DevSetupPath { return "$TestDrive\Users\Test User\devsetup" }
                }
                It "should return the correct cache path for a valid user" {
                    $cachePath = Get-DevSetupCachePath
                    $cachePath | Should -Be "$TestDrive\Users\Test User\devsetup\.cache"
                }
            }
        } elseif ($IsLinux) {
            Context "When running on Pwsh 6+ on Linux" {
                BeforeEach {
                    Mock Get-DevSetupPath { return "$TestDrive/home/testuser/devsetup" }
                }
                It "should return the correct cache path for a valid user" {
                    $cachePath = Get-DevSetupCachePath
                    $cachePath | Should -Be "$TestDrive/home/testuser/devsetup/.cache"
                }
            }
        } elseif ($IsMacOS) {
            Context "When running on Pwsh 6+ on MacOS" {
                BeforeEach {
                    Mock Get-DevSetupPath { return "$TestDrive/Users/TestUser/devsetup" }
                }
                It "should return the correct cache path for a valid user" {
                    $cachePath = Get-DevSetupCachePath
                    $cachePath | Should -Be "$TestDrive/Users/TestUser/devsetup/.cache"
                }
            }
        }
    }
}