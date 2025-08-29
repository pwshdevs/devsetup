BeforeAll {
    . $PSScriptRoot\Uninstall-ScoopBucket.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1
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
        It "Should return true and debug" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
            $result = Uninstall-ScoopBucket -Name "extras"
            $result | Should -Be $true
        }
    }

    Context "When bucket uninstall command fails" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $true }
            Mock Invoke-Expression { $global:LASTEXITCODE = 1 }
            $result = Uninstall-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }

    Context "When Write-ScoopCache fails after uninstall" {
        It "Should return false and error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $false }
            Mock Invoke-Expression { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }

    Context "When bucket is successfully uninstalled" {
        It "Should return true and debug" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Write-ScoopCache { return $true }
            Mock Invoke-Expression { $global:LASTEXITCODE = 0 }
            $result = Uninstall-ScoopBucket -Name "extras"
            $result | Should -Be $true
        }
    }

    Context "When an exception occurs during uninstall" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { throw "Unexpected error" }
            $result = Uninstall-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }
}