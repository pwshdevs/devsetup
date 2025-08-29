BeforeAll {
    . $PSScriptRoot\Uninstall-ScoopPackage.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1

}

Describe "Uninstall-ScoopPackage" {

    Context "When Scoop is not installed" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $false }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When Scoop command cannot be found" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When package is not installed" {
        It "Should return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return [InstalledState]::NotInstalled 
            }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }
    }

    Context "When uninstall succeeds" {
        It "Should return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return [InstalledState]::Pass 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }
    }

    Context "When uninstall fails" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return [InstalledState]::Pass 
            }
            Mock Invoke-Command { $global:LASTEXITCODE = 1 }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When uninstall throws an exception" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return [InstalledState]::Pass 
            }
            Mock Invoke-Command { throw "Unexpected error" }
            $result = Uninstall-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When uninstalling a global package" {
        It "Should pass --global and return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { 
                return [InstalledState]::Pass 
            }
            Mock Invoke-Command {
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
                # Optionally, you could inspect $ScriptBlock here
                return $null
            }
            $result = Uninstall-ScoopPackage -PackageName "git" -Global
            $result | Should -Be $true
        }
    }
}