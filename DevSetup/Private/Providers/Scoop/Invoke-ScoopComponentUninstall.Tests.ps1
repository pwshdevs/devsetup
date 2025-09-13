BeforeAll {
    . $PSScriptRoot\Invoke-ScoopComponentUninstall.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\Uninstall-ScoopBucket.ps1
    . $PSScriptRoot\Uninstall-ScoopPackage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }
}

Describe "Invoke-ScoopComponentUninstall" {

    BeforeEach {
        $global:LASTEXITCODE = 0
        
        # Mock data matching Assert-DevSetupEnvValid structure requirements
        $script:mockYamlDataEmpty = [PSCustomObject]@{
            devsetup = [PSCustomObject]@{
                dependencies = [PSCustomObject]@{
                    scoop = [PSCustomObject]@{
                        buckets = @()
                        packages = @()
                    }
                }
            }
        }
        
        $script:mockYamlDataWithBuckets = [PSCustomObject]@{
            devsetup = [PSCustomObject]@{
                dependencies = [PSCustomObject]@{
                    scoop = [PSCustomObject]@{
                        buckets = @(
                            [PSCustomObject]@{ name = "extras"; source = "https://github.com/ScoopInstaller/Extras.git" },
                            [PSCustomObject]@{ name = "versions"; source = "https://github.com/ScoopInstaller/Versions.git" }
                        )
                        packages = @()
                    }
                }
            }
        }
        
        $script:mockYamlDataWithPackages = [PSCustomObject]@{
            devsetup = [PSCustomObject]@{
                dependencies = [PSCustomObject]@{
                    scoop = [PSCustomObject]@{
                        buckets = @()
                        packages = @(
                            [PSCustomObject]@{ name = "git"; bucket = "main" },
                            [PSCustomObject]@{ name = "nodejs"; version = "18.17.0"; bucket = "main" },
                            [PSCustomObject]@{ name = "7zip"; global = $true; bucket = "extras" }
                        )
                    }
                }
            }
        }
        
        $script:mockYamlDataMixed = [PSCustomObject]@{
            devsetup = [PSCustomObject]@{
                dependencies = [PSCustomObject]@{
                    scoop = [PSCustomObject]@{
                        buckets = @(
                            [PSCustomObject]@{ name = "extras"; source = "https://github.com/ScoopInstaller/Extras.git" }
                        )
                        packages = @(
                            [PSCustomObject]@{ name = "git"; bucket = "main" },
                            [PSCustomObject]@{ name = "nodejs"; version = "18.17.0"; bucket = "main"; global = $true }
                        )
                    }
                }
            }
        }
    }

    Context "When Scoop is not installed" {
        It "Should return false and display warning message" {
            Mock Test-ScoopInstalled { return $false }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $false
            Should -Invoke Test-ScoopInstalled -Times 1 -Exactly
            Should -Invoke Write-StatusMessage -Times 1 -Exactly -ParameterFilter { 
                $Message -like "*Scoop is not installed*" -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Scoop configuration has empty arrays" {
        It "Should return true and not attempt any uninstalls" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $true }
            Mock Uninstall-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataEmpty
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -Times 0 -Exactly
            Should -Invoke Uninstall-ScoopPackage -Times 0 -Exactly
        }
    }

    Context "When Write-ScoopCache fails" {
        It "Should return false and display error message" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $false }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -Times 1 -Exactly -ParameterFilter { 
                $Message -like "*Failed to write Scoop cache file*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When only buckets are present and all uninstalls succeed" {
        It "Should return true and uninstall all buckets" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $true }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -Times 2 -Exactly
        }
    }

    Context "When only packages are present and all uninstalls succeed" {
        It "Should return true and uninstall all packages" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopPackage -Times 3 -Exactly
        }
    }

    Context "When buckets and packages are present" {
        It "Should return true and uninstall both buckets and packages" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $true }
            Mock Uninstall-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataMixed
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -Times 1 -Exactly
            Should -Invoke Uninstall-ScoopPackage -Times 2 -Exactly
        }
    }

    Context "When using DryRun parameter" {
        It "Should pass WhatIf to both bucket and package uninstall functions" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $true }
            Mock Uninstall-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataMixed -DryRun
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -ParameterFilter { $WhatIf -eq $true } -Times 1 -Exactly
            Should -Invoke Uninstall-ScoopPackage -ParameterFilter { $WhatIf -eq $true } -Times 2 -Exactly
        }

        It "Should return true when using DryRun with only buckets" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $true }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithBuckets -DryRun
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -ParameterFilter { $WhatIf -eq $true } -Times 2 -Exactly
        }
    }

    Context "When complex object formats are used" {
        It "Should handle package objects with all properties" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopPackage { return $true }
            
            $complexData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    dependencies = [PSCustomObject]@{
                        scoop = [PSCustomObject]@{
                            buckets = @()
                            packages = @(
                                [PSCustomObject]@{ name = "git"; bucket = "main" },
                                [PSCustomObject]@{ name = "nodejs"; version = "18.17.0"; bucket = "main"; global = $false },
                                [PSCustomObject]@{ name = "python"; bucket = "main"; global = $true }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $complexData
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopPackage -ParameterFilter { $PackageName -eq "git" } -Times 1 -Exactly
            Should -Invoke Uninstall-ScoopPackage -ParameterFilter { $PackageName -eq "nodejs" } -Times 1 -Exactly
            Should -Invoke Uninstall-ScoopPackage -ParameterFilter { $PackageName -eq "python" -and $Global -eq $true } -Times 1 -Exactly
        }

        It "Should skip packages and buckets with missing names" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $true }
            Mock Uninstall-ScoopPackage { return $true }
            
            $invalidData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    dependencies = [PSCustomObject]@{
                        scoop = [PSCustomObject]@{
                            buckets = @(
                                [PSCustomObject]@{ source = "https://example.com" }, # Missing name
                                [PSCustomObject]@{ name = "extras"; source = "https://github.com/ScoopInstaller/Extras.git" },
                                [PSCustomObject]@{ name = ""; source = "https://example2.com" } # Empty name
                            )
                            packages = @(
                                [PSCustomObject]@{ bucket = "main" }, # Missing name
                                [PSCustomObject]@{ name = "git"; bucket = "main" },
                                [PSCustomObject]@{ name = $null; bucket = "main" } # Null name
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $invalidData
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -Times 1 -Exactly  # Only the valid bucket
            Should -Invoke Uninstall-ScoopPackage -Times 1 -Exactly  # Only the valid package
        }

        It "Should handle buckets without source property (line 132 coverage)" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $true }
            
            $bucketsWithoutSource = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    dependencies = [PSCustomObject]@{
                        scoop = [PSCustomObject]@{
                            buckets = @(
                                [PSCustomObject]@{ name = "main" }, # No source property
                                [PSCustomObject]@{ name = "extras"; source = "" } # Empty source
                            )
                            packages = @()
                        }
                    }
                }
            }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $bucketsWithoutSource
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -Times 2 -Exactly
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -eq "- Removing Scoop bucket: main" -and $ForegroundColor -eq "Gray"
            } -Times 1 -Exactly
        }
    }

    Context "When Write-ScoopCache throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { throw "Cache write failed" }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Error writing Scoop cache*" -and $Verbosity -eq "Error" 
            } -Times 1 -Exactly
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { throw "Scoop test failed" }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Scoop is not installed*" -and $Verbosity -eq "Error" 
            } -Times 1 -Exactly
        }
    }

    Context "When uninstall operations return false" {
        It "Should display [FAILED] when bucket uninstall returns false (line 144 coverage)" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopBucket { return $false } # Return false instead of throwing
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $true  # Function still continues and returns true
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red"
            } -Times 2 -Exactly  # Should be called for both failed buckets
        }

        It "Should display [FAILED] when package uninstall returns false (line 201 coverage)" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopPackage { return $false } # Return false instead of throwing
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true  # Function still continues and returns true
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red"
            } -Times 3 -Exactly  # Should be called for all 3 failed packages
        }

        It "Should display [FAILED] when package uninstall sets LASTEXITCODE to non-zero" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Uninstall-ScoopPackage { 
                $global:LASTEXITCODE = 1  # Set non-zero exit code
                return $true 
            }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true  # Function still continues and returns true
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red"
            } -Times 3 -Exactly  # Should be called for all 3 packages due to LASTEXITCODE
        }
    }

    Context "When uninstall operations throw exceptions" {
        It "Should continue processing remaining components when bucket uninstall fails" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            $script:callCount = 0
            Mock Uninstall-ScoopBucket { 
                $script:callCount++
                if ($script:callCount -eq 1) { throw "First bucket failed" }
                return $true
            }
            Mock Uninstall-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataMixed
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopBucket -Times 1 -Exactly
            Should -Invoke Uninstall-ScoopPackage -Times 2 -Exactly  # Packages should still be processed
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Failed to uninstall Scoop bucket*" -and $Verbosity -eq "Error" 
            } -Times 1 -Exactly
        }

        It "Should continue processing remaining packages when package uninstall fails" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            $script:callCount = 0
            Mock Uninstall-ScoopPackage { 
                $script:callCount++
                if ($script:callCount -eq 1) { throw "First package failed" }
                return $true
            }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true
            Should -Invoke Uninstall-ScoopPackage -Times 3 -Exactly
            # Verify Write-StatusMessage was called with error verbosity
            Should -Invoke Write-StatusMessage -Times 2 -Exactly -ParameterFilter { 
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When configuration structure is missing or invalid" {
        It "Should handle missing scoop configuration gracefully" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            
            $missingData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    dependencies = [PSCustomObject]@{}
                }
            }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $missingData
            
            $result | Should -Be $true  # Should complete successfully but do nothing
        }

        It "Should handle missing dependencies section" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            
            $missingData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{}
            }
            
            $result = Invoke-ScoopComponentUninstall -YamlData $missingData
            
            $result | Should -Be $true  # Should complete successfully but do nothing
        }

        It "Should handle missing devsetup section" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            
            $missingData = [PSCustomObject]@{}
            
            $result = Invoke-ScoopComponentUninstall -YamlData $missingData
            
            $result | Should -Be $true  # Should complete successfully but do nothing
        }
    }
}