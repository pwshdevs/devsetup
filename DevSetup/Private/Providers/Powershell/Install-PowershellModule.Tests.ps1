BeforeAll {
    . $PSScriptRoot\Install-PowershellModule.ps1
    . $PSScriptRoot\Test-PowershellModuleInstalled.ps1
    . $PSScriptRoot\Uninstall-PowershellModule.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    Mock Write-Error {}
    Mock Write-Warning {}
}

Describe "Install-PowershellModule" {

    Context "When installing for AllUsers without admin privileges" {
        It "Should return false" {
            Mock Test-RunningAsAdmin { return $false }
            $result = Install-PowershellModule -ModuleName "Az" -Scope "AllUsers"
            $result | Should -Be $false
        }
    }

    Context "When module is already installed with correct version and scope" {
        It "Should return true and not call Uninstall-PowershellModule or Install-Module" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-PowershellModuleInstalled { 
                return [InstalledState]::Pass
            }
            Mock Uninstall-PowershellModule { throw "Should not be called" }
            Mock Install-Module { throw "Should not be called" }
            $result = Install-PowershellModule -ModuleName "Az"
            $result | Should -Be $true
        }
    }

    Context "When module is installed but needs to be uninstalled and reinstalled" {
        It "Should uninstall and install the module, returning true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-PowershellModuleInstalled { 
                return [InstalledState]::Installed
            }
            $script:uninstallCalled = $false
            Mock Uninstall-PowershellModule -MockWith {
                param(
                    [string]$ModuleName,
                    [string]$Scope
                )
                $script:uninstallCalled = $true
            }
            $script:installCalled = $false
            Mock Install-Module -MockWith {
                param(
                    [string]$Name,
                    [switch]$Force,
                    [string]$Scope,
                    [switch]$AllowClobber,
                    [string]$RequiredVersion
                )
                $script:installCalled = $true
            }
            $result = Install-PowershellModule -ModuleName "Az"
            $result | Should -Be $true
            $uninstallCalled | Should -Be $true
            $installCalled | Should -Be $true
        }
    }

    Context "When module is not installed" {
        It "Should install the module and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-PowershellModuleInstalled { 
                return [InstalledState]::NotInstalled
            }
            $script:installCalled = $false
            Mock Install-Module -MockWith {
                param(
                    [string]$Name,
                    [switch]$Force,
                    [string]$Scope,
                    [switch]$AllowClobber,
                    [string]$RequiredVersion
                )
                $script:installCalled = $true
            }
            $result = Install-PowershellModule -ModuleName "Az"
            $result | Should -Be $true
            $installCalled | Should -Be $true
        }
    }

    Context "When Install-Module throws an exception" {
        It "Should return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-PowershellModuleInstalled { 
                return [InstalledState]::NotInstalled
            }
            Mock Install-Module { throw "Install failed" }
            $result = Install-PowershellModule -ModuleName "Az"
            $result | Should -Be $false
        }
    }

    Context "When Uninstall-PowershellModule throws an exception" {
        It "Should return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-PowershellModuleInstalled { 
                return [InstalledState]::Installed
            }
            Mock Uninstall-PowershellModule { throw "Uninstall failed" }
            Mock Install-Module -MockWith {
                param(
                    [string]$Name
                )
                $script:installParams = @{
                    ModuleName      = $Name
                }
            }            
            $result = Install-PowershellModule -ModuleName "Az"
            $result | Should -Be $true
        }
    }

    Context "When installing with Version, Force, and AllowClobber" {
        It "Should pass correct parameters and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-PowershellModuleInstalled { 
                return [InstalledState]::NotInstalled
            }
            Mock Install-Module -MockWith {
                param(
                    [string]$Name,
                    [switch]$Force,
                    [string]$Scope,
                    [switch]$AllowClobber,
                    [string]$RequiredVersion
                )
                $script:installParams = @{
                    ModuleName      = $Name
                    Force           = $Force
                    Scope           = $Scope
                    AllowClobber    = $AllowClobber
                    RequiredVersion = $RequiredVersion
                }
            }
            $result = Install-PowershellModule -ModuleName "Az" -Version "9.0.1" -Force -AllowClobber -Scope "CurrentUser"
            $result | Should -Be $true

            $installParams | Should -Not -Be $null
            $installParams.ModuleName | Should -Be "Az"
            $installParams.Force | Should -Be $true
            $installParams.Scope | Should -Be "CurrentUser"
            $installParams.AllowClobber | Should -Be $true
            $installParams.RequiredVersion | Should -Be "9.0.1"
        }
    }
}