BeforeAll {
    . $PSScriptRoot\Install-ScoopBucket.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1    
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1
}

Describe "Install-ScoopBucket" {
    Context "When scoop is not installed" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $false }
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }    
    Context "When scoop is not found" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }
    Context "When a Bucket is already installed" {
        It "Should return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $true
        }
    }    
    Context "When a Bucket is not already installed and it fails to install it" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 1
                return $null
            } -Verifiable
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }

    Context "When a Bucket is not already installed and it gets installed but fails to write the cache" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            } -Verifiable
            Mock Write-ScoopCache { return $false }
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    }
    Context "When a Bucket is not already installed and installing it causes an error to be thrown" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                throw 'Failed'
            } -Verifiable
            Mock Write-ScoopCache { return $true }
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }
    } 
    Context "When a Bucket is not already installed and it gets installed and writes the cache" {
        It "Should return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            } -Verifiable
            Mock Write-ScoopCache { return $true }
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $true
        }
    } 
}