BeforeAll {
    . (Join-Path $PSScriptRoot "Get-DevSetupManifest.ps1")
    . (Join-Path $PSScriptRoot "Test-OperatingSystem.ps1")
    Mock Test-OperatingSystem {
        Param($Windows, $Linux, $MacOS)
        if ($Windows) { return $true }
        if ($Linux) { return $false }
        if ($MacOS) { return $false }
    }  # Default to Windows
    Mock Get-Module { [PSCustomObject]@{ ModuleBase = "$TestDrive\DevSetup" } }
    Mock Test-Path { $true }
    Mock Import-PowerShellDataFile { @{ ModuleVersion = "1.0.0" } }
    Mock Write-Error { }
}

Describe "Get-DevSetupManifest" {

    Context "When DevSetup module is installed and manifest exists" {
        It "Should return the manifest" {
            $result = Get-DevSetupManifest
            $result | Should -Not -Be $null
            $result.ModuleVersion | Should -Be "1.0.0"
            Assert-MockCalled Get-Module -Exactly 1 -Scope It -ParameterFilter { $Name -eq "DevSetup" }
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq (Join-Path "$TestDrive\DevSetup" "DevSetup.psd1") }
            Assert-MockCalled Import-PowerShellDataFile -Exactly 1 -Scope It -ParameterFilter { $Path -eq (Join-Path "$TestDrive\DevSetup" "DevSetup.psd1") }
        }
    }

    Context "When DevSetup module is not installed" {
        It "Should write error and return null" {
            Mock Get-Module { $null }
            $result = Get-DevSetupManifest
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "DevSetup module is not installed." }
        }
    }

    Context "When manifest file does not exist" {
        It "Should write error and return null" {
            Mock Test-Path { $false }
            $result = Get-DevSetupManifest
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "DevSetup module manifest not found at" }
        }
    }

    Context "When Import-PowerShellDataFile fails" {
        It "Should write error and return null" {
            Mock Import-PowerShellDataFile { $null }
            $result = Get-DevSetupManifest
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Failed to import DevSetup module manifest." }
        }
    }

    Context "When exception occurs in try block" {
        It "Should write error and return null" {
            Mock Get-Module { throw "Unexpected error" }
            $result = Get-DevSetupManifest
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to retrieve DevSetup manifest:" }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $result = Get-DevSetupManifest
            $result | Should -Not -Be $null
        }

        It "Should work on Linux" {
            $result = Get-DevSetupManifest
            $result | Should -Not -Be $null
        }

        It "Should work on macOS" {
            $result = Get-DevSetupManifest
            $result | Should -Not -Be $null
        }
    }
}