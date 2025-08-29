BeforeAll {
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    Mock Write-Warning { }
}

Describe "Test-ChocolateyInstalled" {

    Context "When Chocolatey is installed" {
        It "Should return true" {
            Mock Get-Command { [PSCustomObject]@{ Name = "choco" } }
            $result = Test-ChocolateyInstalled
            $result | Should -Be $true
            Assert-MockCalled Write-Warning -Exactly 0 -Scope It
        }
    }

    Context "When Chocolatey is not installed" {
        It "Should return false and write a warning" {
            Mock Get-Command { $null }
            $result = Test-ChocolateyInstalled
            $result | Should -Be $false
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "not installed" }
        }
    }
}