BeforeAll {
    Function New-Item {
        Param(
            [string]$ItemType, 
            [string]$Path, 
            [switch]$Force
        )
    }

    Function Test-Path { 
        Param(
            [string]$Path
        ) 
    }
    Function Copy-Item {
        Param(
            [string]$Path, 
            [string]$Destination, 
            [switch]$Recurse,
            [switch]$Force
        )
    }
    . $PSScriptRoot\Install-DevSetupModule.ps1
    . $PSScriptRoot\Get-DevSetupModuleInstallPath.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage {
        #Write-Error $Message
    }
    $global:InstallPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "Program Files" ) "WindowsPowerShell" ) "Modules" ) "DevSetup" )
    $global:ModulePath = (Join-Path (Join-Path $TestDrive "Temp" ) "DevSetup" )
}

Describe "Install-DevSetupModule" {
    Context "When ModulePath is invalid" {
        It "Should return false and log an error" {
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $ModulePath }
            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 1
        }
    }
    Context "When installation path cannot be determined" {
        It "Should return false and log an error" {
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $InstallPath }
            Mock Get-DevSetupModuleInstallPath { return $null }
            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 1
        }
    }

    Context "When installation path cannot be determined is null" {
        It "Should return false and log an error" {
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $InstallPath }
            Mock Join-Path { return $null }
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 1
        }
    }    

    Context "When installation is successful" {
        It "Should return true and log success message" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $InstallPath }
            Mock New-Item {}
            Mock Copy-Item {}

            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Debug' } -Exactly 1
        }
    }

    Context "When user declines installation" {
        It "Should return false and log a warning message" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $InstallPath }
            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" } -WhatIf:$true -Confirm:$false
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Warning' } -Exactly 1
        }
    }

    Context "When installation fails due to an exception" {
        It "Should return false and log an error message" {
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $InstallPath }
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            Mock New-Item { throw "Simulated failure" }
            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 2
        }
    }
    Context "When installation path already exists" {
        It "Should skip directory creation and proceed with copying" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            Mock Test-Path { return $true }
            Mock Copy-Item { return $true }
            Mock New-Item { }

            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $true
            Assert-MockCalled New-Item -Exactly 0
            Assert-MockCalled Copy-Item -Exactly 1
        }
    }
    Context "When Copy-Item fails due to an exception" {     
        It "Should return false and log an error message" {
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $InstallPath }            
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            Mock New-Item { return $true }
            Mock Copy-Item { throw "Simulated copy failure" }

            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 2
        }
    }
    Context "When Manifest does not contain ModuleVersion" {
        It "Should return false and log an error message" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }

            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{}
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 1
        }
    }
    Context "When ModulePath is invalid" {
        BeforeEach {
            Mock Write-StatusMessage {
                Write-Error $Message
            }
        }           
        It "Should throw an error when ModulePath is null" {
            { Install-DevSetupModule -ModulePath $null -Manifest @{ ModuleVersion = "1.0.0" } } | Should -Throw
        }
    }
    Context "When Manifest is invalid" {
        BeforeEach {
            Mock Write-StatusMessage {
                Write-Error $Message
            }
        }          
        It "Should throw error when Manifest is null" {
            { Install-DevSetupModule -ModulePath $ModulePath -Manifest $null } | Should -Throw
        }
    }
    Context "When Get-DevSetupModuleInstallPath throws an exception" {
        It "Should return false and log an error message" {
            Mock Get-DevSetupModuleInstallPath { throw "Simulated path retrieval failure" }
            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 1
        }
    }
    Context "When Manifest version is a complex object" {
        It "Should handle non-string version gracefully and return false" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }

            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = @{ Major = 1; Minor = 0; Patch = 0 } }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 1
        }
    }
    Context "When Manifest version is an empty string" {
        It "Should return false and log an error message" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }

            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "" }
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Verbosity -eq 'Error' } -Exactly 1
        }
    }
    Context "When using ShouldProcess functionality" {
        It "Should execute normally when ShouldProcess returns true" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $InstallPath }                 
            Mock New-Item {}
            Mock Copy-Item {}

            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" } -WhatIf:$false
            $result | Should -Be $true
            Should -Invoke New-Item -Times 1 -Exactly
            Should -Invoke Copy-Item -Times 1 -Exactly
        }

        It "Should skip execution when ShouldProcess returns false" {
            Mock Get-DevSetupModuleInstallPath { return $InstallPath }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq $ModulePath }
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $InstallPath } 
            Mock New-Item { return $true}
            Mock Copy-Item { return $true }
            $result = Install-DevSetupModule -ModulePath $ModulePath -Manifest @{ ModuleVersion = "1.0.0" } -WhatIf:$true -Confirm:$false
            $result | Should -Be $true
            Should -Invoke New-Item -Times 0 -Exactly
            Should -Invoke Copy-Item -Times 0 -Exactly
        }
    }
}