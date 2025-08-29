BeforeAll {
    . $PSScriptRoot\Show-DevSetupEnvList.ps1
    . $PSScriptRoot\Show-DevSetupEnvList.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Optimize-DevSetupEnvs.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupPath.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1    
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Format-PrettyTable.ps1    
    Mock Get-DevSetupPath { "C:\DevSetup" }
    Mock Optimize-DevSetupEnvs { }
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock Test-OperatingSystem { param($Windows, $Linux, $MacOS) $false }
    Mock Test-Path { $true }
    Mock Get-Content { '[{"name":"EnvWin","version":"1.0","platform":"windows","file":"envwin.yaml"},{"name":"EnvLinux","version":"2.0","platform":"linux","file":"envlinux.yaml"},{"name":"EnvMac","version":"3.0","platform":"macos","file":"envmac.yaml"},{"name":"EnvCross","version":"4.0","platform":"cross-platform","file":"envcross.yaml"},{"name":"EnvUnspec","version":"5.0","file":"envunspec.yaml"}]' }
    Mock ConvertFrom-Json { 
        @(
            @{ name = "EnvWin"; version = "1.0"; platform = "windows"; file = "envwin.yaml" },
            @{ name = "EnvLinux"; version = "2.0"; platform = "linux"; file = "envlinux.yaml" },
            @{ name = "EnvMac"; version = "3.0"; platform = "macos"; file = "envmac.yaml" },
            @{ name = "EnvCross"; version = "4.0"; platform = "cross-platform"; file = "envcross.yaml" },
            @{ name = "EnvUnspec"; version = "5.0"; file = "envunspec.yaml" }
        )
    }
}

Describe "Show-DevSetupEnvList" {
    Context "When environments.json does not exist" {
        It "Should run optimization to create it" {
            Mock Test-Path { $false }
            Show-DevSetupEnvList -Platform "all"
            Assert-MockCalled Optimize-DevSetupEnvs -Exactly 1 -Scope It
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "No environments index found" }
        }
    }

    Context "When environments.json is corrupt" {
        It "Should run optimization to recreate it" {
            Mock Test-Path { $true }
            Mock Get-Content { throw "corrupt file" }
            Show-DevSetupEnvList -Platform "all"
            Assert-MockCalled Optimize-DevSetupEnvs -Exactly 1 -Scope It
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Failed to read environments.json" }
        }
    }

    Context "When filtering for current platform (windows)" {
        It "Should detect windows platform and filter environments" {
            Mock Format-PrettyTable { }
            Mock Test-OperatingSystem { param($Windows, $Linux, $MacOS) if ($Windows) { $true } else { $false } }
            Show-DevSetupEnvList -Platform "current"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Filtering for current platform: windows" }
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When filtering for current platform (linux)" {
        It "Should detect linux platform and filter environments" {
            Mock Format-PrettyTable { }
            Mock Test-OperatingSystem { param($Windows, $Linux, $MacOS) if ($Linux) { $true } else { $false } }
            Show-DevSetupEnvList -Platform "current"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Filtering for current platform: linux" }
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When filtering for current platform (macos)" {
        It "Should detect macos platform and filter environments" {
            Mock Format-PrettyTable { }
            Mock Test-OperatingSystem { param($Windows, $Linux, $MacOS) if ($MacOS) { $true } else { $false } }
            Show-DevSetupEnvList -Platform "current"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Filtering for current platform: macos" }
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When filtering for all platforms" {
        It "Should show all environments without filtering" {
            Mock Format-PrettyTable { }
            Show-DevSetupEnvList -Platform "all"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Showing all environments regardless of platform" }
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When filtering for specific platform (windows)" {
        It "Should filter and display only windows-compatible environments" {
            Mock Format-PrettyTable { }
            Show-DevSetupEnvList -Platform "windows"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Filtering for platform: windows" }
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When no environments are found for a platform" {
        It "Should display guidance message" {
            Mock Format-PrettyTable { }
            Mock ConvertFrom-Json { @() }
            Show-DevSetupEnvList -Platform "windows"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "No development environments found for platform: windows" }
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Use -Platform 'all' to see all available environments" }
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
        }
    }

    Context "When no environments exist at all" {
        It "Should display no environments found message" {
            Mock Format-PrettyTable { }
            Mock ConvertFrom-Json { @() }
            Show-DevSetupEnvList -Platform "all"
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "No development environments found." }
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
        }
    }

    Context "When environments are found" {
        It "Should display the environments table and count" {
            Mock Format-PrettyTable { }
            Mock Write-Host { }
            Show-DevSetupEnvList -Platform "all"
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }
}