BeforeAll {
    . $PSScriptRoot\Install-CoreDependencies.ps1
    . $PSScriptRoot\Install-Nuget.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-DevSetupManifest.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Providers\Powershell\Install-PowerShellModule.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Providers\Chocolatey\Install-Chocolatey.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Providers\Chocolatey\Install-ChocolateyPackage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Providers\Scoop\Install-Scoop.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Providers\Homebrew\Install-Homebrew.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Install-Homebrew { return $true }
}

Describe "Install-CoreDependencies" {

    Context "When NuGet installation fails" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $false }
            Mock Test-OperatingSystem { param($os) return $true }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When manifest is missing or has no required modules" {
        It "Should return true and write warning" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return $null }
            Mock Test-OperatingSystem { param($os) return $true }
            $result = Install-CoreDependencies
            $result | Should -Be $true

            Mock Get-DevSetupManifest { return @{ RequiredModules = $null } }
            $result = Install-CoreDependencies
            $result | Should -Be $true
        }
    }

    Context "When required module installation fails" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git", "PSReadLine") } }
            Mock Test-OperatingSystem { param($os) return $false }
            $script:callCount = 0
            Mock Install-PowerShellModule -MockWith {
                param($ModuleName, $Force, $AllowClobber, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return $true }
                else { return $false }
            }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When required modules include empty names" {
        It "Should skip empty module names and return true" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git", $null, "PSReadLine") } }
            Mock Install-PowerShellModule { return $true }
            Mock Test-OperatingSystem { param($os) return $false }
            $result = Install-CoreDependencies
            $result | Should -Be $true
        }
    }

    Context "When all core dependencies install successfully on Windows" {
        It "Should install everything and return true" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git", "PSReadLine") } }
            Mock Install-PowerShellModule { return $true }
            Mock Install-Chocolatey { return $true }
            Mock Install-ChocolateyPackage { return $true }
            Mock Install-Scoop { return $true }
            Mock Test-OperatingSystem { param($os) if ($os -eq 'Windows') { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $true
        }
    }

    Context "When Chocolatey installation fails on Windows" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowerShellModule { return $true }
            Mock Install-Chocolatey { return $false }
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When Git installation fails on Windows" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowerShellModule { return $true }
            Mock Install-Chocolatey { return $true }
            Mock Install-ChocolateyPackage { return $false }
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When Scoop installation fails on Windows" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowerShellModule { return $true }
            Mock Install-Chocolatey { return $true }
            Mock Install-ChocolateyPackage { return $true }
            Mock Install-Scoop { return $false }
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When all core dependencies install successfully on non-Windows" {
        It "Should skip Windows-only installs and return true" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowerShellModule { return $true }
            Mock Test-OperatingSystem { param($os) return $false }
            $result = Install-CoreDependencies
            $result | Should -Be $true
        }
    }
}