BeforeAll {
    . (Join-Path $PSScriptRoot "Show-ExplainDevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Format-PrettyTable.ps1")
    Mock Write-StatusMessage { }
    Mock Get-DevSetupEnvPath { "$TestDrive\devsetup" }
    Mock Read-DevSetupEnvFile { 
        return @{
            devsetup = @{
                name = "Test Environment"
                configuration = @{
                    description = "Test description"
                    version = "1.0.0"
                    createdBy = "Test User"
                    createdDate = "2023-01-01"
                    lastUpdatedDate = "2023-01-02"
                    os = @{
                        name = "Windows"
                        version = "10.0"
                        architecture = "x64"
                    }
                }
                dependencies = @{
                    chocolatey = @{
                        packages = @(@{ name = "git"; version = "2.0.0" })
                    }
                    powershell = @{
                        modules = @(@{ name = "PSScriptAnalyzer"; minimumVersion = "1.0.0" })
                    }
                }
                commands = @(@{ name = "test command" })
            }
        }
    }
    Mock Format-PrettyTable { }
    Mock Test-Path { return $true } -ParameterFilter { $Path -match "\.devsetup$" }
}

Describe "Show-ExplainDevSetupEnv" {

    Context "When name is provided without provider" {
        It "Should use local provider and display information" {
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Reading environment file" -and $ForegroundColor -eq "Gray" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "This environment installs" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When name is provided with provider" {
        It "Should parse provider and name correctly" {
            Show-ExplainDevSetupEnv -Name "remote:testenv"
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When path is provided and file exists" {
        It "Should use provided path" {
            $testFile = "$TestDrive\test.devsetup"
            New-Item -ItemType File -Path $testFile
            Show-ExplainDevSetupEnv -Path $testFile
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When path is provided but file does not exist" {
        BeforeEach {
            Mock Test-Path { return $false } -ParameterFilter { $Path -match "\.devsetup$" }
        }
        It "Should write error and return" {
            $testFile = "$TestDrive\nonexistent.devsetup"
            Show-ExplainDevSetupEnv -Path $testFile
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Invalid Path provided" -and $Verbosity -eq "Error" }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "When constructed file path does not exist" {
        BeforeEach {
            Mock Test-Path { return $false } -ParameterFilter { $Path -match "\.devsetup$" }
        }
        It "Should write error and return" {
            Mock Test-Path { return $false } -ParameterFilter { $Path -match "\.devsetup$" }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file not found" -and $Verbosity -eq "Error" }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "When Read-DevSetupEnvFile returns null" {
        It "Should write error and return" {
            Mock Read-DevSetupEnvFile { return $null }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to read or parse" -and $Verbosity -eq "Error" }
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
        }
    }

    Context "When YAML data has no dependencies" {
        It "Should handle empty dependencies gracefully" {
            Mock Read-DevSetupEnvFile { 
                return @{
                    devsetup = @{
                        name = "Test Environment"
                        configuration = @{
                            description = "Test description"
                            version = "1.0.0"
                            createdBy = "Test User"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{
                                name = "Windows"
                                version = "10.0"
                                architecture = "x64"
                            }
                        }
                        dependencies = @{}
                        commands = @()
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When YAML data has no commands" {
        It "Should handle empty commands gracefully" {
            Mock Read-DevSetupEnvFile { 
                return @{
                    devsetup = @{
                        name = "Test Environment"
                        configuration = @{
                            description = "Test description"
                            version = "1.0.0"
                            createdBy = "Test User"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{
                                name = "Windows"
                                version = "10.0"
                                architecture = "x64"
                            }
                        }
                        dependencies = @{
                            chocolatey = @{
                                packages = @(@{ name = "git"; version = "2.0.0" })
                            }
                        }
                        commands = $null
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When dependencies have empty packages and modules" {
        It "Should handle empty collections" {
            Mock Read-DevSetupEnvFile { 
                return @{
                    devsetup = @{
                        name = "Test Environment"
                        configuration = @{
                            description = "Test description"
                            version = "1.0.0"
                            createdBy = "Test User"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{
                                name = "Windows"
                                version = "10.0"
                                architecture = "x64"
                            }
                        }
                        dependencies = @{
                            chocolatey = @{
                                packages = @()
                            }
                            powershell = @{
                                modules = @()
                            }
                        }
                        commands = @()
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When name is empty" {
        It "Should throw due to parameter validation" {
            { Show-ExplainDevSetupEnv -Name "" } | Should -Throw
        }
    }

    Context "When path is empty" {
        It "Should throw due to parameter validation" {
            { Show-ExplainDevSetupEnv -Path "" } | Should -Throw
        }
    }

    Context "When neither name nor path is provided" {
        It "Should throw due to parameter set requirements" {
            { Show-ExplainDevSetupEnv } | Should -Throw
        }
    }

    Context "When provider has multiple colons" {
        It "Should use first part as provider" {
            Show-ExplainDevSetupEnv -Name "remote:extra:testenv"
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }
}
