BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-ChocolateyPackageExport.ps1")
    . (Join-Path $PSScriptRoot "Test-ChocolateyInstalled.ps1")
    . (Join-Path $PSScriptRoot "Find-Chocolatey.ps1")
    . (Join-Path $PSScriptRoot "Get-ChocolateyPackageDependencyMap.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Update-DevSetupEnvFile.ps1")
    
    Mock Write-StatusMessage { }
}

Describe "Invoke-ChocolateyPackageExport" {

    Context "When not running as administrator" {
        It "Should return false and write error message" {
            Mock Test-RunningAsAdmin { return $false }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "requires administrator privileges" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-RunningAsAdmin throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Chocolatey is not installed" {
        It "Should return false and write warning message" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $false }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey is not installed. Cannot export packages." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When Test-ChocolateyInstalled throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { throw "Installation check failed" }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking if Chocolatey is installed" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Find-Chocolatey throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { throw "Cannot locate chocolatey" }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error locating Chocolatey command" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Find-Chocolatey returns null or empty" {
        It "Should return false when Find-Chocolatey returns null" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $null }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot export packages." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return false when Find-Chocolatey returns empty string" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "" }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot export packages." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return false when Find-Chocolatey returns whitespace" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "   " }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot export packages." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When chocolatey command execution fails" {
        It "Should handle Invoke-Command exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { throw "Command execution failed" }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to retrieve Chocolatey package list" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
        
        It "Should handle non-zero exit code and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 1
                return "error output"
            }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to retrieve Chocolatey package list" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When chocolatey command returns no packages" {
        It "Should return true and write warning when command returns null" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $null 
            }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "No Chocolatey packages found or Chocolatey is not installed." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return true and write warning when command returns empty string" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return ""
            }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "No Chocolatey packages found or Chocolatey is not installed." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return true and write warning when command returns whitespace" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "   "
            }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "No Chocolatey packages found or Chocolatey is not installed." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When Get-ChocolateyPackageDependencyMap throws an exception" {
        It "Should handle exception and continue with empty ignore list" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "git|2.42.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { throw "Dependency map failed" }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to retrieve Chocolatey package dependency map" -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When processing packages with filtering" {
        It "Should skip packages starting with chocolatey" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("chocolatey|0.12.1", "chocolatey-core|0.12.1", "git|2.42.0")
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Message -match "Skipping chocolatey package:" -and $Verbosity -eq "Verbose"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found 1 Chocolatey packages" -and $Verbosity -eq "Debug"
            }
        }
        
        It "Should skip packages in ignore list from dependency map" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0", "nodejs|20.10.0", "ignored-package|1.0.0")
            }
            Mock Get-ChocolateyPackageDependencyMap { return @("ignored-package") }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Skipping ignored package: ignored-package" -and $Verbosity -eq "Verbose"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found 2 Chocolatey packages" -and $Verbosity -eq "Debug"
            }
        }
        
        It "Should process packages with proper name and version parsing" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0.20231018", "nodejs|20.10.0", "vscode|1.84.2")
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found package: git \(version: 2\.42\.0\.20231018\)" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found package: nodejs \(version: 20\.10\.0\)" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found package: vscode \(version: 1\.84\.2\)" -and $Verbosity -eq "Debug"
            }
        }
        
        It "Should skip lines with invalid format" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("", "invalid-line", "git|2.42.0", "another-invalid", "nodejs|20.10.0")
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found 2 Chocolatey packages" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When Read-DevSetupEnvFile fails" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "git|2.42.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { throw "Failed to read YAML" }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to read YAML configuration from test.yaml" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When processing packages against existing configuration" {
        It "Should add new package not in existing configuration" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "git|2.42.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { 
                return @{ 
                    devsetup = @{ 
                        dependencies = @{ 
                            chocolatey = @{ 
                                packages = @(
                                    @{ name = "nodejs"; version = "20.10.0" }
                                ) 
                            } 
                        } 
                    } 
                } 
            }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Adding package: git \(2\.42\.0\)" -and $ForegroundColor -eq "Gray" -and $Indent -eq 2 -and $Width -eq 112 -and $NoNewline -eq $true
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
        }
        
        It "Should update existing package when version changes" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "nodejs|20.11.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            $existingPackage = @{ name = "nodejs"; version = "20.10.0" }
            Mock Read-DevSetupEnvFile { 
                return @{ 
                    devsetup = @{ 
                        dependencies = @{ 
                            chocolatey = @{ 
                                packages = @($existingPackage) 
                            } 
                        } 
                    } 
                } 
            }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Updating package: nodejs \(20\.10\.0 -> 20\.11\.0\)" -and $ForegroundColor -eq "Cyan" -and $Indent -eq 2 -and $Width -eq 112 -and $NoNewline -eq $true
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
        }
        
        It "Should update existing package when no version exists" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "nodejs|20.10.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            $existingPackage = @{ name = "nodejs" }
            Mock Read-DevSetupEnvFile { 
                return @{ 
                    devsetup = @{ 
                        dependencies = @{ 
                            chocolatey = @{ 
                                packages = @($existingPackage) 
                            } 
                        } 
                    } 
                } 
            }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Updating package: nodejs" -and $ForegroundColor -eq "Gray" -and $Indent -eq 2 -and $Width -eq 112 -and $NoNewline -eq $true
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
        }
        
        It "Should skip existing package with same version" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "nodejs|20.10.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            $existingPackage = @{ name = "nodejs"; version = "20.10.0" }
            Mock Read-DevSetupEnvFile { 
                return @{ 
                    devsetup = @{ 
                        dependencies = @{ 
                            chocolatey = @{ 
                                packages = @($existingPackage) 
                            } 
                        } 
                    } 
                } 
            }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Skipping package \(No Change\): nodejs \(20\.10\.0\)" -and $ForegroundColor -eq "Gray" -and $Indent -eq 2 -and $Width -eq 112 -and $NoNewline -eq $true
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Gray"
            }
        }
    }

    Context "When Update-DevSetupEnvFile fails" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "git|2.42.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { throw "Failed to save YAML" }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to save configuration to test.yaml" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When using DryRun parameter" {
        It "Should pass WhatIf to Update-DevSetupEnvFile" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "git|2.42.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml" -DryRun
            
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -Times 1 -Scope It -ParameterFilter {
                $WhatIf -eq $true
            }
        }
    }

    Context "When validating parameter validation" {
        It "Should throw when Config is null" {
            { Invoke-ChocolateyPackageExport -Config $null } | Should -Throw
        }
        
        It "Should throw when Config is empty string" {
            { Invoke-ChocolateyPackageExport -Config "" } | Should -Throw
        }
    }

    Context "When processing successful export operation" {
        It "Should complete export successfully with multiple packages" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0", "nodejs|20.10.0", "vscode|1.84.2")
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Getting list of installed Chocolatey packages..." -and $ForegroundColor -eq "Gray"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found 3 Chocolatey packages" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It -ParameterFilter {
                $Message -match "Found package:" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It -ParameterFilter {
                $Message -match "Adding package:" -and $ForegroundColor -eq "Gray"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Saving configuration to:" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "Configuration saved successfully!" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "Chocolatey packages conversion completed!" -and $ForegroundColor -eq "Green"
            }
        }
        
        It "Should write proper console messages in the correct sequence" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "git|2.42.0"
            }
            Mock Get-ChocolateyPackageDependencyMap { return @() }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ChocolateyPackageExport -Config "test.yaml"
            
            $result | Should -Be $true
            # Expected messages: Getting list...(1) + Found 1 packages(1) + Found package(1) + Adding package(1) + [OK](1) + Saving(1) + saved(1) + completed(1) = 8 total
            Assert-MockCalled Write-StatusMessage -Exactly 8 -Scope It
        }
    }
}