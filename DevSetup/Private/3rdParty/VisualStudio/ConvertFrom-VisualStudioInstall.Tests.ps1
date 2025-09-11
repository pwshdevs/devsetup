BeforeAll {
    . (Join-Path $PSScriptRoot "ConvertFrom-VisualStudioInstall.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Update-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "Add-VsToPackageManager.ps1")
    . (Join-Path $PSScriptRoot "Invoke-VsConfigExport.ps1")
    Mock Write-StatusMessage { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Get-VSSetupInstance { return @(@{ DisplayName = "Visual Studio Community 2022"; InstallationPath = "$TestDrive\VS2022" }) }
    Mock Add-VsToPackageManager { return "visualstudio2022community" }
    Mock Read-DevSetupEnvFile { return @{ devsetup = @{ commands = @() } } }
    Mock Invoke-VsConfigExport { return "mocked config content" }
    Mock Update-DevSetupEnvFile { }
    Mock Test-RunningAsAdmin { return $true }
}

Describe "ConvertFrom-VisualStudioInstall" {

    Context "When not running as admin" {
        It "Should throw error and return false" {
            Mock Test-RunningAsAdmin { return $false }
            $result = ConvertFrom-VisualStudioInstall -Config "$TestDrive\config.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "requires administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When no VS instances found" {
        It "Should write warning and return true" {
            Mock Get-VSSetupInstance { return @() }
            $result = ConvertFrom-VisualStudioInstall -Config "$TestDrive\config.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "No Visual Studio instances found." -and $Verbosity -eq "Warning" }
            Assert-MockCalled Add-VsToPackageManager -Exactly 0 -Scope It
        }
    }

    Context "When single VS instance and new command" {
        It "Should add package and command, return true" {
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $true
            Assert-MockCalled Get-VSSetupInstance -Exactly 1 -Scope It
            Assert-MockCalled Add-VsToPackageManager -Exactly 1 -Scope It
            Assert-MockCalled Invoke-VsConfigExport -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Adding new VS configuration command" -and $ForegroundColor -eq "Gray" -and $Indent -eq 4 }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Visual Studio installation conversion completed!" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When existing command found" {
        It "Should update existing command" {
            Mock Read-DevSetupEnvFile { 
                return @{ 
                    devsetup = @{ 
                        commands = @(@{ 
                            packageName = "invoke.vs.config.import.visualstudio2022community"
                            command = "old command"
                            params = @{}
                        }) 
                    } 
                } 
            }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Updating existing VS configuration command" -and $ForegroundColor -eq "Gray" -and $Indent -eq 4 }
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }

    Context "When old command package name exists" {
        It "Should update old command" {
            Mock Read-DevSetupEnvFile { 
                return @{ 
                    devsetup = @{ 
                        commands = @(@{ 
                            packageName = "visualstudio2022community.importConfig"
                            command = "old command"
                            params = @{}
                        }) 
                    } 
                } 
            }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Updating existing VS configuration command" -and $ForegroundColor -eq "Gray" -and $Indent -eq 4 }
        }
    }

    Context "When multiple VS instances" {
        It "Should process each instance" {
            Mock Get-VSSetupInstance { 
                return @(
                    @{ DisplayName = "Visual Studio Community 2022"; InstallationPath = "$TestDrive\VS2022" },
                    @{ DisplayName = "Visual Studio Professional 2019"; InstallationPath = "$TestDrive\VS2019" }
                )
            }
            Mock Add-VsToPackageManager { 
                param($Instance)
                if ($Instance.DisplayName -match "2022") { return "visualstudio2022community" }
                else { return "visualstudio2019professional" }
            }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $true
            Assert-MockCalled Add-VsToPackageManager -Exactly 2 -Scope It
            Assert-MockCalled Invoke-VsConfigExport -Exactly 2 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 2 -Scope It
        }
    }

    Context "When Update-DevSetupEnvFile throws exception" {
        It "Should write error and return false" {
            Mock Update-DevSetupEnvFile { throw "Update failed" }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to save configuration" -and $Verbosity -eq "Error" }
        }
    }

    Context "When DryRun is specified" {
        It "Should pass DryRun to functions" {
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile -DryRun
            $result | Should -Be $true
            Assert-MockCalled Add-VsToPackageManager -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "When Read-DevSetupEnvFile returns empty data" {
        It "Should create commands structure" {
            Mock Read-DevSetupEnvFile { return @{} }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }

    Context "When Invoke-VsConfigExport returns null" {
        It "Should still add command with null config" {
            Mock Invoke-VsConfigExport { return $null }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }

    Context "When config is empty" {
        It "Should throw due to parameter validation" {
            { ConvertFrom-VisualStudioInstall -Config "" } | Should -Throw
        }
    }

    Context "When Test-RunningAsAdmin throws exception" {
        It "Should catch and return false" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error in Visual Studio installation conversion" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Get-VSSetupInstance throws exception" {
        It "Should catch and return false" {
            Mock Get-VSSetupInstance { throw "VS detection failed" }
            $configFile = "$TestDrive\config.yaml"
            $result = ConvertFrom-VisualStudioInstall -Config $configFile
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error in Visual Studio installation conversion" -and $Verbosity -eq "Error" }
        }
    }
}
