BeforeAll {
    Function Remove-Item {
        Param(
            [string]$Path,
            [switch]$Recurse,
            [switch]$Force
        )
    }

    Function Test-Path {
        Param(
            [string]$Path
        )
    }

    . $PSScriptRoot\Uninstall-DevSetupModule.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\Get-DevSetupModuleInstallPath.ps1
    Mock Write-StatusMessage { }
}

Describe "Uninstall-DevSetupModule" {
    Context "When DevSetup module is installed" {
        It "Should uninstall the module and return true" {
            $modulePath = Join-Path -Path $TestDrive -ChildPath "DevSetup"

            Mock Get-DevSetupModuleInstallPath { return $modulePath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $modulePath }
            Mock Remove-Item { return $true }

            $result = Uninstall-DevSetupModule
            $result | Should -Be $true

            Assert-MockCalled Remove-Item -Times 1 -ParameterFilter { $Path -eq $modulePath }
            Assert-MockCalled Write-StatusMessage -Times 1 -ParameterFilter {
                $Message -match "Successfully uninstalled DevSetup module from '$([regex]::Escape($modulePath))'."
            }
        }

        It "Should handle errors during uninstallation and return false" {
            $modulePath = Join-Path -Path $TestDrive -ChildPath "DevSetup"

            Mock Get-DevSetupModuleInstallPath { return $modulePath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $modulePath }
            Mock Remove-Item { throw "Error during removal" }

            $result = Uninstall-DevSetupModule
            $result | Should -Be $false

            Assert-MockCalled -CommandName Remove-Item -Times 1 -ParameterFilter { $Path -eq $modulePath }
            Assert-MockCalled Write-StatusMessage -Times 1 -ParameterFilter {
                $Message -match "Failed to uninstall DevSetup module from '$([regex]::Escape($modulePath))': Error during removal" -and 
                $Verbosity -eq "Error" 
            }
        }
    }

    Context "When DevSetup module is not installed" {
        It "Should return true and indicate no action taken" {
            $modulePath = Join-Path -Path $TestDrive -ChildPath "DevSetup"
            Mock Get-DevSetupModuleInstallPath { return $modulePath }
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $modulePath }

            $result = Uninstall-DevSetupModule
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Times 1 -ParameterFilter {
                $Message -eq "DevSetup module is not installed. No action taken." -and 
                $Verbosity -eq "Warning" 
            }
        }
    }
}