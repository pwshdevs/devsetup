BeforeAll {
    . $PSScriptRoot\Install-Scoop.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Get-ScoopVersion.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }
}

Describe "Install-Scoop" {
    Context "When scoop is installed" {
        BeforeEach {
            Mock Get-ScoopVersion { return '0.5.3' }
            Mock Test-ScoopInstalled { return $true }
        }
        It "Should return true" {
            Install-Scoop | Should -Be $true
        }
    }

    Context "When scoop is installed but the version cant be found" {
        BeforeEach {
            Mock Get-ScoopVersion { return $null }
            Mock Test-ScoopInstalled { return $true }    
        }

        It "Should return false" {
            Install-Scoop | Should -Be $false
        }
    }

    Context "When scoop is not installed" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $false }
            Mock Get-ScoopVersion { return '0.5.3' }
            Mock Set-ExecutionPolicy { return $true }
            Mock Invoke-RestMethod { return $true }
            Mock Invoke-Expression { return $true }
        }
        It "Should install it and return true" {
            Install-Scoop | Should -Be $true
        }
    }  
    
    Context "When scoop is not installed" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $false }
            Mock Get-ScoopVersion { return '0.5.3' }
            Mock Set-ExecutionPolicy { return $true }
            Mock Invoke-RestMethod { return $true }
            Mock Invoke-Expression { throw "Failed" }
        }
        It "Should try to install it and throw an error when it fails" {
            { Install-Scoop } | Should -Throw "Failed to install scoop: Failed"
        }
    }      
}