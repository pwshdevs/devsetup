BeforeAll {
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
    if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
        Mock Get-EnvironmentVariable { return "$TestDrive\Users\Test User" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
        Mock Get-EnvironmentVariable { return "$TestDrive/home/testuser" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
        Mock Get-EnvironmentVariable { return "$TestDrive/Users/TestUser" }
    }    
}

Describe "Find-Scoop" {
    Context "When scoop is found by Get-Command" {
        BeforeEach {
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-Command { return "$TestDrive\Users\Test User\scoop\shims\scoop.ps1" }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-Command { return "$TestDrive/home/testuser/scoop/shims/scoop" }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-Command { return "$TestDrive/Users/TestUser/scoop/shims/scoop" }
            }
        }
        It "should return scoop" {
            $scoop = Find-Scoop
            $scoop | Should -Be "scoop"
        }
    }

    Context "When scoop is not found by Get-Command or any other option it should return null" {
        BeforeEach {
            Mock Get-Command { return $null }
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-EnvironmentVariable { return "$TestDrive\Users\Test User" }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-EnvironmentVariable { return "$TestDrive/home/testuser" }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-EnvironmentVariable { return "$TestDrive/Users/TestUser" }
            }
        }
        It "should return null" {
            $scoop = Find-Scoop
            $scoop | Should -BeNullOrEmpty
        }
    }

    Context "When scoop is not found by Get-Command but scoop.ps1 is found" {
        BeforeEach {
            Mock Get-Command { return $null }
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-EnvironmentVariable { return "$TestDrive\Users\Test User" }
                New-Item -Path "$TestDrive\Users\Test User\scoop\shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive\Users\Test User\scoop\shims\scoop.ps1" -Value 'Scoop PowerShell Script'
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-EnvironmentVariable { return "$TestDrive/home/testuser" }
                New-Item -Path "$TestDrive/home/testuser/scoop/shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive/home/testuser/scoop/shims/scoop.ps1" -Value 'Scoop Command Script'
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-EnvironmentVariable { return "$TestDrive/Users/TestUser" }
                New-Item -Path "$TestDrive/Users/TestUser/scoop/shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive/Users/TestUser/scoop/shims/scoop.ps1" -Value 'Scoop Command Script'
            }
        }
        It "should return scoop.ps1" {
            $scoop = Find-Scoop
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $scoop | Should -Be "$TestDrive\Users\Test User\scoop\shims\scoop.ps1"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $scoop | Should -Be "$TestDrive/home/testuser/scoop/shims/scoop.ps1"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $scoop | Should -Be "$TestDrive/Users/TestUser/scoop/shims/scoop.ps1"
            }
        }
    }

    Context "When scoop is not found by Get-Command but scoop.cmd is found" {
        BeforeEach {
            Mock Get-Command { return $null }
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-EnvironmentVariable { return "$TestDrive\Users\Test User" }
                New-Item -Path "$TestDrive\Users\Test User\scoop\shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive\Users\Test User\scoop\shims\scoop.cmd" -Value 'Scoop Command Script'
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-EnvironmentVariable { return "$TestDrive/home/testuser" }
                New-Item -Path "$TestDrive/home/testuser/scoop/shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive/home/testuser/scoop/shims/scoop.cmd" -Value 'Scoop Command Script'
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-EnvironmentVariable { return "$TestDrive/Users/TestUser" }
                New-Item -Path "$TestDrive/Users/TestUser/scoop/shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive/Users/TestUser/scoop/shims/scoop.cmd" -Value 'Scoop Command Script'
            }
        }
        It "should return scoop.cmd" {
            $scoop = Find-Scoop
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $scoop | Should -Be "$TestDrive\Users\Test User\scoop\shims\scoop.cmd"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $scoop | Should -Be "$TestDrive/home/testuser/scoop/shims/scoop.cmd"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $scoop | Should -Be "$TestDrive/Users/TestUser/scoop/shims/scoop.cmd"
            }
        }
    }
    
    Context "When scoop is not found by Get-Command but scoop is found" {
        BeforeEach {
            Mock Get-Command { return $null }
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-EnvironmentVariable { return "$TestDrive\Users\Test User" }
                New-Item -Path "$TestDrive\Users\Test User\scoop\shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive\Users\Test User\scoop\shims\scoop" -Value 'Scoop Command Script'
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-EnvironmentVariable { return "$TestDrive/home/testuser" }
                New-Item -Path "$TestDrive/home/testuser/scoop/shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive/home/testuser/scoop/shims/scoop" -Value 'Scoop Command Script'
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-EnvironmentVariable { return "$TestDrive/Users/TestUser" }
                New-Item -Path "$TestDrive/Users/TestUser/scoop/shims" -ItemType Directory -Force | Out-Null
                Set-Content "$TestDrive/Users/TestUser/scoop/shims/scoop" -Value 'Scoop Command Script'
            }
        }
        It "should return scoop" {
            $scoop = Find-Scoop
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                $scoop | Should -Be "$TestDrive\Users\Test User\scoop\shims\scoop"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                $scoop | Should -Be "$TestDrive/home/testuser/scoop/shims/scoop"
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                $scoop | Should -Be "$TestDrive/Users/TestUser/scoop/shims/scoop"
            }
        }
    }    
}