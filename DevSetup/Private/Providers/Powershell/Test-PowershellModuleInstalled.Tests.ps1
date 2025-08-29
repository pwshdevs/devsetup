BeforeAll {
    . $PSScriptRoot\Test-PowershellModuleInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1     
}

Describe "Test-PowershellModuleInstalled" {

    Context "When module is not installed" {
        It "Should return NotInstalled" {
            Mock Get-Module { return $null }
            $result = Test-PowershellModuleInstalled -ModuleName "notfound"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }

    Context "When module is installed (any version, any scope)" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "posh-git"
                    Version = "1.0.0"
                    Path = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\posh-git"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "posh-git"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed with matching version" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "PSReadLine"
                    Version = "2.2.6"
                    Path = "$env:USERPROFILE\Documents\PowerShell\Modules\PSReadLine"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "PSReadLine" -Version "2.2.6"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed but version does not match" {
        It "Should return Installed + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "PSReadLine"
                    Version = "2.2.5"
                    Path = "$env:USERPROFILE\Documents\PowerShell\Modules\PSReadLine"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "PSReadLine" -Version "2.2.6"
            $expected = [InstalledState]::Installed + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed in AllUsers scope" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "PowerShellGet"
                    Version = "2.2.5"
                    Path = "$env:ProgramFiles\PowerShell\Modules\PowerShellGet"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "PowerShellGet" -Scope "AllUsers"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed in CurrentUser scope" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "Az"
                    Version = "9.0.1"
                    Path = "$env:USERPROFILE\Documents\PowerShell\Modules\Az"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "Az" -Scope "CurrentUser"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When Get-Module throws an exception" {
        It "Should return NotInstalled" {
            Mock Get-Module { throw "Unexpected error" }
            $result = Test-PowershellModuleInstalled -ModuleName "Az"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }
}