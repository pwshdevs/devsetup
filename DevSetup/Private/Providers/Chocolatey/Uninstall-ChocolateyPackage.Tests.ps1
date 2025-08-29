BeforeAll {
    . $PSScriptRoot\Uninstall-ChocolateyPackage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1    
    Mock Test-RunningAsAdmin { $true }
    Mock Write-Debug { }
    Mock Write-Error { }
    Mock Invoke-Expression { }
}

Describe "Uninstall-ChocolateyPackage" {

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-RunningAsAdmin { $false }
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "administrator privileges" }
        }
    }

    Context "When uninstallation succeeds" {
        It "Should return true and write debug" {
            Mock Test-RunningAsAdmin { $true }
            $global:LASTEXITCODE = 0
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $true
            Assert-MockCalled Write-Debug -Scope It -ParameterFilter { $Message -match "uninstalled successfully" }
        }
    }

    Context "When uninstallation fails (non-zero exit code)" {
        It "Should write error and return false" {
            Mock Test-RunningAsAdmin { $true }
            $global:LASTEXITCODE = 1
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to uninstall" }
        }
    }

    Context "When an exception occurs during uninstall" {
        It "Should write error and return false" {
            Mock Test-RunningAsAdmin { $true }
            Mock Invoke-Expression { throw "Unexpected error" }
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Error uninstalling Chocolatey package" }
        }
    }
}