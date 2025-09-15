BeforeAll {
    . $PSScriptRoot\Get-DevSetupModuleInstallPath.ps1
    . $PSScriptRoot\..\Providers\Powershell\Get-PowershellModuleScopeMap.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
}

Describe "Get-DevSetupModuleInstallPath" {
    Context "When DevSetup module is installed in CurrentUser scope" {
        It "Should return the correct path" {
            $CurrentUserPath = (Join-Path (Join-Path (Join-Path $TestDrive "Documents" ) "PowerShell" ) "Modules")
            $AllUsersPath = (Join-Path (Join-Path (Join-Path $TestDrive "ProgramFiles" ) "PowerShell" ) "Modules")
            Mock Get-PowershellModuleScopeMap {
                return @(
                    @{ Scope = "CurrentUser"; Path = $CurrentUserPath },
                    @{ Scope = "AllUsers"; Path = $AllUsersPath }
                )
            }

            $expectedPath = Join-Path -Path $CurrentUserPath -ChildPath "DevSetup"
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $expectedPath }

            $result = Get-DevSetupModuleInstallPath
            $result | Should -Be $expectedPath
        }
    }

    Context "When DevSetup module is installed in AllUsers scope" {
        It "Should return the correct path" {
            $CurrentUserPath = (Join-Path (Join-Path (Join-Path $TestDrive "Documents" ) "PowerShell" ) "Modules")
            $AllUsersPath = (Join-Path (Join-Path (Join-Path $TestDrive "ProgramFiles" ) "PowerShell" ) "Modules")
            Mock Get-PowershellModuleScopeMap {
                return @(
                    @{ Scope = "CurrentUser"; Path = $CurrentUserPath },
                    @{ Scope = "AllUsers"; Path = $AllUsersPath }
                )
            }

            $expectedPath = Join-Path -Path $AllUsersPath -ChildPath "DevSetup"
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $expectedPath }

            $result = Get-DevSetupModuleInstallPath
            $result | Should -Be $expectedPath
        }
    }

    Context "When DevSetup module is not installed" {       
        It "Should return the first scope path if module is not found" {
            $CurrentUserPath = (Join-Path (Join-Path (Join-Path $TestDrive "Documents" ) "PowerShell" ) "Modules")
            $AllUsersPath = (Join-Path (Join-Path (Join-Path $TestDrive "ProgramFiles" ) "PowerShell" ) "Modules")             
            Mock Get-PowershellModuleScopeMap {
                return @(
                    @{ Scope = "CurrentUser"; Path = $CurrentUserPath },
                    @{ Scope = "AllUsers"; Path = $AllUsersPath }
                )
            }
            Mock Test-Path { return $false }
            $expectedPath = Join-Path -Path $CurrentUserPath -ChildPath "DevSetup"
            $result = Get-DevSetupModuleInstallPath
            $result | Should -Be $expectedPath
        }
    }
}