BeforeAll {
    Function Get-GitHubRelease { }
    . (Join-Path $PSScriptRoot "Get-DevSetupVersion.ps1")
    . (Join-Path $PSScriptRoot "Get-DevSetupManifest.ps1")
    . (Join-Path $PSScriptRoot "Test-OperatingSystem.ps1")
    Mock Test-OperatingSystem {
        Param($Windows, $Linux, $MacOS)
        if ($Windows) { return $true }
        if ($Linux) { return $false }
        if ($MacOS) { return $false }
    }  # Default to Windows
    Mock Get-DevSetupManifest { @{ ModuleVersion = "1.0.0"; PrivateData = @{ PSData = @{ ProjectUri = "https://github.com/pwshdevs/devsetup" } } } }
    Mock Get-GitHubRelease { [PSCustomObject]@{ tag_name = "v1.0.1" } }
    Mock Write-Error { }
}

Describe "Get-DevSetupVersion" {

    Context "When Local parameter is specified" {
        It "Should return local version" {
            $result = Get-DevSetupVersion -Local
            $result | Should -BeOfType [Version]
            $result.ToString() | Should -Be "1.0.0"
            Assert-MockCalled Get-DevSetupManifest -Exactly 1 -Scope It
            Assert-MockCalled Get-GitHubRelease -Exactly 0 -Scope It
        }
    }

    Context "When Remote parameter is specified" {
        It "Should return remote version" {
            $result = Get-DevSetupVersion -Remote
            $result | Should -BeOfType [Version]
            $result.ToString() | Should -Be "1.0.1"
            Assert-MockCalled Get-DevSetupManifest -Exactly 1 -Scope It
            Assert-MockCalled Get-GitHubRelease -Exactly 1 -Scope It
        }
    }

    Context "When no parameter is specified" {
        It "Should default to Local" {
            $result = Get-DevSetupVersion
            $result | Should -BeOfType [Version]
            $result.ToString() | Should -Be "1.0.0"
            Assert-MockCalled Get-DevSetupManifest -Exactly 1 -Scope It
            Assert-MockCalled Get-GitHubRelease -Exactly 0 -Scope It
        }
    }

    Context "When both Local and Remote are specified" {
        It "Should write error and return null" {
            $result = Get-DevSetupVersion -Local -Remote
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Local and Remote parameters are mutually exclusive. Please specify only one." }
        }
    }

    Context "When Get-DevSetupManifest fails" {
        It "Should write error and return null" {
            Mock Get-DevSetupManifest { $null }
            $result = Get-DevSetupVersion -Local
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Failed to retrieve DevSetup module manifest." }
        }
    }

    Context "When ModuleVersion is missing in manifest" {
        It "Should write error and return null" {
            Mock Get-DevSetupManifest { @{ PrivateData = @{ PSData = @{ ProjectUri = "https://github.com/pwshdevs/devsetup" } } } }
            $result = Get-DevSetupVersion -Local
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Version information not found in the DevSetup module manifest." }
        }
    }

    Context "When ModuleVersion is invalid" {
        It "Should write error and return null" {
            Mock Get-DevSetupManifest { @{ ModuleVersion = "invalid"; PrivateData = @{ PSData = @{ ProjectUri = "https://github.com/pwshdevs/devsetup" } } } }
            $result = Get-DevSetupVersion -Local
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to parse version 'invalid' as a valid version object" }
        }
    }

    Context "When ProjectUri is missing for Remote" {
        It "Should write error and return null" {
            Mock Get-DevSetupManifest { @{ ModuleVersion = "1.0.0"; PrivateData = @{ PSData = @{ } } } }
            $result = Get-DevSetupVersion -Remote
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "ProjectUri not found in the DevSetup module manifest." }
        }
    }

    Context "When Get-GitHubRelease fails" {
        It "Should write error and return null" {
            Mock Get-GitHubRelease { $null }
            $result = Get-DevSetupVersion -Remote
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Failed to retrieve latest release information from GitHub." }
        }
    }

    Context "When tag_name is missing in release" {
        It "Should write error and return null" {
            Mock Get-GitHubRelease { [PSCustomObject]@{ } }
            $result = Get-DevSetupVersion -Remote
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Failed to retrieve latest release information from GitHub." }
        }
    }

    Context "When tag_name is invalid for Remote" {
        It "Should write error and return null" {
            Mock Get-GitHubRelease { [PSCustomObject]@{ tag_name = "invalid" } }
            $result = Get-DevSetupVersion -Remote
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to retrieve or parse remote version" }
        }
    }

    Context "When tag_name has 'v' prefix" {
        It "Should remove prefix and parse correctly" {
            Mock Get-GitHubRelease { [PSCustomObject]@{ tag_name = "v2.0.0" } }
            $result = Get-DevSetupVersion -Remote
            $result | Should -BeOfType [Version]
            $result.ToString() | Should -Be "2.0.0"
        }
    }

    Context "When tag_name has no 'v' prefix" {
        It "Should parse correctly" {
            Mock Get-GitHubRelease { [PSCustomObject]@{ tag_name = "2.0.0" } }
            $result = Get-DevSetupVersion -Remote
            $result | Should -BeOfType [Version]
            $result.ToString() | Should -Be "2.0.0"
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $result = Get-DevSetupVersion -Local
            $result | Should -BeOfType [Version]
        }

        It "Should work on Linux" {
            $result = Get-DevSetupVersion -Local
            $result | Should -BeOfType [Version]
        }

        It "Should work on macOS" {
            $result = Get-DevSetupVersion -Local
            $result | Should -BeOfType [Version]
        }
    }
}