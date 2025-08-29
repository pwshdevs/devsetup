BeforeAll {
    . $PSScriptRoot\Uninstall-PowershellModule.ps1
    . $PSScriptRoot\Test-PowershellModuleInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1    
    Mock Test-RunningAsAdmin { return $true }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Write-Debug { }
}

Describe "Uninstall-PowershellModule" {

    Context "When module is not installed" {
        It "Should return true and warn" {
            Mock Test-PowershellModuleInstalled { return [InstalledState]::NotInstalled }
            $result = Uninstall-PowershellModule -ModuleName "notfound"
            $result | Should -Be $true
        }
    }

    Context "When module is installed for AllUsers but not running as admin" {
        It "Should return false and warn" {
            $callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $callCount++
                if ($callCount -eq 1) { return [InstalledState]::Installed }
                if ($callCount -eq 2) { return [InstalledState]::Pass }
                return [InstalledState]::NotInstalled
            }
            Mock Test-RunningAsAdmin { return $false }
            $result = Uninstall-PowershellModule -ModuleName "Az"
            $result | Should -Be $false
        }
    }

    Context "When module is installed and uninstall succeeds" {
        It "Should remove and uninstall the module, returning true" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { return [InstalledState]::NotInstalled }
                return [InstalledState]::NotInstalled
            }
            $script:removeCalled = $false
            $script:uninstallCalled = $false
            Mock Remove-Module -MockWith {
                param([string]$Name, [switch]$Force, [string]$ErrorAction)
                $script:removeCalled = $true
            }
            Mock Uninstall-Module -MockWith {
                param([string]$Name, [switch]$Force, [string]$ErrorAction)
                $script:uninstallCalled = $true
            }
            $result = Uninstall-PowershellModule -ModuleName "posh-git"
            $removeCalled | Should -Be $true
            $uninstallCalled | Should -Be $true            
            $result | Should -Be $true
        }
    }

    Context "When uninstall fails with exception" {
        It "Should return false and write error" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                return [InstalledState]::NotInstalled
            }
            Mock Remove-Module -MockWith {
                param([string]$Name, [switch]$Force, [string]$ErrorAction)
            }
            Mock Uninstall-Module -MockWith {
                param([string]$Name, [switch]$Force, [string]$ErrorAction)
                throw "Uninstall failed"
            }
            $result = Uninstall-PowershellModule -ModuleName "PSReadLine"
            $result | Should -Be $false
        }
    }

    Context "When module is installed but still present after uninstall" {
        It "Should return false" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { return [InstalledState]::Installed }
                return [InstalledState]::NotInstalled
            }
            Mock Remove-Module -MockWith {
                param([string]$Name, [switch]$Force, [string]$ErrorAction)
            }
            Mock Uninstall-Module -MockWith {
                param([string]$Name, [switch]$Force, [string]$ErrorAction)
            }
            $result = Uninstall-PowershellModule -ModuleName "PowerShellGet"
            $result | Should -Be $false
        }
    }
}