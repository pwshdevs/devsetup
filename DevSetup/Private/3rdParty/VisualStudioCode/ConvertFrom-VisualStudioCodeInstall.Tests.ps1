BeforeAll {
    Function ConvertTo-Yaml { }
    . (Join-Path $PSScriptRoot "ConvertFrom-VisualStudioCodeInstall.ps1")
    . (Join-Path $PSScriptRoot "Find-VsCode.ps1")
    . (Join-Path $PSScriptRoot "Add-VsCodeToPackageManager.ps1")
    . (Join-Path $PSScriptRoot "Invoke-VsCodeExtensionsExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Test-OperatingSystem {
        Param($Windows, $Linux, $MacOS)
        if ($Windows) { return $true }
        if ($Linux) { return $false }
        if ($MacOS) { return $false }
    }  # Default to Windows
    Mock Read-ConfigurationFile { @{ devsetup = @{ commands = @() } } }
    Mock Find-VsCode { "$TestDrive\Code\bin\code.cmd" }
    Mock Add-VsCodeToPackageManager { $true }
    Mock Invoke-VsCodeExtensionsExport { "mocked extensions json" }
    Mock Write-StatusMessage { }
    Mock ConvertTo-Yaml { "mocked yaml output" }
    Mock Out-File { }
}

Describe "ConvertFrom-VisualStudioCodeInstall" {

    Context "When VS Code is found and all operations succeed" {
        It "Should update config and return true" {
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled Add-VsCodeToPackageManager -Exactly 1 -Scope It
            Assert-MockCalled Invoke-VsCodeExtensionsExport -Exactly 1 -Scope It
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Visual Studio Code installation conversion completed!" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When VS Code is not found" {
        It "Should skip and return true" {
            Mock Find-VsCode { $null }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled Add-VsCodeToPackageManager -Exactly 0 -Scope It
            Assert-MockCalled Invoke-VsCodeExtensionsExport -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "- Visual Studio Code not detected, skipping extension export" -and $ForegroundColor -eq "Yellow" }
        }
    }

    Context "When Add-VsCodeToPackageManager fails" {
        It "Should return false" {
            Mock Add-VsCodeToPackageManager { $false }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
            Assert-MockCalled Invoke-VsCodeExtensionsExport -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red" }
        }
    }

    Context "When Invoke-VsCodeExtensionsExport fails" {
        It "Should return true" {
            Mock Invoke-VsCodeExtensionsExport { $null }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            Assert-MockCalled ConvertTo-Yaml -Exactly 0 -Scope It
            Assert-MockCalled Out-File -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red" }
            $result | Should -Be $true          
        }
    }

    Context "When saving config fails" {
        It "Should return false and write error" {
            Mock Out-File { throw "Save failed" }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to save updated devsetup environment:" -and $Verbosity -eq "Error" }
        }
    }

    Context "When WhatIf is true" {
        It "Should not save config" {
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup" -WhatIf:$true
            $result | Should -Be $true
            Assert-MockCalled Out-File -Exactly 0 -Scope It
        }
    }

    Context "When existing command is present" {
        It "Should update the existing command" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ commands = @(@{ packageName = "invoke.vs.code.extensions.import"; command = "old"; params = @{} }) } } }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "- Updating Visual Studio Code import command..." -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When no existing command" {
        It "Should add new command" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ commands = @() } } }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "- Adding Visual Studio Code import command..." -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When YAML structure is missing" {
        It "Should create structure" {
            Mock Read-ConfigurationFile { @{ } }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
        }
    }

    Context "When exception occurs in try block" {
        It "Should return false and write error" {
            Mock Read-ConfigurationFile { throw "Read failed" }
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error detecting Visual Studio Code installation:" -and $Verbosity -eq "Error" }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $true }
                if ($Linux) { return $false }
                if ($MacOS) { return $false }
            }            
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
        }

        It "Should work on Linux" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $true }
                if ($MacOS) { return $false }
            }            
            Mock Find-VsCode { $null }  # VS Code not found on Linux
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
        }

        It "Should work on macOS" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $false }
                if ($MacOS) { return $true }
            }            
            Mock Find-VsCode { $null }  # VS Code not found on macOS
            $result = ConvertFrom-VisualStudioCodeInstall -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
        }
    }
}