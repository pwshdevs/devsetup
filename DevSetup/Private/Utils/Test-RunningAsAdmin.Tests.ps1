BeforeAll {
    . $PSScriptRoot\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\Test-OperatingSystem.ps1
    Mock Test-OperatingSystem { param($Windows) $false }
}

Describe "Test-RunningAsAdmin" {

    Context "When not running on Windows" {
        It "Should return true (assume sufficient privileges)" {
            Mock Test-OperatingSystem { param($Windows) $false }
            $result = Test-RunningAsAdmin
            $result | Should -Be $true
        }
    }

    Context "When running on Windows as administrator" {
        It "Should return true" {
            Mock Test-OperatingSystem { param($Windows) $true }
            class MockPrincipal {
                [bool] IsInRole([object]$role) { return $true }
            }
            Mock 'New-Object' -MockWith {
                param($type)
                return [MockPrincipal]::new()
            }
            $result = Test-RunningAsAdmin
            $result | Should -Be $true
        }
    }

    Context "When running on Windows but not as administrator" {
        It "Should return false" {
            Mock Test-OperatingSystem { param($Windows) $true }
            class MockPrincipal {
                [bool] IsInRole([object]$role) { return $false }
            }
            Mock 'New-Object' -MockWith {
                param($type)
                return [MockPrincipal]::new()
            }
            $result = Test-RunningAsAdmin
            $result | Should -Be $false
        }
    }
}