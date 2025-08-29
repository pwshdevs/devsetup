BeforeAll {
    . $PSScriptRoot\Install-Nuget.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1   
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1     
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1    
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Write-StatusMessage { }
}

Describe "Install-Nuget" {

    Context "When not running on Windows" {
        It "Should skip installation and return true" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $false } else { return $true } }
            $result = Install-Nuget
            $result | Should -Be $true
        }
    }

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            Mock Test-RunningAsAdmin { return $false }
            $result = Install-Nuget
            $result | Should -Be $false
        }
    }

    Context "When NuGet PackageProvider is already installed" {
        It "Should return true and not install again" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            Mock Test-RunningAsAdmin { return $true }
            Mock Get-PackageProvider { 
                [PSCustomObject]@{ Name = "NuGet"; Version = "2.8.5.201" }
            }
            $result = Install-Nuget
            $result | Should -Be $true
        }
    }

    Context "When NuGet PackageProvider is not installed and installation succeeds" {
        It "Should install and return true" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            Mock Test-RunningAsAdmin { return $true }
            $script:installCalled = $false
            $script:providerCallCount = 0
            Mock Get-PackageProvider -MockWith {
                param($Name)
                $script:providerCallCount++
                if ($script:providerCallCount -eq 1) { return $null }
                else { return [PSCustomObject]@{ Name = "NuGet"; Version = "2.8.5.201" } }
            }
            Mock Install-PackageProvider -MockWith {
                param($Name, $MinimumVersion, $Force, $Scope)
                $script:installCalled = $true
            }
            $result = Install-Nuget
            $result | Should -Be $true
            $script:installCalled | Should -Be $true
        }
    }

    Context "When NuGet PackageProvider installation fails" {
        It "Should return false and write error" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            Mock Test-RunningAsAdmin { return $true }
            $script:providerCallCount = 0
            Mock Get-PackageProvider -MockWith {
                param($Name)
                $script:providerCallCount++
                return $null
            }
            Mock Install-PackageProvider { }
            $result = Install-Nuget
            $result | Should -Be $false
        }
    }

    Context "When NuGet CLI is available and version is detected" {
        It "Should check CLI version and return true" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            Mock Test-RunningAsAdmin { return $true }
            Mock Get-PackageProvider { [PSCustomObject]@{ Name = "NuGet"; Version = "2.8.5.201" } }
            Mock Get-Command { [PSCustomObject]@{ Name = "nuget" } }
            Mock Invoke-Expression { "NuGet Version: 6.0.0" }
            Mock Select-String { [PSCustomObject]@{ Line = "NuGet Version: 6.0.0" } }
            Mock ForEach-Object { "6.0.0" }
            $result = Install-Nuget
            $result | Should -Be $true
        }
    }

    Context "When NuGet CLI is available but version detection fails" {
        It "Should still return true" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            Mock Test-RunningAsAdmin { return $true }
            Mock Get-PackageProvider { [PSCustomObject]@{ Name = "NuGet"; Version = "2.8.5.201" } }
            Mock Get-Command { [PSCustomObject]@{ Name = "nuget" } }
            Mock Invoke-Expression { throw "CLI error" }
            $result = Install-Nuget
            $result | Should -Be $true
        }
    }

    Context "When an unexpected error occurs" {
        It "Should return false and write error" {
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            Mock Test-RunningAsAdmin { throw "Unexpected error" }
            $result = Install-Nuget
            $result | Should -Be $false
        }
    }
}