BeforeAll {
    Function ConvertTo-Yaml { }
    . (Join-Path $PSScriptRoot "Invoke-HomebrewComponentsExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Find-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Invoke-ExternalCommand.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Invoke-HomebrewComponentsExport" {
    Context "When Homebrew is not installed" {
        It "should return false" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ } } } }
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
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1`nnode 14.17.0"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git`nnode"
                }
            }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-ConfigurationFile -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 3 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 2 -Scope It
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Configuration saved successfully" }
        }
    }

    Context "When YAML conversion fails" {
        It "should fall back to JSON and save" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git"
                }
            }
            Mock ConvertTo-Yaml { throw "YAML conversion failed" }
            Mock ConvertTo-Json { "mock json output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled ConvertTo-Json -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It
        }
    }

    Context "When saving fails" {
        It "should return false" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git"
                }
            }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { throw "Save failed" }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Out-File -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to save configuration" }
        }
    }

    Context "When WhatIf is specified" {
        It "should not save the file" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git"
                }
            }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }

            ($result = Invoke-HomebrewComponentsExport -Config "test.yaml" -WhatIf:$true) *> $null
            $result | Should -Be $true
            Assert-MockCalled Out-File -Exactly 0 -Scope It  # Should not save
        }
    }

    Context "Cross-platform compatibility" {
        It "should handle Windows (where Homebrew is unlikely)" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ } } } }
            Mock Find-Homebrew { $null }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $false
        }

        It "should work on Linux" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/home/linuxbrew/.linuxbrew/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git"
                }
            }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
        }

        It "should work on macOS" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ homebrew = @() } } } }
            Mock Find-Homebrew { "/opt/homebrew/bin/brew" }
            Mock Invoke-ExternalCommand {
                Param($Arguments)
                if ($Arguments -contains "list --versions") {
                    return "git 2.30.1"
                } elseif ($Arguments -contains "list --installed-on-request") {
                    return "git"
                }
            }
            Mock ConvertTo-Yaml { "mock yaml output" }
            Mock Out-File { }
            Mock Write-StatusMessage { }

            $result = Invoke-HomebrewComponentsExport -Config "test.yaml"
            $result | Should -Be $true
        }
    }
}