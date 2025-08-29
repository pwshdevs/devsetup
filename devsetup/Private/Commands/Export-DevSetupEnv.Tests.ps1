BeforeAll {
    . $PSScriptRoot\Export-DevSetupEnv.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Write-NewConfig.ps1
    Mock Get-DevSetupEnvPath { "C:\DevSetupEnvs" }
    Mock Write-NewConfig { param($OutFile) $OutFile }
    Mock Write-Host { }
    Mock Write-Error { }
}

Describe "Export-DevSetupEnv" {

    Context "When called with a valid name" {
        It "Should create the config file and return its path" {
            $result = Export-DevSetupEnv -Name "MyEnv"
            $result | Should -Be "C:\DevSetupEnvs\MyEnv.yaml"
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq "C:\DevSetupEnvs\MyEnv.yaml" }
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "exported to" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When called with a name that needs sanitization" {
        It "Should sanitize the name and warn" {
            $result = Export-DevSetupEnv -Name "Data Science Environment!"
            $result | Should -Be "C:\DevSetupEnvs\DataScienceEnvironment.yaml"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "sanitized" -and $ForegroundColor -eq "Yellow" }
        }
    }

    Context "When Write-NewConfig fails" {
        It "Should write error and return null" {
            Mock Write-NewConfig { param($OutFile) $null }
            $result = Export-DevSetupEnv -Name "FailEnv"
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to create configuration file" }
        }
    }
}