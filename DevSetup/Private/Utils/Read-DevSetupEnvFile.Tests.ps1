BeforeAll {
    function ConvertFrom-Yaml { }
    function Assert-DevSetupEnvValid { }
    . $PSScriptRoot\Read-DevSetupEnvFile.ps1
    . $PSScriptRoot\Assert-DevSetupEnvValid.ps1
    Mock Get-Content { }
    Mock ConvertFrom-Yaml { }
    Mock Assert-DevSetupEnvValid { $true }
}

Describe "Read-DevSetupEnvFile" {

    Context "When configuration file exists and contains valid YAML" {
        It "Should return parsed YAML data after validation" {
            $validYamlData = @{ devsetup = @{ configuration = @{}; dependencies = @{}; commands = @() } }
            Mock Get-Content { "valid yaml content" }
            Mock ConvertFrom-Yaml { $validYamlData }
            Mock Assert-DevSetupEnvValid { }  # Don't return anything, just don't throw
            
            $result = Read-DevSetupEnvFile -Config "config.yaml"
            
            $result | Should -BeOfType System.Collections.Hashtable
            $result.devsetup | Should -Not -BeNullOrEmpty
            Assert-MockCalled Assert-DevSetupEnvValid -Exactly 1 -Scope It -ParameterFilter { $EnvData -eq $validYamlData }
        }
    }

    Context "When configuration file does not exist" {
        It "Should throw an error" {
            Mock Get-Content { throw "File not found" }
            { Read-DevSetupEnvFile -Config "missing.yaml" } | Should -Throw "File not found"
        }
    }

    Context "When YAML is invalid" {
        It "Should throw an error from ConvertFrom-Yaml" {
            Mock Get-Content { "invalid: yaml: -" }
            Mock ConvertFrom-Yaml { throw "Invalid YAML" }
            { Read-DevSetupEnvFile -Config "bad.yaml" } | Should -Throw "Invalid YAML"
        }
    }

    Context "When ConvertFrom-Yaml returns null" {
        It "Should throw configuration error for null data" {
            Mock Get-Content { "key: value" }
            Mock ConvertFrom-Yaml { $null }
            
            { Read-DevSetupEnvFile -Config "config.yaml" } | Should -Throw "Configuration file 'config.yaml' is empty or returned null data."
        }
    }
    
    Context "When YAML structure is invalid" {
        It "Should throw validation error for missing devsetup section" {
            Mock Get-Content { "somekey: value" }
            Mock ConvertFrom-Yaml { @{ somekey = "value" } }
            Mock Assert-DevSetupEnvValid { throw "Environment data must contain 'devsetup' key." }
            
            { Read-DevSetupEnvFile -Config "config.yaml" } | Should -Throw "Environment data must contain 'devsetup' key."
            Assert-MockCalled Assert-DevSetupEnvValid -Exactly 1 -Scope It
        }
        
        It "Should throw validation error for malformed devsetup structure" {
            Mock Get-Content { "devsetup: invalid" }
            Mock ConvertFrom-Yaml { @{ devsetup = "invalid" } }
            Mock Assert-DevSetupEnvValid { throw "'devsetup' must be a hashtable or PSCustomObject." }
            
            { Read-DevSetupEnvFile -Config "config.yaml" } | Should -Throw "'devsetup' must be a hashtable or PSCustomObject."
            Assert-MockCalled Assert-DevSetupEnvValid -Exactly 1 -Scope It
        }
        
        It "Should throw validation error for missing required sections" {
            Mock Get-Content { "devsetup: {}" }
            Mock ConvertFrom-Yaml { @{ devsetup = @{} } }
            Mock Assert-DevSetupEnvValid { throw "Environment data 'devsetup' section must contain 'configuration' key." }
            
            { Read-DevSetupEnvFile -Config "config.yaml" } | Should -Throw "Environment data 'devsetup' section must contain 'configuration' key."
            Assert-MockCalled Assert-DevSetupEnvValid -Exactly 1 -Scope It
        }
    }
}