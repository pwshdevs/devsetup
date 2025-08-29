BeforeAll {
    . $PSScriptRoot\Install-Chocolatey.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }    
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Get-Command { $null }
    Mock Invoke-Expression { }
    Mock Set-ExecutionPolicy { }
}

Describe "Install-Chocolatey" {

    Context "When not running on Windows" {
        It "Should skip installation and return true" {
            Mock Test-OperatingSystem { param($Windows) $false }
            $result = Install-Chocolatey
            $result | Should -Be $true
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -match "not available on this platform" }
        }
    }

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-OperatingSystem { param($Windows) $true }
            Mock Test-RunningAsAdmin { return $false }
            $result = Install-Chocolatey
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "administrator privileges" }
        }
    }

    Context "When Chocolatey is already installed" {
        It "Should return true and show version" {
            Mock Test-OperatingSystem { param($Windows) $true }
            Mock Test-RunningAsAdmin { return $true }
            Mock Get-Command { [PSCustomObject]@{ Name = "choco" } }
            Mock Invoke-Expression { "1.4.0" }
            $result = Install-Chocolatey
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "[OK]" }
        }
    }

    Context "When Chocolatey is not installed and installation succeeds" {
        It "Should install and return true" {
            Mock Test-OperatingSystem { param($Windows) $true }
            $script:installCalled = $false
            $script:commandCallCount = 0
            Mock Test-RunningAsAdmin { return $true }
            Mock Get-Command -MockWith {
                $script:commandCallCount++
                if ($script:commandCallCount -eq 1) { return $null }
                else { return [PSCustomObject]@{ Name = "choco" } }
            }
            Mock Invoke-Expression -MockWith {
                param($expr)
                if ($expr -like "*--version*") { return "1.4.0" }
                $script:installCalled = $true
            }
            $result = Install-Chocolatey
            $result | Should -Be $true
            $script:installCalled | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "[OK]" }
        }
    }

    Context "When Chocolatey is not installed and installation fails" {
        It "Should return false and write error" {
            Mock Test-OperatingSystem { param($Windows) $true }
            $script:commandCallCount = 0
            Mock Test-RunningAsAdmin { return $true }
            Mock Get-Command -MockWith {
                $script:commandCallCount++
                return $null
            }
            Mock Invoke-Expression { }
            $result = Install-Chocolatey
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to install" }
        }
    }

    Context "When an unexpected error occurs" {
        It "Should return false and write error" {
            Mock Test-OperatingSystem { param($Windows) $true }
            Mock Test-RunningAsAdmin { throw "Unexpected error" }
            $result = Install-Chocolatey
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Error checking/installing Chocolatey" }
        }
    }
}