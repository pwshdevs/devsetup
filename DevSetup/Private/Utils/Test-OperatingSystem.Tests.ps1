BeforeAll {
    . $PSScriptRoot\Test-OperatingSystem.ps1
    . $PSScriptRoot\Get-PwshVersion.ps1
}

Describe "Test-OperatingSystem" {

    if ($PSVersionTable.PSVersion.Major -eq 5) {
        BeforeAll { Mock Get-PwshVersion { [PSCustomObject]@{ Major = $PSVersionTable.PSVersion.Major } } }

        Context "When called with -Windows on PowerShell 5.1" {
            It "Should return $true" {
                $result = Test-OperatingSystem -Windows
                $result | Should -Be $true
            }
        }

        Context "When called with -Linux on PowerShell 5.1" {
            It "Should return $false" {
                $result = Test-OperatingSystem -Linux
                $result | Should -Be $false
            }
        }

        Context "When called with -MacOS on PowerShell 5.1" {
            It "Should return $false" {
                $result = Test-OperatingSystem -MacOS
                $result | Should -Be $false
            }
        }

        Context "When called with no parameters on PowerShell 5.1" {
            It "Should return $false" {
                $result = Test-OperatingSystem
                $result | Should -Be $false
            }
        }
    }

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        BeforeAll { Mock Get-PwshVersion { [PSCustomObject]@{ Major = $PSVersionTable.PSVersion.Major } } }
        if($IsWindows) {
            Context "When called in PowerShell 7+ (Windows)" {
                It "Should return value of `$IsWindows (default: $true)" {
                    $result = Test-OperatingSystem -Windows
                    $result | Should -Be $true
                }
                It "Should return value of `$IsLinux (default: $false)" {
                    $result = Test-OperatingSystem -Linux
                    $result | Should -Be $false
                }
                It "Should return value of `$IsMacOS (default: $false)" {
                    $result = Test-OperatingSystem -MacOS
                    $result | Should -Be $false
                }
                It "Should return $false if no parameter is specified" {
                    $result = Test-OperatingSystem
                    $result | Should -Be $false
                }
            }
        }

        if($IsLinux) {
            Context "When called in PowerShell 7+ (Linux)" {
                It "Should return value of `$IsWindows (default: $false)" {
                    $result = Test-OperatingSystem -Windows
                    $result | Should -Be $false
                }
                It "Should return value of `$IsLinux (default: $true)" {
                    $result = Test-OperatingSystem -Linux
                    $result | Should -Be $true
                }
                It "Should return value of `$IsMacOS (default: $false)" {
                    $result = Test-OperatingSystem -MacOS
                    $result | Should -Be $false
                }
                It "Should return $false if no parameter is specified" {
                    $result = Test-OperatingSystem
                    $result | Should -Be $false
                }
            }
        } 
        
        if($IsMacOS) {
            Context "When called in PowerShell 7+ (MacOS)" {
                It "Should return value of `$IsWindows (default: $false)" {
                    $result = Test-OperatingSystem -Windows
                    $result | Should -Be $false
                }
                It "Should return value of `$IsLinux (default: $false)" {
                    $result = Test-OperatingSystem -Linux
                    $result | Should -Be $false
                }
                It "Should return value of `$IsMacOS (default: $true)" {
                    $result = Test-OperatingSystem -MacOS
                    $result | Should -Be $true
                }
                It "Should return $false if no parameter is specified" {
                    $result = Test-OperatingSystem
                    $result | Should -Be $false
                }
            }
        }         
    }
}