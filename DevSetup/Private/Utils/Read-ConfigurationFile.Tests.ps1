BeforeAll {
    function ConvertFrom-Yaml { }
    . $PSScriptRoot\Read-ConfigurationFile.ps1
    Mock Get-Content { }
    Mock ConvertFrom-Yaml { }
}

Describe "Read-ConfigurationFile" {

    Context "When configuration file exists and contains valid YAML" {
        It "Should return parsed YAML data" {
            Mock Get-Content { "key: value" }
            Mock ConvertFrom-Yaml { @{ key = "value" } }
            $result = Read-ConfigurationFile -Config "config.yaml"
            $result | Should -BeOfType System.Collections.Hashtable
            $result.key | Should -Be "value"
        }
    }

    Context "When configuration file does not exist" {
        It "Should throw an error" {
            Mock Get-Content { throw "File not found" }
            { Read-ConfigurationFile -Config "missing.yaml" } | Should -Throw "File not found"
        }
    }

    Context "When YAML is invalid" {
        It "Should throw an error from ConvertFrom-Yaml" {
            Mock Get-Content { "invalid: yaml: -" }
            Mock ConvertFrom-Yaml { throw "Invalid YAML" }
            { Read-ConfigurationFile -Config "bad.yaml" } | Should -Throw "Invalid YAML"
        }
    }

    Context "When ConvertFrom-Yaml returns $null" {
        It "Should return null" {
            Mock Get-Content { "key: value" }
            Mock ConvertFrom-Yaml { $null }
            $result = Read-ConfigurationFile -Config "config.yaml"
            $result | Should -Be $null
        }
    }
}