BeforeAll {
    . (Join-Path $PSScriptRoot "Write-NewConfig.ps1")
    . (Join-Path $PSScriptRoot "New-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "Get-HostArchitecture.ps1")
    . (Join-Path $PSScriptRoot "Get-HostOperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "Get-HostOperatingSystemVersion.ps1")
    . (Join-Path $PSScriptRoot "Get-EnvironmentVariable.ps1")
    . (Join-Path $PSScriptRoot "Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "Update-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "Optimize-DevSetupEnvs.ps1")    
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Chocolatey\Invoke-ChocolateyPackageExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Scoop\Invoke-ScoopComponentExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Homebrew\Invoke-HomebrewComponentsExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Powershell\Invoke-PowershellModulesExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\3rdParty\ConvertFrom-3rdPartyInstall.ps1")
    Mock Test-OperatingSystem { $true }  # Default to Windows for tests
}

Describe "Write-NewConfig" {
    Context "When not running as administrator" {
        It "should throw an exception and return false" {
            Mock Test-RunningAsAdmin { $false }
            Mock Write-StatusMessage { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error creating new configuration:" }
        }
    }

    Context "When creating a new configuration file" {
        It "should create base config and export packages" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            Assert-MockCalled Test-RunningAsAdmin -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            $result | Should -Be $true
        }
    }

    Context "When updating an existing configuration file" {
        It "should merge with existing config and increment version" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ configuration = @{ version = "1.0.0"; description = "Existing config"; createdDate = "2022-01-01 12:00:00"; createdBy = "OldUser" }; dependencies = @{ chocolatey = @{ packages = @("git") } }; commands = @("echo hello") } } }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
        }
    }

    Context "When exporting chocolately packages and the export returns false" {
        It "should report and continue" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ configuration = @{ version = "1.0.0"; description = "Existing config"; createdDate = "2022-01-01 12:00:00"; createdBy = "OldUser" }; dependencies = @{ chocolatey = @{ packages = @("git") } }; commands = @("echo hello") } } }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $false }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to convert Chocolatey packages, but continuing..." }
        }
    }
    
    Context "When exporting scoop packages and the export returns false" {
        It "should report and continue" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ configuration = @{ version = "1.0.0"; description = "Existing config"; createdDate = "2022-01-01 12:00:00"; createdBy = "OldUser" }; dependencies = @{ chocolatey = @{ packages = @("git") } }; commands = @("echo hello") } } }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $false }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to convert Scoop packages, but continuing..." }
        }
    } 
    
    Context "When exporting powershell modules and the export returns false" {
        It "should report and continue" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ configuration = @{ version = "1.0.0"; description = "Existing config"; createdDate = "2022-01-01 12:00:00"; createdBy = "OldUser" }; dependencies = @{ chocolatey = @{ packages = @("git") } }; commands = @("echo hello") } } }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $false }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to convert PowerShell modules, but continuing..." }
        }
    }     

    Context "When updating an existing configuration file and version is invalid" {
        It "should keep version" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ configuration = @{ version = "abcd"; description = "Existing config"; createdDate = "2022-01-01 12:00:00"; createdBy = "OldUser" }; dependencies = @{ chocolatey = @{ packages = @("git") } }; commands = @("echo hello") } } }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "- Version" -and $Verbosity -eq "Warning"}
        }
    }
    
    Context "When updating an existing configuration file and version is not present" {
        It "should skip version" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ configuration = @{ description = "Existing config"; createdDate = "2022-01-01 12:00:00"; createdBy = "OldUser" }; dependencies = @{ chocolatey = @{ packages = @("git") } }; commands = @("echo hello") } } }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "- Version" }
        }
    }    

    Context "When reading existing config fails" {
        It "should fall back to new config" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { throw "Read failed" }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }

    Context "When writing YAML fails" {
        It "should return false" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock Update-DevSetupEnvFile { throw "YAML conversion failed" }
            Mock Write-StatusMessage { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to create base configuration file" }
        }
    }

    Context "When DryRun is specified on non-Windows" {
        BeforeEach { 
            $script:callCount = 0
            Mock Test-OperatingSystem { 
                switch ($script:callCount) {
                    0 { $script:callCount++; return $false }  # First call for Windows check
                    1 { $script:callCount++; return $false }
                }
            }
        }  # Default to non-Windows for this context
        It "should pass DryRun to Homebrew export" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Get-HostOperatingSystemVersion { "Ubuntu 20.04" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { Write-Output $false }  # Not Windows
            Mock Invoke-HomebrewComponentsExport {
                Param($Config, $DryRun) 
                return $true 
            }
            Mock Invoke-PowershellModulesExport { return $true }
            Mock Invoke-ChocolateyPackageExport { return $false }
            Mock Invoke-ScoopComponentExport { return $false }
            Mock ConvertFrom-3rdPartyInstall { return $true }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml" -DryRun:$true
            Assert-MockCalled Test-OperatingSystem -Exactly 2 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 0 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 0 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsExport -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
            Assert-MockCalled Invoke-PowershellModulesExport -Exactly 1 -Scope It
            $result | Should -Be $true
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-HostOperatingSystemVersion { "10.0.19042" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $true }  # Windows
            Mock Invoke-ChocolateyPackageExport { $true }
            Mock Invoke-ScoopComponentExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Invoke-ChocolateyPackageExport -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ScoopComponentExport -Exactly 1 -Scope It
        }

        It "should work on Linux" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Get-HostOperatingSystemVersion { "Ubuntu 20.04" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $false }  # Not Windows
            Mock Invoke-HomebrewComponentsExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Invoke-HomebrewComponentsExport -Exactly 1 -Scope It
        }

        It "should work on Linux and when export homebrew returns false it should continue" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "x64" }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Get-HostOperatingSystemVersion { "Ubuntu 20.04" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $false }  # Not Windows
            Mock Invoke-HomebrewComponentsExport { $false }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Invoke-HomebrewComponentsExport -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to convert Homebrew packages, but continuing..." }
        }        

        It "should work on macOS" {
            Mock Test-RunningAsAdmin { $true }
            Mock Get-HostArchitecture { "arm64" }
            Mock Get-HostOperatingSystem { "macOS" }
            Mock Get-HostOperatingSystemVersion { "12.0.1" }
            Mock Get-EnvironmentVariable { "TestUser" }
            Mock Get-Date { [DateTime]::Parse("2023-01-01 12:00:00") }
            Mock Test-Path { $false }
            Mock Update-DevSetupEnvFile { }
            Mock Write-StatusMessage { }
            Mock Test-OperatingSystem { $false }  # Not Windows
            Mock Invoke-HomebrewComponentsExport { $true }
            Mock Invoke-PowershellModulesExport { $true }
            Mock ConvertFrom-3rdPartyInstall { }
            Mock Optimize-DevSetupEnvs { }

            $result = Write-NewConfig -OutFile "test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Invoke-HomebrewComponentsExport -Exactly 1 -Scope It
        }
    }
}