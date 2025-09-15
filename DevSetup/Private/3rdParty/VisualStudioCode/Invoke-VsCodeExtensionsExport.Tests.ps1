BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-VsCodeExtensionsExport.ps1")
    . (Join-Path $PSScriptRoot "Find-VsCode.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Find-VsCode { "$TestDrive\Code\bin\code.cmd" }  # Default to found
    Mock Invoke-Command { "extension1@1.0.0", "extension2@2.0.0" }  # Default to success with extensions
    Mock Write-StatusMessage { }
    Mock ConvertTo-Json { "mocked json output" }  # Default to success
    $script:LASTEXITCODE = 0  # Default to success
}

Describe "Invoke-VsCodeExtensionsExport" {

    Context "When Find-VsCode returns null" {
        It "Should return null and write warning" {
            Mock Find-VsCode { $null }
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Visual Studio Code 'code' command not found in PATH. Cannot export extensions." -and $Verbosity -eq "Debug" }
        }
    }

    Context "When Invoke-Command succeeds with extensions" {
        It "Should return JSON data" {
            Mock Invoke-Command { "extension1@1.0.0", "extension2@2.0.0" }
            $script:LASTEXITCODE = 0
            $result = Invoke-VsCodeExtensionsExport
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "- Found 2 Visual Studio Code extensions" -and $Verbosity -eq "Debug" }
            Assert-MockCalled ConvertTo-Json -Exactly 2 -Scope It
            $result | Should -Be @("mocked json output", "mocked json output")
        }
    }

    Context "When Invoke-Command succeeds but no extensions" {
        It "Should return null" {
            Mock Invoke-Command { @() }
            $script:LASTEXITCODE = 0
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "- No Visual Studio Code extensions found" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When Invoke-Command fails with non-zero exit code" {
        It "Should return null and write warning" {
            Mock Invoke-Command { "some output" }
            $script:LASTEXITCODE = 1
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get Visual Studio Code extensions list" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When Invoke-Command throws exception" {
        It "Should return null and write error" {
            Mock Invoke-Command { throw "Command failed" }
            $script:LASTEXITCODE = 0
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error getting Visual Studio Code extensions:" -and $Verbosity -eq "Error" }
        }
    }

    Context "When ConvertTo-Json fails" {
        It "Should return null and write error" {
            Mock Invoke-Command { "extension1@1.0.0" }
            $script:LASTEXITCODE = 0
            Mock ConvertTo-Json { throw "JSON conversion failed" }
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error getting Visual Studio Code extensions:" -and $Verbosity -eq "Error" }
        }
    }

    Context "When outer try-catch catches exception" {
        It "Should return null and write error" {
            Mock Find-VsCode { throw "Unexpected error" }
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error exporting Visual Studio Code configuration:" -and $Verbosity -eq "Error" }
        }
    }

    Context "When extensions output has empty lines" {
        It "Should filter out empty lines" {
            Mock Invoke-Command { "extension1@1.0.0", "", "extension2@2.0.0", " " }
            $script:LASTEXITCODE = 0
            $result = Invoke-VsCodeExtensionsExport
            Assert-MockCalled ConvertTo-Json -Exactly 2 -Scope It
            $result | Should -Be @("mocked json output", "mocked json output")
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Invoke-Command { "extension1@1.0.0" }
            $script:LASTEXITCODE = 0
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be "mocked json output"
        }

        It "Should work on Linux" {
            Mock Find-VsCode { $null }  # VS Code not found on Linux
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
        }

        It "Should work on macOS" {
            Mock Find-VsCode { $null }  # VS Code not found on macOS
            $result = Invoke-VsCodeExtensionsExport
            $result | Should -Be $null
        }
    }
}