BeforeAll {
    # Define Write-EZLog function to avoid dependency issues
    Function Write-EZLog { }
    
    . (Join-Path $PSScriptRoot "Invoke-HomebrewComponentsExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Update-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Find-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Invoke-ExternalCommand.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Invoke-HomebrewComponentsExport" {
    Context "When Homebrew is not installed" {
        It "should return false" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ } } } }
            Mock Find-Homebrew { $null }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Homebrew is not installed" }
        }
    }

    Context "When export succeeds" {
        It "should update YAML data and save the file" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git 2.30.1", "node 14.17.0")
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git", "node")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 3 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 2 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Configuration saved successfully" }
        }

        It "should update existing packages instead of adding duplicates" {
            # Mock existing homebrew packages in the config
            Mock Read-DevSetupEnvFile { 
                @{ 
                    devsetup = @{ 
                        dependencies = @{ 
                            homebrew = @(
                                @{ name = "git"; minimumVersion = "2.25.0" },
                                @{ name = "node"; minimumVersion = "14.0.0" }
                            ) 
                        } 
                    } 
                } 
            }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git 2.30.1", "node 14.17.0")
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git", "node")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Updating package: git" }
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Updating package: node" }
        }

        It "should handle mixed scenario of existing and new packages" {
            # Mock existing homebrew packages in the config, but installed packages include new ones
            Mock Read-DevSetupEnvFile { 
                @{ 
                    devsetup = @{ 
                        dependencies = @{ 
                            homebrew = @(
                                @{ name = "git"; minimumVersion = "2.25.0" }
                            ) 
                        } 
                    } 
                } 
            }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git 2.30.1", "node 14.17.0", "wget 1.21.0")
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git", "node", "wget")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Updating package: git" }
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Adding package: node" }
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Adding package: wget" }
        }

        It "should handle packages with different version formats" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git 2.30.1_1", "node 14.17.0", "python@3.9 3.9.5")  # Different version formats
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git", "node", "python@3.9")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Adding package: git" }
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Adding package: node" }
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Adding package: python@3.9" }
        }

        It "should handle packages with no version information" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git", "node 14.17.0")  # git has no version, node has version
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git", "node")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Adding package: git" }
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter { $Message -match "Adding package: node" }
        }
    }

    Context "When saving fails" {
        It "should return false" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git 2.30.1")
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { throw "Save failed" }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to save configuration" }
        }
    }

    Context "When WhatIf is specified" {
        It "should not save the file" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git 2.30.1")
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            ($result = Invoke-HomebrewComponentsExport -Config "test.yaml" -WhatIf:$true) *> $null
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It  # Should not save
        }
    }

    Context "Edge cases and error handling" {
        It "should handle empty package list" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return ""  # Empty package list
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return ""  # Empty package list
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }

        It "should handle custom output file parameter" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments[1] -match "list --versions") {
                    return @("git 2.30.1")
                } elseif ($Arguments[1] -match "list --installed-on-request") {
                    return @("git")
                }
                return @()
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml" -OutFile "custom.yaml"
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $EnvFilePath -eq "custom.yaml" }
        }
    }

    Context "Cross-platform compatibility" {
        It "should handle Windows (where Homebrew is unlikely)" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ } } } }
            Mock Find-Homebrew { $null }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $false
        }

        It "should work on Linux" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/home/linuxbrew/.linuxbrew/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git"
                }
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
        }

        It "should work on macOS" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/opt/homebrew/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git"
                }
            }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
        }
    }
}