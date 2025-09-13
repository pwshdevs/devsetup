BeforeAll {
    # Define stub functions before dot-sourcing
    Function Write-EZLog {}
    
    . $PSScriptRoot\Uninstall-ScoopBucket.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1
    . $PSScriptRoot\..\..\Utils\Write-StatusMessage.ps1
    
    # Global mocks
    Mock Write-EZLog { }
    Mock Write-Host { }
    Mock Write-Error { }
}

Describe "Uninstall-ScoopBucket" {

    Context "When Scoop is not installed" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $false }
            $result = Uninstall-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }

    Context "When Scoop command cannot be found" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            $result = Uninstall-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }

    Context "When bucket is already uninstalled" {
        It "Should return true and display already uninstalled message" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $true
        }
    }

    Context "When bucket uninstall command fails" {
        It "Should return false when bucket removal command fails" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 1 }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $false
        }
    }

    Context "When Write-ScoopCache fails after uninstall" {
        It "Should return false when cache update fails" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $false }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $false
        }
    }

    Context "When bucket is successfully uninstalled" {
        It "Should return true and display success message" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $true
        }
    }

    Context "When an exception occurs during uninstall" {
        It "Should return false when Test-ScoopComponentInstalled throws exception" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { throw "Unexpected error checking bucket state" }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $false
        }
    }

    Context "When exceptions occur in various operations" {
        It "Should return false when Test-ScoopInstalled throws exception" {
            Mock Test-ScoopInstalled { throw "Scoop check failed" }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $false
        }

        It "Should return false when Find-Scoop throws exception" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { throw "Cannot find Scoop command" }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $false
        }

        It "Should return false when Invoke-Command throws exception during uninstall" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command { throw "Command execution failed" }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $false
        }

        It "Should return false when Write-ScoopCache throws exception" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { throw "Cache write failed" }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $false
        }
    }

    Context "When using WhatIf parameter" {
        It "Should not execute bucket removal when WhatIf is specified" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            
            $result = Uninstall-ScoopBucket -Name "extras" -WhatIf
            
            $result | Should -Be $true
            Should -Invoke Invoke-Command -Times 0 -Exactly
            # Write-ScoopCache should not be called with WhatIf due to -WhatIf:$PSCmdlet.WhatIf
            Should -Invoke Write-ScoopCache -Times 0 -Exactly
        }

        It "Should return true when WhatIf is used with already uninstalled bucket" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
            
            $result = Uninstall-ScoopBucket -Name "extras" -WhatIf
            
            $result | Should -Be $true
        }
    }

    Context "When using ShouldProcess functionality" {
        It "Should execute normally when ShouldProcess returns true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            
            $result = Uninstall-ScoopBucket -Name "extras"
            
            $result | Should -Be $true
            Should -Invoke Invoke-Command -Times 1 -Exactly
            Should -Invoke Write-ScoopCache -Times 1 -Exactly
        }
    }
}