BeforeAll {
    . $PSScriptRoot\Uninstall-PowershellModule.ps1
    . $PSScriptRoot\Test-PowershellModuleInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
}

Describe "Uninstall-PowershellModule" {

    BeforeEach {
        Mock Test-RunningAsAdmin { return $true }
        Mock Write-StatusMessage { }
        Mock Remove-Module { }
        Mock Uninstall-Module { }
    }

    Context "When module is not installed" {
        It "Should return true and log warning" {
            Mock Test-PowershellModuleInstalled { return [InstalledState]::NotInstalled }
            $result = Uninstall-PowershellModule -ModuleName "NonExistentModule"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "NonExistentModule.*is not installed"
            } -Times 1
        }
    }

    Context "When initial check throws exception" {
        It "Should return false and log error" {
            Mock Test-PowershellModuleInstalled { throw "Check failed" }
            $result = Uninstall-PowershellModule -ModuleName "ErrorModule"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "Error checking installation status"
            } -Times 1
        }
    }

    Context "When scope check throws exception" {
        It "Should return false and log error" {
            $callCount = 0
            Mock Test-PowershellModuleInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                throw "Scope check failed"
            }
            $result = Uninstall-PowershellModule -ModuleName "ScopeError"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "Error checking installation scope"
            } -Times 1
        }
    }

    Context "When AllUsers module but not admin" {
        It "Should return false and warn" {
            # Use parameter-based mocking instead of call counting
            Mock Test-PowershellModuleInstalled { return [InstalledState]::Installed } -ParameterFilter { -not $PSBoundParameters.ContainsKey('Scope') }
            Mock Test-PowershellModuleInstalled { return [InstalledState]::Pass } -ParameterFilter { $Scope -eq 'AllUsers' }
            Mock Test-RunningAsAdmin { return $false }
            $result = Uninstall-PowershellModule -ModuleName "AdminModule"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "installed for AllUsers but current session is not elevated"
            } -Times 1
        }
    }

    Context "When uninstall succeeds" {
        It "Should return true" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { return [InstalledState]::NotInstalled }
                return [InstalledState]::NotInstalled
            }
            $result = Uninstall-PowershellModule -ModuleName "TestModule" -Confirm:$false
            $result | Should -Be $true
            Assert-MockCalled Remove-Module -Times 1
            Assert-MockCalled Uninstall-Module -Times 1
        }
    }

    Context "When Remove-Module fails" {
        It "Should continue and succeed" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { return [InstalledState]::NotInstalled }
                return [InstalledState]::NotInstalled
            }
            Mock Remove-Module { throw "Remove failed" }
            $result = Uninstall-PowershellModule -ModuleName "TestModule" -Confirm:$false
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "Failed to remove module.*from current session"
            } -Times 1
            Assert-MockCalled Uninstall-Module -Times 1
        }
    }

    Context "When Uninstall-Module fails" {
        It "Should return false and log error" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                return [InstalledState]::NotInstalled
            }
            Mock Uninstall-Module { throw "Uninstall failed" }
            $result = Uninstall-PowershellModule -ModuleName "TestModule" -Confirm:$false
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "Error during Uninstall-Module"
            } -Times 1
        }
    }

    Context "When final verification fails" {
        It "Should return false and log error" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { throw "Verify failed" }
                return [InstalledState]::NotInstalled
            }
            $result = Uninstall-PowershellModule -ModuleName "TestModule" -Confirm:$false
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "Error verifying uninstallation"
            } -Times 1
        }
    }

    Context "When module still installed after uninstall" {
        It "Should return false" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled {
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }
                if ($script:callCount -eq 3) { return [InstalledState]::Installed }
                return [InstalledState]::Installed
            }
            $result = Uninstall-PowershellModule -ModuleName "TestModule" -Confirm:$false
            $result | Should -Be $false
        }
    }

    Context "When using WhatIf" {
        It "Should return true and not uninstall" {
            Mock Test-PowershellModuleInstalled { return [InstalledState]::Installed }
            $result = Uninstall-PowershellModule -ModuleName "TestModule" -WhatIf
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "was cancelled by user"
            } -Times 1
            Assert-MockCalled Remove-Module -Times 0
            Assert-MockCalled Uninstall-Module -Times 0
        }
    }

    Context "When scope installation check throws exception" {
        It "Should return false and log error" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { throw "Scope check failed" }
                return [InstalledState]::NotInstalled
            }
            $result = Uninstall-PowershellModule -ModuleName "ScopeErrorModule"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "Error checking installation scope.*ScopeErrorModule.*Scope check failed"
            } -Times 1
        }
    }

    Context "When module is installed for AllUsers but not running as admin" {
        It "Should return false and warn about privileges" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }
                if ($script:callCount -eq 2) { return [InstalledState]::Pass }  # Has Pass flag for AllUsers
                return [InstalledState]::NotInstalled
            }
            Mock Test-RunningAsAdmin { return $false }
            $result = Uninstall-PowershellModule -ModuleName "AdminRequiredModule"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "AdminRequiredModule.*installed for AllUsers but current session is not elevated"
            } -Times 1
        }
    }

    Context "When module uninstall succeeds" {
        It "Should return true and call Remove-Module and Uninstall-Module" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }       # Initial check
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }       # Scope check (CurrentUser)
                if ($script:callCount -eq 3) { return [InstalledState]::NotInstalled }    # Final verification
                return [InstalledState]::NotInstalled
            }
            $result = Uninstall-PowershellModule -ModuleName "SuccessModule" -Confirm:$false
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Debug" -and $Message -match "Uninstalling PowerShell module \'SuccessModule\'..."
            } -Times 1
            Assert-MockCalled Remove-Module -ParameterFilter { 
                $Name -eq "SuccessModule" -and $Force -eq $true
            } -Times 1
            Assert-MockCalled Uninstall-Module -ParameterFilter { 
                $Name -eq "SuccessModule" -and $Force -eq $true
            } -Times 1
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Debug" -and $Message -match "PowerShell module \'SuccessModule\' uninstalled successfully."
            } -Times 1
        }
    }

    Context "When Remove-Module throws exception" {
        It "Should log warning and continue with Uninstall-Module" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }       # Initial check
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }       # Scope check
                if ($script:callCount -eq 3) { return [InstalledState]::NotInstalled }    # Final verification
                return [InstalledState]::NotInstalled
            }
            Mock Remove-Module { throw "Remove-Module failed" }
            $result = Uninstall-PowershellModule -ModuleName "RemoveErrorModule" -Confirm:$false
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "Failed to remove module 'RemoveErrorModule' from current session.*Remove-Module failed"
            } -Times 1
            Assert-MockCalled Uninstall-Module -ParameterFilter { 
                $Name -eq "RemoveErrorModule" -and $Force -eq $true
            } -Times 1
        }
    }

    Context "When Uninstall-Module throws exception" {
        It "Should return false and log error" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }       # Initial check
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }       # Scope check
                return [InstalledState]::NotInstalled
            }
            Mock Uninstall-Module { throw "Uninstall-Module failed" }
            $result = Uninstall-PowershellModule -ModuleName "UninstallErrorModule" -Confirm:$false
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "Error during Uninstall-Module for 'UninstallErrorModule'.*Uninstall-Module failed"
            } -Times 1
        }
    }

    Context "When final verification throws exception" {
        It "Should return false and log error" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }       # Initial check
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }       # Scope check
                if ($script:callCount -eq 3) { throw "Final verification failed" }        # Final verification throws
                return [InstalledState]::NotInstalled
            }
            $result = Uninstall-PowershellModule -ModuleName "VerifyErrorModule" -Confirm:$false
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "Error verifying uninstallation.*VerifyErrorModule.*Final verification failed"
            } -Times 1
        }
    }

    Context "When module still shows as installed after uninstall" {
        It "Should return false" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }       # Initial check
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }       # Scope check
                if ($script:callCount -eq 3) { return [InstalledState]::Installed }       # Final verification - still installed
                return [InstalledState]::NotInstalled
            }
            $result = Uninstall-PowershellModule -ModuleName "PersistentModule" -Confirm:$false
            $result | Should -Be $false
            Assert-MockCalled Uninstall-Module -ParameterFilter { 
                $Name -eq "PersistentModule"
            } -Times 1
        }
    }

    Context "When using WhatIf parameter" {
        It "Should return true and not actually uninstall" {
            $script:callCount = 0
            Mock Test-PowershellModuleInstalled -MockWith {
                param($ModuleName, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return [InstalledState]::Installed }       # Initial check
                if ($script:callCount -eq 2) { return [InstalledState]::Installed }       # Scope check
                return [InstalledState]::NotInstalled
            }
            $result = Uninstall-PowershellModule -ModuleName "WhatIfModule" -WhatIf
            $result | Should -Be $true  # ShouldProcess returns false for WhatIf, so else branch returns true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "Uninstallation of PowerShell module 'WhatIfModule' was cancelled by user"
            } -Times 1
            Assert-MockCalled Remove-Module -Times 0
            Assert-MockCalled Uninstall-Module -Times 0
        }
    }

    Context "When user cancels ShouldProcess confirmation" {
        It "Should return true and log cancellation message" {
            # This test demonstrates the new behavior where cancellation returns true
            Mock Test-PowershellModuleInstalled { return [InstalledState]::Installed } -ParameterFilter { -not $PSBoundParameters.ContainsKey('Scope') }
            Mock Test-PowershellModuleInstalled { return [InstalledState]::Installed } -ParameterFilter { $Scope -eq 'AllUsers' }
            
            # Test using WhatIf to simulate ShouldProcess returning false
            $result = Uninstall-PowershellModule -ModuleName "CancelledModule" -WhatIf
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Warning" -and $Message -match "Uninstallation of PowerShell module 'CancelledModule' was cancelled by user"
            } -Times 1
            Assert-MockCalled Remove-Module -Times 0
            Assert-MockCalled Uninstall-Module -Times 0
        }
    }
}