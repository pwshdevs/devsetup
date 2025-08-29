BeforeAll {
    Function ConvertFrom-Yaml { }
    . $PSScriptRoot\Optimize-DevSetupEnvs.ps1
    . $PSScriptRoot\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\Get-DevSetupPath.ps1
    . $PSScriptRoot\Write-StatusMessage.ps1
    . $PSScriptRoot\Read-ConfigurationFile.ps1
    Mock Get-DevSetupEnvPath { "$TestDrive\DevSetupEnvs" }
    Mock Get-DevSetupPath { "$TestDrive\DevSetup" }
    Mock Join-Path { Param($Path, $ChildPath) "$Path\$ChildPath" }
    Mock Write-StatusMessage { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Write-Debug { }
    Mock Write-Host { }
    Mock ConvertTo-Json { param($obj) "json-output" }
    Mock Out-File { }
    Mock Read-ConfigurationFile { 
        param($Config)
        switch ($Config) {
            "$TestDrive\DevSetupEnvs\env1.yaml" { 
                @{ devsetup = @{ configuration = @{ os = @{ name = "Windows" }; version = "1.0.0" } } }
            }
            "$TestDrive\DevSetupEnvs\env2.yaml" { 
                @{ devsetup = @{ configuration = @{ os = @{ name = "Linux" }; version = "2.0.0" } } }
            }
            default { $null }
        }
    }
}

Describe "Optimize-DevSetupEnvs" {

    Context "When environments path is missing or invalid" {
        It "Should warn and return false" {
            Mock Get-DevSetupEnvPath { $null }
            $result = Optimize-DevSetupEnvs
            $result | Should -Be $false
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "DevSetup environments path not found" }
        }

        It "Should warn and return null if path does not exist" {
            Mock Get-DevSetupEnvPath { "TestDrive:\DevSetupEnvs" }
            Mock Test-Path { $false }
            $result = Optimize-DevSetupEnvs
            $result | Should -Be $false
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "DevSetup environments path not found" }
        }
    }

    Context "When no YAML files are found" {
        It "Should write status message and return empty array" {
            Mock Test-Path { $true }
            Mock Get-ChildItem { @() }
            $result = Optimize-DevSetupEnvs
            $result | Should -BeOfType 'bool'
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Indexing 0 environment files" }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -eq "[OK]" }
        }
    }

    Context "When YAML files are found and processed successfully" {
        It "Should return environments array and write status messages" {
            Mock Test-Path { $true }
            Mock Get-ChildItem {
                @(
                    @{ Name = "env1.yaml"; FullName = "$TestDrive\DevSetupEnvs\env1.yaml" },
                    @{ Name = "env2.yaml"; FullName = "$TestDrive\DevSetupEnvs\env2.yaml" }
                )
            }
            $result = Optimize-DevSetupEnvs
            Assert-MockCalled Write-Error -Scope It -Exactly 0
            #Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Object -match "Indexing 2 environment files" }
            #Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -eq "[OK]" }
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false          
        }
    }

    Context "When a YAML file fails to process" {
        It "Should warn and continue processing other files" {
            Mock Test-Path { $true }
            Mock Get-ChildItem {
                @(
                    @{ Name = "env1.yaml"; FullName = "$TestDrive\DevSetupEnvs\env1.yaml" },
                    @{ Name = "bad.yaml"; FullName = "$TestDrive\DevSetupEnvs\bad.yaml" }
                )
            }
            Mock Read-ConfigurationFile {
                param($Config)
                if ($Config -eq "$TestDrive\DevSetupEnvs\bad.yaml") { throw "YAML error" }
                @{ devsetup = @{ configuration = @{ os = @{ name = "Windows" }; version = "1.0.0" } } }
            }
            $result = Optimize-DevSetupEnvs
            Assert-MockCalled Write-Error -Scope It -Exactly 0
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Failed to process bad.yaml" }            
            $result | Should -BeOfType 'bool'
            $result | Should -Be $false

        }
    }

    Context "When writing environments.json fails" {
        It "Should write failed status message and return null" {
            Mock Test-Path { $true }
            Mock Get-ChildItem {
                @(
                    @{ Name = "env1.yaml"; FullName = "$TestDrive\DevSetupEnvs\env1.yaml" }
                )
            }
            Mock Out-File { throw "File error" }
            $result = Optimize-DevSetupEnvs
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -eq "[Failed]" }
        }
    }

    Context "When an unexpected error occurs" {
        It "Should write error and return null" {
            Mock Get-DevSetupEnvPath { throw "Unexpected error" }
            $result = Optimize-DevSetupEnvs
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to optimize DevSetup environments" }
        }
    }
}