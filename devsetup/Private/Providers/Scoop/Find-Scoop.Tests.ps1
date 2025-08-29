BeforeAll {
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
}

Describe "Find-Scoop" {
    Context "When scoop is found by Get-Command" {
        BeforeEach {
            Mock Get-Command { return 'TestDrive:\Users\Test User\scoop\shims\scoop.ps1' }
        }
        It "should return scoop" {
            $scoop = Find-Scoop
            $scoop | Should -Be "scoop"
        }
    }

    Context "When scoop is not found by Get-Command or any other option it should return null" {
        BeforeEach {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return 'TestDrive:\Users\Test User' }
        }
        It "should return null" {
            $scoop = Find-Scoop
            $scoop | Should -BeNullOrEmpty
        }
    }

    Context "When scoop is not found by Get-Command but scoop.ps1 is found" {
        BeforeEach {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return 'TestDrive:\Users\Test User' }
            New-Item -Path 'TestDrive:\Users\Test User\scoop\shims' -ItemType Directory -Force | Out-Null
            Set-Content 'TestDrive:\Users\Test User\scoop\shims\scoop.ps1' -Value 'Scoop PowerShell Script'
        }
        It "should return TestDrive:\Users\Test User\scoop\shims\scoop.ps1" {
            $scoop = Find-Scoop
            $scoop | Should -Be "TestDrive:\Users\Test User\scoop\shims\scoop.ps1"
        }
    }

    Context "When scoop is not found by Get-Command but scoop.cmd is found" {
        BeforeEach {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return 'TestDrive:\Users\Test User' }
            New-Item -Path 'TestDrive:\Users\Test User\scoop\shims' -ItemType Directory -Force | Out-Null
            Set-Content 'TestDrive:\Users\Test User\scoop\shims\scoop.cmd' -Value 'Scoop Command Script'
        }
        It "should return TestDrive:\Users\Test User\scoop\shims\scoop.cmd" {
            $scoop = Find-Scoop
            $scoop | Should -Be "TestDrive:\Users\Test User\scoop\shims\scoop.cmd"
        }
    }
    
    Context "When scoop is not found by Get-Command but scoop is found" {
        BeforeEach {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return 'TestDrive:\Users\Test User' }
            New-Item -Path 'TestDrive:\Users\Test User\scoop\shims' -ItemType Directory -Force | Out-Null
            Set-Content 'TestDrive:\Users\Test User\scoop\shims\scoop' -Value 'Scoop Command Script'
        }
        It "should return TestDrive:\Users\Test User\scoop\shims\scoop" {
            $scoop = Find-Scoop
            $scoop | Should -Be "TestDrive:\Users\Test User\scoop\shims\scoop"
        }
    }    
}