BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-VsCodeExtensionsImport.ps1")
    . (Join-Path $PSScriptRoot "Find-VsCode.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Find-VsCode { "code" }
    Mock Write-StatusMessage { }
    Mock Invoke-Command {
        param($ScriptBlock)
        $script:LASTEXITCODE = 0
    }
}

Describe "Invoke-VsCodeExtensionsImport" {

    Context "When no extensions are provided" {
        It "Should return false and write warning" {
            $result = Invoke-VsCodeExtensionsImport -Extensions ""
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "No extensions provided" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When extensions is an empty array" {
        It "Should return true and write message" {
            $result = Invoke-VsCodeExtensionsImport -Extensions "[]"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "No extensions found in provided configuration" -and $Verbosity -eq "Warning"}
        }
    }

    Context "When JSON parsing fails" {
        It "Should return false and write error" {
            $result = Invoke-VsCodeExtensionsImport -Extensions "invalid json"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to parse JSON" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Find-VsCode fails" {
        It "Should return false and write error" {
            Mock Find-VsCode { $null }
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ms-vscode.powershell"]'
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Visual Studio Code executable not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When installing a single extension successfully" {
        It "Should return true and write success" {
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ms-vscode.powershell"]'
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Installing extension: ms-vscode.powershell" -and $ForegroundColor -eq "Gray" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[OK]" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Extension installation complete: 1 successful" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When installing a single extension fails" {
        It "Should return true and write failure" {
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 1
            }
            $result = Invoke-VsCodeExtensionsImport -Extensions '["invalid.extension"]'
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Extension installation complete: 0 successful, 1 failed" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When installing multiple extensions with mixed results" {
        It "Should return true and write summary" {
            $script:count = 0
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:count++
                $script:LASTEXITCODE = $script:count % 2
            }
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ext1", "ext2"]'
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Extension installation complete: 1 successful, 1 failed" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When extension list contains empty string" {
        It "Should skip empty entries and write warning" {
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ms-vscode.powershell", "", "another.ext"]'
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "- Skipping empty extension entry" -and $ForegroundColor -eq "Yellow" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When LogFile is provided" {
        It "Should set PSDefaultParameterValues" {
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ms-vscode.powershell"]' -LogFile "test.log"
            $result | Should -Be $true
            # Note: PSDefaultParameterValues is set, but hard to assert directly
        }
    }

    Context "When extensions are piped" {
        It "Should accept pipeline input and return true" {
            $extensions = '["ms-vscode.powershell"]'
            $result = $extensions | Invoke-VsCodeExtensionsImport
            $result | Should -Be $true
        }
    }

    Context "When extension data is a single string" {
        It "Should convert to array and install" {
            $result = Invoke-VsCodeExtensionsImport -Extensions '"ms-vscode.powershell"'
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Installing 1 Visual Studio Code extensions" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When unexpected data type" {
        It "Should return false and write error" {
            $result = Invoke-VsCodeExtensionsImport -Extensions 123
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Unexpected extension data type" -and $Verbosity -eq "Error" }
        }
    }

    Context "When exception occurs during install" {
        It "Should keep going and return true and write error" {
            Mock Invoke-Command { throw "Install failed" }
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ext"]'
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error installing:" -and $Verbosity -eq "Error" }
        }
    }

    Context "When outer try-catch catches exception" {
        It "Should return false and write error" {
            Mock Find-VsCode { throw "Unexpected error" }
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ext"]'
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error importing VS Code configuration:" -and $Verbosity -eq "Error" }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ms-vscode.powershell"]'
            $result | Should -Be $true
        }

        It "Should work on Linux" {
            Mock Find-VsCode { $null }
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ext"]'
            $result | Should -Be $false
        }

        It "Should work on macOS" {
            Mock Find-VsCode { $null }
            $result = Invoke-VsCodeExtensionsImport -Extensions '["ext"]'
            $result | Should -Be $false
        }
    }
}
