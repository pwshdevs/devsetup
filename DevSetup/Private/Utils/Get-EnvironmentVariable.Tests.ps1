BeforeAll {
    . $PSScriptRoot\Get-EnvironmentVariable.ps1
}

Describe "Get-EnvironmentVariable" {

    Context "When the environment variable exists" {
        It "Should return the value of the variable" {
            $env:TEST_ENV_VAR = "TestValue"
            $result = Get-EnvironmentVariable -Name "TEST_ENV_VAR"
            $result | Should -Be "TestValue"
            Remove-Item Env:\TEST_ENV_VAR
        }
    }

    Context "When the environment variable does not exist" {
        It "Should return null" {
            Remove-Item Env:\NOT_EXISTING_VAR -ErrorAction SilentlyContinue
            $result = Get-EnvironmentVariable -Name "NOT_EXISTING_VAR"
            $result | Should -Be $null
        }
    }

    Context "When called with pipeline input" {
        It "Should return the value for each variable" {
            $env:PIPE_VAR1 = "Value1"
            $env:PIPE_VAR2 = "Value2"
            $results = @("PIPE_VAR1", "PIPE_VAR2") | Get-EnvironmentVariable
            $results | Should -Contain "Value1"
            $results | Should -Contain "Value2"
            Remove-Item Env:\PIPE_VAR1
            Remove-Item Env:\PIPE_VAR2
        }
    }
}