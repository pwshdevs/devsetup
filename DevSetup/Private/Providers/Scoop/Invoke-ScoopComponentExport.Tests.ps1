BeforeAll {
    . $PSScriptRoot\Invoke-ScoopComponentExport.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Get-ScoopPackagesAvailable.ps1
    . $PSScriptRoot\Get-ScoopComponentsInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Read-DevSetupEnvFile.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Update-DevSetupEnvFile.ps1
    Mock Write-StatusMessage { }
    Mock Write-Host {}
    Mock Write-Error {}
}

Describe "Invoke-ScoopComponentExport" {

    BeforeEach {
        # Common mock data for tests
        $script:mockYamlData = @{
            devsetup = @{
                dependencies = @{
                    scoop = @{
                        packages = @()
                        buckets = @()
                    }
                }
            }
        }

        $script:mockScoopPackagesAvailable = @{
            "git" = @{ Name = "git"; Version = "2.39.0.windows.2"; Source = "main" }
            "nodejs" = @{ Name = "nodejs"; Version = "18.13.0"; Source = "main" }
            "vscode" = @{ Name = "vscode"; Version = "1.74.2"; Source = "extras" }
        }

        $script:mockScoopExportData = @{
            apps = @(
                @{ Name = "git"; Version = "2.39.0.windows.2"; Info = "" }
                @{ Name = "nodejs"; Version = "18.13.0"; Info = "Global install" }
                @{ Name = "vscode"; Version = "1.74.2"; Info = "" }
            )
            buckets = @(
                @{ Name = "main"; Source = "https://github.com/ScoopInstaller/Main" }
                @{ Name = "extras"; Source = "https://github.com/ScoopInstaller/Extras" }
            )
        }
    }

    Context "When Scoop is not installed" {
        It "Should return false and warn about Scoop not being installed" {
            Mock Test-ScoopInstalled { return $false }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Scoop is not installed. Cannot check for components." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { throw "Critical error checking Scoop" }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Error checking Scoop installation: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Find-Scoop returns null" {
        It "Should return false and warn about failing to find Scoop command" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Failed to find Scoop command. Cannot check for components." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Find-Scoop throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { throw "Error finding Scoop executable" }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Error finding Scoop command: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Get-ScoopPackagesAvailable returns null" {
        It "Should return true and warn about no packages found" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $null }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No Scoop packages found or unable to retrieve packages." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Get-ScoopPackagesAvailable throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { throw "Error getting packages" }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not get Scoop packages: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Get-ScoopComponentsInstalled returns null" {
        It "Should return true and warn about no components found" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { return $null }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No Scoop components found or unable to retrieve components." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Get-ScoopComponentsInstalled throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { throw "Error getting components" }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not get Scoop components: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When ConvertFrom-Json fails with invalid JSON" {
        It "Should return false and log JSON parsing error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { throw "Simulated parsing error" }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not get Scoop components: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When no packages are found after JSON parsing" {
        It "Should return true and warn about no packages" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return @{ apps = @(); buckets = @() }
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No Scoop packages found." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When successfully processing packages and buckets" {
        It "Should export packages and buckets to YAML configuration" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Scoop packages conversion completed!" 
            }
        }
    }

    Context "When main bucket should be skipped" {
        It "Should skip the main bucket but process other buckets" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            # Should skip main bucket
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Skipping 'main' bucket (automatically installed with Scoop)" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When DryRun is specified" {
        It "Should process data but not save to file" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml" -DryRun
            
            $result | Should -Be $true
            Assert-MockCalled Update-DevSetupEnvFile -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "When packages have global installation info" {
        It "Should correctly identify global installations" {
            $mockGlobalExportData = @{
                apps = @(
                    @{ Name = "git"; Version = "2.39.0.windows.2"; Info = "Global install" }
                    @{ Name = "nodejs"; Version = "18.13.0"; Info = "" }
                )
                buckets = @()
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockGlobalExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            # Should process global installation correctly
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "*git* (version: 2.39.0.windows.2, bucket: main, global: True)" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "*nodejs* (version: 18.13.0, bucket: main, global: False)" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When existing packages need updates" {
        It "Should update existing packages with new versions or properties" {
            $mockYamlWithExisting = @{
                devsetup = @{
                    dependencies = @{
                        scoop = @{
                            packages = @(
                                @{ name = "git"; version = "2.38.0.windows.1"; bucket = "main"; global = $false }
                            )
                            buckets = @()
                        }
                    }
                }
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlWithExisting }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            # Should indicate package update
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "- Updating package: git*" 
            }
        }
    }

    Context "When existing buckets need updates" {
        It "Should update existing buckets with new sources" {
            $mockYamlWithExistingBucket = @{
                devsetup = @{
                    dependencies = @{
                        scoop = @{
                            packages = @()
                            buckets = @(
                                @{ name = "extras"; source = "https://old-source.com/Extras" }
                            )
                        }
                    }
                }
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlWithExistingBucket }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            # Should indicate bucket update
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "- Updating bucket: extras*" 
            }
        }
    }

    Context "When Update-DevSetupEnvFile fails" {
        It "Should return false and log error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { throw "Failed to save file" }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Failed to save configuration to test.yaml*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When export data has no buckets property" {
        It "Should handle missing buckets property gracefully" {
            $mockExportDataNoBuckets = @{
                apps = @(
                    @{ Name = "git"; Version = "2.39.0.windows.2"; Info = "" }
                )
                # No buckets property at all
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockExportDataNoBuckets
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No buckets found in scoop export JSON" -and $Verbosity -eq "Verbose"
            }
        }
    }

    Context "When export data has empty buckets array" {
        It "Should handle empty buckets array gracefully" {
            $mockExportDataEmptyBuckets = @{
                apps = @(
                    @{ Name = "git"; Version = "2.39.0.windows.2"; Info = "" }
                )
                buckets = @()  # Empty array
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockExportDataEmptyBuckets
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No buckets found in scoop export JSON" -and $Verbosity -eq "Verbose"
            }
        }
    }

    Context "When export data has no apps property" {
        It "Should handle missing apps property gracefully" {
            $mockExportDataNoApps = @{
                # No apps property at all
                buckets = @(
                    @{ Name = "extras"; Source = "https://github.com/ScoopInstaller/Extras" }
                )
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockExportDataNoApps
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No apps found in scoop export JSON" -and $Verbosity -eq "Verbose"
            }
        }
    }

    Context "When export data has empty apps array" {
        It "Should handle empty apps array gracefully" {
            $mockExportDataEmptyApps = @{
                apps = @()  # Empty array
                buckets = @(
                    @{ Name = "extras"; Source = "https://github.com/ScoopInstaller/Extras" }
                )
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockExportDataEmptyApps
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No apps found in scoop export JSON" -and $Verbosity -eq "Verbose"
            }
        }
    }

    Context "When existing bucket has no source property" {
        It "Should skip updating bucket when existing source is null" {
            $mockYamlWithBucketNoSource = @{
                devsetup = @{
                    dependencies = @{
                        scoop = @{
                            packages = @()
                            buckets = @(
                                @{ name = "extras" }  # No source property
                            )
                        }
                    }
                }
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlWithBucketNoSource }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "- Skipping bucket (No Change): extras*"
            }
        }
    }

    Context "When existing package has no version, global, or bucket properties" {
        It "Should skip updating package when existing properties are null" {
            $mockYamlWithPackageNoProps = @{
                devsetup = @{
                    dependencies = @{
                        scoop = @{
                            packages = @(
                                @{ name = "git" }  # No version, global, or bucket properties
                            )
                            buckets = @()
                        }
                    }
                }
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlWithPackageNoProps }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "- Skipping package (No Change): git*"
            }
        }
    }

    Context "When existing package needs only global property update" {
        It "Should update package when only global property changes" {
            $mockYamlWithGlobalDiff = @{
                devsetup = @{
                    dependencies = @{
                        scoop = @{
                            packages = @(
                                @{ name = "git"; version = "2.39.0.windows.2"; bucket = "main"; global = $true }
                            )
                            buckets = @()
                        }
                    }
                }
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlWithGlobalDiff }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "- Updating package: git*"
            }
        }
    }

    Context "When existing package needs only bucket property update" {
        It "Should update package when only bucket property changes" {
            $mockYamlWithBucketDiff = @{
                devsetup = @{
                    dependencies = @{
                        scoop = @{
                            packages = @(
                                @{ name = "git"; version = "2.39.0.windows.2"; bucket = "extras"; global = $false }
                            )
                            buckets = @()
                        }
                    }
                }
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlWithBucketDiff }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "- Updating package: git*"
            }
        }
    }

    Context "When package has missing source in available packages list" {
        It "Should handle missing package source gracefully" {
            $mockScoopPackagesNoSource = @{
                "git" = @{ Name = "git"; Version = "2.39.0.windows.2" }  # No Source property
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesNoSource }
            Mock Get-ScoopComponentsInstalled { 
                $singleAppData = @{
                    apps = @(@{ Name = "git"; Version = "2.39.0.windows.2"; Info = "" })
                    buckets = @()
                }
                return $singleAppData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            # Should still process the package even without source
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Found package: git*"
            }
        }
    }

    Context "When bucket processing encounters debug logging" {
        It "Should log bucket processing details at debug level" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Found bucket: extras*" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Found * Scoop packages and * buckets" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When save operation logging is triggered" {
        It "Should log configuration save operations" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $mockScoopPackagesAvailable }
            Mock Get-ScoopComponentsInstalled { 
                return $mockScoopExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "*Saving configuration to:*" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Configuration saved successfully!" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "Performance test with large dataset" {
        It "Should handle large numbers of packages and buckets efficiently" {
            # Generate large mock datasets
            $largeMockPackages = @{}
            $largeMockApps = @()
            for ($i = 1; $i -le 500; $i++) {
                $largeMockPackages["package$i"] = @{ Name = "package$i"; Version = "1.0.$i"; Source = "main" }
                $largeMockApps += @{ Name = "package$i"; Version = "1.0.$i"; Info = "" }
            }
            
            $largeMockExportData = @{
                apps = $largeMockApps
                buckets = @(
                    @{ Name = "extras"; Source = "https://github.com/ScoopInstaller/Extras" }
                )
            }
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Get-ScoopPackagesAvailable { return $largeMockPackages }
            Mock Get-ScoopComponentsInstalled { 
                return $largeMockExportData
            }
            Mock Read-DevSetupEnvFile { return $mockYamlData }
            Mock Update-DevSetupEnvFile { }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-ScoopComponentExport -Config "test.yaml"
            $stopwatch.Stop()
            
            $result | Should -Be $true
            # Should complete in reasonable time (less than 30 seconds)
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 30000
        }
    }
}
