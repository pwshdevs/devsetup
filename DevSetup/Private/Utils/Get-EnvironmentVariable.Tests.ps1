BeforeAll {
    . $PSScriptRoot\Get-EnvironmentVariable.ps1
    . $PSScriptRoot\Test-OperatingSystem.ps1
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

    Context "When using different scopes" {
        It "Should default to Process scope" {
            $env:SCOPE_TEST = "ProcessValue"
            $result = Get-EnvironmentVariable -Name "SCOPE_TEST"
            $result | Should -Be "ProcessValue"
            Remove-Item Env:\SCOPE_TEST
        }

        It "Should handle Process scope explicitly" {
            $env:SCOPE_TEST = "ProcessValue"
            $result = Get-EnvironmentVariable -Name "SCOPE_TEST" -Scope "Process"
            $result | Should -Be "ProcessValue"
            Remove-Item Env:\SCOPE_TEST
        }

        It "Should handle User scope on Windows" {
            # Test should not throw an exception and should return something or null
            { Get-EnvironmentVariable -Name "PATH" -Scope "User" } | Should -Not -Throw
            # Get the actual result and verify type if not null
            $result = Get-EnvironmentVariable -Name "PATH" -Scope "User"
            if ($result -ne $null) {
                $result | Should -BeOfType [string]
            }
        }

        It "Should handle Machine scope on Windows" {
            # Test should not throw an exception and should return something or null
            { Get-EnvironmentVariable -Name "PATH" -Scope "Machine" } | Should -Not -Throw
            # Get the actual result and verify type if not null
            $result = Get-EnvironmentVariable -Name "PATH" -Scope "Machine"
            if ($result -ne $null) {
                $result | Should -BeOfType [string]
            }
        }

        It "Should return null for User scope on non-Windows when IsWindows is false" {
            # Mock Test-OperatingSystem to return false for Windows
            Mock Test-OperatingSystem { return $false } -ParameterFilter { $Windows -eq $true }
            
            $result = Get-EnvironmentVariable -Name "PATH" -Scope "User"
            $result | Should -Be $null
        }

        It "Should return null for Machine scope on non-Windows when IsWindows is false" {
            # Mock Test-OperatingSystem to return false for Windows
            Mock Test-OperatingSystem { return $false } -ParameterFilter { $Windows -eq $true }
            
            $result = Get-EnvironmentVariable -Name "PATH" -Scope "Machine"
            $result | Should -Be $null
        }
        
        It "Should call Test-OperatingSystem when using User scope" {
            Mock Test-OperatingSystem { return $true } -ParameterFilter { $Windows -eq $true }
            
            Get-EnvironmentVariable -Name "PATH" -Scope "User" | Out-Null
            
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
        }
        
        It "Should call Test-OperatingSystem when using Machine scope" {
            Mock Test-OperatingSystem { return $true } -ParameterFilter { $Windows -eq $true }
            
            Get-EnvironmentVariable -Name "PATH" -Scope "Machine" | Out-Null
            
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
        }
    }
}