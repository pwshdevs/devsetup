BeforeAll {
    . $PSScriptRoot\Uninstall-ChocolateyPackage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1    
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Test-RunningAsAdmin { $true }
    Mock Write-StatusMessage { }
    Mock Invoke-Command { }
}

Describe "Uninstall-ChocolateyPackage" {

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-RunningAsAdmin { $false }
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "administrator privileges" -and $Verbosity -eq "Error"}
        }
    }

    Context "When uninstallation succeeds" {
        It "Should return true and write debug" {
            Mock Test-RunningAsAdmin { $true }
            $global:LASTEXITCODE = 0
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "uninstalled successfully" -and $Verbosity -eq "Debug"}
        }
    }

    Context "When uninstallation fails (non-zero exit code)" {
        It "Should write error and return false" {
            Mock Test-RunningAsAdmin { $true }
            $global:LASTEXITCODE = 1
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to uninstall" -and $Verbosity -eq "Error" }
        }
    }

    Context "When an exception occurs during uninstall" {
        It "Should write error and return false" {
            Mock Test-RunningAsAdmin { $true }
            Mock Invoke-Command { throw "Unexpected error" }
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Error uninstalling Chocolatey package" -and $Verbosity -eq "Error" }
        }
    }
}