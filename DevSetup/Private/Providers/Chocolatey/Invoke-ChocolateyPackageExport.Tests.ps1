BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-ChocolateyPackageExport.ps1")
    . (Join-Path $PSScriptRoot "Get-ChocolateyPackageDependencyMap.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Update-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Write-StatusMessage { }
    Mock Test-RunningAsAdmin { $true }
    Mock Get-ChocolateyPackageDependencyMap { @('chocolatey-core.extension', 'magic') }
    Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
    Mock Update-DevSetupEnvFile { }
    $script:LASTEXITCODE = 0
    Mock Invoke-Command {
        param($ScriptBlock)
        $script:LASTEXITCODE = 0
        # Simulate successful choco list output
        return @("git|2.40.0", "nodejs|18.16.0", "vscode|1.80.0")
    }
}

Describe "Invoke-ChocolateyPackageExport" {

    Context "When not running as administrator" {
        It "Should return false and write error" {
            Mock Test-RunningAsAdmin { $false }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "requires administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Test-RunningAsAdmin throws exception" {
        It "Should return false and write error" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When choco list command fails" {
        It "Should return false and write error" {
            Mock Invoke-Command { throw "Command failed" }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to retrieve Chocolatey package list" -and $Verbosity -eq "Error" }
        }
    }

    Context "When choco list command fails with non-zero exit code" {
        BeforeEach {
            $script:LASTEXITCODE = 0
            Mock Invoke-Command { $script:LASTEXITCODE = 1; return @() }
        }
        It "Should return false and write error" {
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to retrieve Chocolatey package list" -and $Verbosity -eq "Error" }
        }
    }    

    Context "When no Chocolatey packages are found" {
        BeforeEach {
            Mock Invoke-Command { $script:LASTEXITCODE = 0; return @() }
        }
        It "Should return true and write warning" {
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "No Chocolatey packages found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When Get-ChocolateyPackageDependencyMap fails" {
        It "Should continue with empty ignore list and write warning" {
            Mock Get-ChocolateyPackageDependencyMap { throw "Dependency map failed" }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to retrieve Chocolatey package dependency map" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When choco output contains empty lines" {
        It "Should skip empty lines and process valid packages" {
            Mock Invoke-Command { return @("", "git|2.40.0", "", "nodejs|18.16.0") }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Found 2 Chocolatey packages" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When packages start with chocolatey" {
        It "Should skip chocolatey packages" {
            Mock Invoke-Command { return @("chocolatey|1.0.0", "chocolatey-core|1.0.0", "git|2.40.0") }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Message -match "Skipping chocolatey package" -and $Verbosity -eq "Verbose" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Found 1 Chocolatey packages" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When packages are in ignore list" {
        It "Should skip ignored packages" {
            Mock Invoke-Command { return @("magic|1.0.0", "git|2.40.0") }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Skipping ignored package" -and $Verbosity -eq "Verbose" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Found 1 Chocolatey packages" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When Read-DevSetupEnvFile fails" {
        It "Should return false and write error" {
            Mock Read-DevSetupEnvFile { throw "Read failed" }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to read YAML configuration" -and $Verbosity -eq "Error" }
        }
    }

    Context "When YAML structure is missing sections" {
        It "Should create missing sections and add packages" {
            Mock Read-DevSetupEnvFile { 
                @{ 
                    devsetup = @{ 
                        configuration = @{} 
                        dependencies = @{} 
                        commands = @() 
                    } 
                } 
            }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It -ParameterFilter { $Message -match "Found package:" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When adding new packages" {
        It "Should add packages and write success messages" {
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It -ParameterFilter { $Message -match "Adding package:" -and $ForegroundColor -eq "Gray" }
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It -ParameterFilter { $Message -eq "[OK]" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When package exists as hashtable and version matches" {
        It "Should skip package with no change message" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git"; version = "2.40.0" }) } } } } }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Skipping package \(No Change\)" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When package exists as hashtable and version changes" {
        It "Should update package version" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git"; version = "2.39.0" }) } } } } }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Updating package: git" -and $ForegroundColor -eq "Cyan" }
        }
    }

    Context "When package exists as hashtable without version" {
        It "Should add version to existing package" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git" }) } } } } }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Updating package: git" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When Update-DevSetupEnvFile fails" {
        It "Should return false and write error" {
            Mock Update-DevSetupEnvFile { throw "Update failed" }
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to save configuration" -and $Verbosity -eq "Error" }
        }
    }

    Context "When DryRun is specified" {
        It "Should call Update-DevSetupEnvFile with WhatIf" {
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml" -DryRun
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "When successful export" {
        It "Should return true and write success messages" {
            $result = Invoke-ChocolateyPackageExport -Config "$TestDrive\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Saving configuration to:" -and $Verbosity -eq "Debug" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Configuration saved successfully!" -and $Verbosity -eq "Debug" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Chocolatey packages conversion completed!" -and $ForegroundColor -eq "Green" }
        }
    }
}