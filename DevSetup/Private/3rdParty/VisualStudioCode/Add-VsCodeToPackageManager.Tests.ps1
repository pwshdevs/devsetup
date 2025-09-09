BeforeAll {
    Function ConvertTo-Yaml { }
    . (Join-Path $PSScriptRoot "Add-VsCodeToPackageManager.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Test-OperatingSystem {
        Param($Windows, $Linux, $MacOS)
        if ($Windows) { return $true }
        if ($Linux) { return $false }
        if ($MacOS) { return $false }
    }  # Default to Windows
    Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }  # Default YAML
    Mock Write-StatusMessage { }
    Mock ConvertTo-Yaml { "mocked yaml output" }
    Mock Out-File { }
}

Describe "Add-VsCodeToPackageManager" {

    Context "When on Windows and vscode not in packages" {
        It "Should add vscode and save config" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It -ParameterFilter { $FilePath -eq "$TestDrive\config.devsetup" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "- Configuration updated successfully" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When on Windows and vscode already in packages as string" {
        It "Should return true without adding" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("vscode") } } } } }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled ConvertTo-Yaml -Exactly 0 -Scope It
            Assert-MockCalled Out-File -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "VS Code is already listed as a chocolatey package." -and $Verbosity -eq "Debug" }
        }
    }

    Context "When on Windows and vscode already in packages as hashtable" {
        It "Should return true without adding" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "vscode"; version = "1.0" }) } } } } }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled ConvertTo-Yaml -Exactly 0 -Scope It
            Assert-MockCalled Out-File -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "VS Code is already listed as a chocolatey package." -and $Verbosity -eq "Debug" }
        }
    }

    Context "When on Windows and YAML structure is missing" {
        It "Should create structure and add vscode" {
            Mock Read-ConfigurationFile { @{ } }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Out-File -Exactly 1 -Scope It
        }
    }

    Context "When on Windows and saving fails" {
        It "Should return false and write error" {
            Mock Out-File { throw "Save failed" }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to save updated configuration:" -and $Verbosity -eq "Error" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Save failed" -and $Verbosity -eq "Error" }
        }
    }

    Context "When on Windows and WhatIf is true" {
        It "Should not save config" {
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup" -WhatIf:$true
            $result | Should -Be $true
            Assert-MockCalled Out-File -Exactly 0 -Scope It
        }
    }

    Context "When on Linux" {
        It "Should return false and write message" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $true }
                if ($MacOS) { return $false }
            }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Find-VsCode is only supported on Windows at this time" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When on macOS" {
        It "Should return false and write message" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $false }
                if ($MacOS) { return $true }
            }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Find-VsCode is only supported on Windows at this time" -and $Verbosity -eq "Debug" }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $true
        }

        It "Should work on Linux" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $true }
                if ($MacOS) { return $false }
            }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
        }

        It "Should work on macOS" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $false }
                if ($MacOS) { return $true }
            }
            $result = Add-VsCodeToPackageManager -Config "$TestDrive\config.devsetup"
            $result | Should -Be $false
        }
    }
}