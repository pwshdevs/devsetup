BeforeAll {
    . (Join-Path $PSScriptRoot "Uninstall-PowershellModule.ps1")
    . (Join-Path $PSScriptRoot "Test-PowershellModuleInstalled.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Test-RunningAsAdmin { return $true }
    Mock Write-StatusMessage { }
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
                param()
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
                param()
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { return [InstalledState]::NotInstalled }
                return [InstalledState]::NotInstalled
            }
            $script:removeCalled = $false
            $script:uninstallCalled = $false
            Mock Remove-Module -MockWith {
                param()
                $script:removeCalled = $true
            }
            Mock Uninstall-Module -MockWith {
                param()
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
                param()
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                return [InstalledState]::NotInstalled
            }
            Mock Remove-Module -MockWith {
                param()
            }
            Mock Uninstall-Module -MockWith {
                param()
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
                param()
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { return [InstalledState]::Installed }
                return [InstalledState]::NotInstalled
            }
            Mock Remove-Module -MockWith {
                param()
            }
            Mock Uninstall-Module -MockWith {
                param()
            }
            $result = Uninstall-PowershellModule -ModuleName "PowerShellGet"
            $result | Should -Be $false
        }
    }
}