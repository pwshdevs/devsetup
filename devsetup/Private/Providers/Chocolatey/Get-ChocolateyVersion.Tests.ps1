BeforeAll {
    . $PSScriptRoot\Get-ChocolateyVersion.ps1
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    Mock Write-Warning { }
}

Describe "Get-ChocolateyVersion" {

    Context "When Chocolatey is not installed" {
        It "Should return null and write a warning" {
            Mock Test-ChocolateyInstalled { return $false }
            $result = Get-ChocolateyVersion
            $result | Should -Be $null
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "not installed" }
        }
    }

    Context "When Chocolatey is installed and version is returned" {
        It "Should return the trimmed version string" {
            Mock Test-ChocolateyInstalled { return $true }
            Mock Invoke-Expression { " 1.4.0 " }
            $result = Get-ChocolateyVersion
            $result | Should -Be "1.4.0"
        }
    }

    Context "When Chocolatey is installed but version is not returned" {
        It "Should return null and write a warning" {
            Mock Test-ChocolateyInstalled { return $true }
            Mock Invoke-Expression { $null }
            $result = Get-ChocolateyVersion
            $result | Should -Be $null
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to retrieve" }
        }
    }

    Context "When an error occurs during version retrieval" {
        It "Should return null and write a warning" {
            Mock Test-ChocolateyInstalled { return $true }
            Mock Invoke-Expression { throw "choco error" }
            $result = Get-ChocolateyVersion
            $result | Should -Be $null
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "An error occurred" }
        }
    }
}