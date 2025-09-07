BeforeAll {
    . $PSScriptRoot\Get-DevSetupPath.ps1
    . $PSScriptRoot\Get-EnvironmentVariable.ps1
    . $PSScriptRoot\Test-OperatingSystem.ps1
    Mock Test-OperatingSystem { $true }
}

Describe "Get-DevSetupPath" {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Context "When running on Pwsh 5.1" {
            BeforeEach {
                Mock Get-EnvironmentVariable { return "$TestDrive\Users\Test User" }
            }
            It "should return the correct devsetup for the current user" {
                $envPath = Get-DevSetupPath
                $envPath | Should -Be "$TestDrive\Users\Test User\devsetup"
            }
        }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        Context "When running on Pwsh 6+" {
            BeforeEach {
                if ($IsWindows) {
                    Mock Get-EnvironmentVariable { return (Join-Path $TestDrive "Users" "Test User") }
                } elseif( $IsLinux) {
                    Mock Get-EnvironmentVariable { return (Join-Path $TestDrive "home" "testuser") }
                } elseif ($IsMacOS) {
                    Mock Get-EnvironmentVariable { return (Join-Path $TestDrive "Users" "TestUser") }
                }
                Mock Test-OperatingSystem { $true }
            }

            if($IsLinux) {
                It "should return the correct devsetup for the current user on Linux" {
                    $envPath = Get-DevSetupPath
                    $envPath | Should -Be (Join-Path $TestDrive "home" "testuser" "devsetup")
                }
            }

            if($IsMacOS) {
                It "should return the correct devsetup for the current user on MacOS" {
                    Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $MacOS } }
                    $envPath = Get-DevSetupPath
                    $envPath | Should -Be (Join-Path $TestDrive "Users" "TestUser" "devsetup")
                }
            }

            if($IsWindows) {
                It "should return the correct devsetup for the current user on Windows" {
                    Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $Windows } }
                    $envPath = Get-DevSetupPath
                    $envPath | Should -Be (Join-Path $TestDrive "Users" "Test User" "devsetup")
                }
            }
        }
    }
}