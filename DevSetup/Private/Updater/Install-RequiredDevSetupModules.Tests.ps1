BeforeAll {
    Function Get-PackageProvider {
        Param(
            [string]$Name,
            [string]$ErrorAction = "SilentlyContinue"
        )
    }

    Function Install-PackageProvider {
        Param(
            [string]$Name,
            [switch]$Force,
            [switch]$ForceBootstrap
        )
    }

    Function Install-Module {
        Param(
            [string]$Name,
            [string]$Scope,
            [switch]$Force
        )
    }

    Function Get-Module {
        Param(
            [string]$Name,
            [string]$ErrorAction = "SilentlyContinue"
        )
    }

    . $PSScriptRoot\Install-RequiredDevSetupModules.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1

    Mock Write-StatusMessage { }
}

Describe "Install-RequiredDevSetupModules" {
    Context "When NuGet provider is not installed" {
        It "Should attempt to install NuGet provider and return false if installation fails" {
            Mock Get-PackageProvider -MockWith { return $null }
            Mock Install-PackageProvider { throw "Installation failed" }
            $modules = @("ModuleA", "ModuleB")
            $result = Install-RequiredDevSetupModules -Modules $modules
            $result | Should -Be $false
            Assert-MockCalled -CommandName Install-PackageProvider -Times 1
            Assert-MockCalled Write-StatusMessage -Times 1 -ParameterFilter {
                $Message -match "Failed to install NuGet PackageProvider:" -and 
                $Verbosity -eq "Error" 
            }
        }

        It "Should attempt to install NuGet provider and required modules" {
            Mock Get-PackageProvider -MockWith { return $null }
            Mock Install-PackageProvider
            Mock Get-Module -MockWith { return $null }
            Mock Install-Module
            $modules = @("ModuleA", "ModuleB")
            $result = Install-RequiredDevSetupModules -Modules $modules
            $result | Should -Be $true
            Assert-MockCalled -CommandName Install-PackageProvider -Times 1
            foreach ($module in $modules) {
                Assert-MockCalled -CommandName Install-Module -ParameterFilter { $Name -eq $module } -Times 1
            }
        }
    }

    Context "When NuGet provider is already installed" {
        BeforeEach {
            Mock Get-PackageProvider -MockWith { return @{ Name = "NuGet" } }
            Mock Install-PackageProvider
            Mock Get-Module -MockWith { return $null }
            Mock Install-Module
        }
        It "Should skip installing NuGet provider and install required modules" {
            $modules = @("ModuleA", "ModuleB")
            $result = Install-RequiredDevSetupModules -Modules $modules
            $result | Should -Be $true
            Assert-MockCalled Install-PackageProvider -Times 0
            foreach ($module in $modules) {
                Assert-MockCalled Install-Module -ParameterFilter { $Name -eq $module } -Times 1
            }
        }
    }

    Context "When a required module is already installed" {
        BeforeEach {
            Mock Get-PackageProvider -MockWith { return @{ Name = "NuGet" } }
            Mock Install-PackageProvider
            Mock Get-Module -MockWith { param($Name) if ($Name -eq "ModuleA") { return @{ Name = "ModuleA" } } else { return $null } }
            Mock Install-Module
        }
        It "Should skip installing already installed modules" {
            $modules = @("ModuleA", "ModuleB")
            $result = Install-RequiredDevSetupModules -Modules $modules
            $result | Should -Be $true
            Assert-MockCalled Install-PackageProvider -Times 0
            Assert-MockCalled Install-Module -ParameterFilter { $Name -eq "ModuleA" } -Times 0
            Assert-MockCalled Install-Module -ParameterFilter { $Name -eq "ModuleB" } -Times 1
        }
    }
    Context "When Install-Module fails for a module" {
        BeforeEach {
            Mock Get-PackageProvider -MockWith { return @{ Name = "NuGet" } }
            Mock Install-PackageProvider
            Mock Get-Module -MockWith { return $null }
            Mock Install-Module -MockWith { param($Name) if ($Name -eq "ModuleB") { throw "Installation failed" } }
            Mock Write-StatusMessage { }
        }
        It "Should log an error and continue installing other modules" {
            $modules = @("ModuleA", "ModuleB", "ModuleC")
            $result = Install-RequiredDevSetupModules -Modules $modules
            $result | Should -Be $true
            Assert-MockCalled Install-PackageProvider -Times 0
            Assert-MockCalled Install-Module -ParameterFilter { $Name -eq "ModuleA" } -Times 1
            Assert-MockCalled Install-Module -ParameterFilter { $Name -eq "ModuleB" } -Times 1
            Assert-MockCalled Install-Module -ParameterFilter { $Name -eq "ModuleC" } -Times 1
            Assert-MockCalled Write-StatusMessage -ParameterFilter {
                $Message -match "Failed to install module 'ModuleB':" -and 
                $Verbosity -eq "Error"
            } -Times 1
        }
    }
}