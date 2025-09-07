BeforeAll {
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
    if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
        Mock Get-EnvironmentVariable { return "$TestDrive\Users\TestUser" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
        Mock Get-EnvironmentVariable { return "$TestDrive/home/testuser" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
        Mock Get-EnvironmentVariable { return "$TestDrive/Users/TestUser" }
    }
}

Describe "Test-ScoopInstalled" {

    Context "When scoop command is available in PATH" {
        It "Should return true" {
            Mock Get-Command { return @{ Name = "scoop" } }
            $result = Test-ScoopInstalled
            $result | Should -Be $true
        }
    }

    Context "When scoop command is not available but scoop.ps1 exists" {
        It "Should return true" {
            Mock Get-Command { return $null }
            Mock Test-Path { param($path) if ($path -like "*scoop.ps1") { return $true } else { return $false } }
            $result = Test-ScoopInstalled
            $result | Should -Be $true
        }
    }

    Context "When scoop command is not available but scoop.cmd exists" {
        It "Should return true" {
            Mock Get-Command { return $null }
            Mock Test-Path { param($path) if ($path -like "*scoop.cmd") { return $true } else { return $false } }
            $result = Test-ScoopInstalled
            $result | Should -Be $true
        }
    }

    Context "When scoop command is not available but scoop executable exists" {
        It "Should return true" {
            Mock Get-Command { return $null }
            Mock Test-Path { param($path) if ($path -like "*scoop") { return $true } else { return $false } }
            $result = Test-ScoopInstalled
            $result | Should -Be $true
        }
    }

    Context "When scoop is not installed at all" {
        It "Should return false" {
            Mock Get-Command { return $null }
            Mock Test-Path { return $false }
            $result = Test-ScoopInstalled
            $result | Should -Be $false
        }
    }
}