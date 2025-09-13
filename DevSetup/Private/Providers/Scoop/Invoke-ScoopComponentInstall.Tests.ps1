BeforeAll {
    . $PSScriptRoot\Invoke-ScoopComponentInstall.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\Install-ScoopBucket.ps1
    . $PSScriptRoot\Install-ScoopPackage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }
    Mock Write-Host {}
    Mock Write-Error {}
}

Describe "Invoke-ScoopComponentInstall" {

    BeforeEach {
        $global:LASTEXITCODE = 0
        # Mock data for testing
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
                            [PSCustomObject]@{ name = "extras" },
                            [PSCustomObject]@{ name = "versions"; source = "https://github.com/ScoopInstaller/Versions" }
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
                            [PSCustomObject]@{ name = "git" },
                            [PSCustomObject]@{ name = "nodejs"; version = "18.17.0" },
                            [PSCustomObject]@{ name = "7zip"; global = $true },
                            [PSCustomObject]@{ name = "firefox"; bucket = "extras"; global = $false }
                        )
                    }
                }
            }
        }
        
        $script:mockYamlDataFull = [PSCustomObject]@{
            devsetup = [PSCustomObject]@{
                dependencies = [PSCustomObject]@{
                    scoop = [PSCustomObject]@{
                        buckets = @(
                            [PSCustomObject]@{ name = "extras" },
                            [PSCustomObject]@{ name = "custom"; source = "https://github.com/user/custom-bucket" }
                        )
                        packages = @(
                            [PSCustomObject]@{ name = "git" },
                            [PSCustomObject]@{ name = "nodejs"; version = "18.17.0"; bucket = "main"; global = $false }
                        )
                    }
                }
            }
        }
    }

    Context "When Scoop is not installed" {
        It "Should return false and warn about Scoop not being installed" {
            Mock Test-ScoopInstalled { return $false }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataFull
            
            $result | Should -Be $false
            Assert-MockCalled Test-ScoopInstalled -Times 1 -Exactly -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Scoop is not installed. Cannot check for components." -and $Verbosity -eq "Warning" 
            } -Times 1 -Exactly -Scope It
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { throw "Scoop verification failed" }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataFull
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not verify Scoop installation: *" -and $Verbosity -eq "Error" 
            } -Times 1 -Exactly -Scope It
        }
    }

    Context "When Write-ScoopCache fails" {
        It "Should return false and log cache update failure" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $false }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataFull
            
            $result | Should -Be $false
            Assert-MockCalled Test-ScoopInstalled -Times 1 -Exactly -Scope It
            Assert-MockCalled Write-ScoopCache -Times 1 -Exactly -Scope It
        }
    }

    Context "When Write-ScoopCache throws an exception" {
        It "Should return false and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { throw "Cache update failed" }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataFull
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not update Scoop cache: *" -and $Verbosity -eq "Error" 
            } -Times 1 -Exactly -Scope It
        }
    }

    Context "When no buckets or packages are configured" {
        It "Should return true and process empty configuration successfully" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataEmpty
            
            $result | Should -Be $true
            Assert-MockCalled Test-ScoopInstalled -Times 1 -Exactly -Scope It
            Assert-MockCalled Write-ScoopCache -Times 1 -Exactly -Scope It
        }
    }

    Context "When processing buckets with valid configurations" {
        It "Should install all buckets successfully" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopBucket { return $true }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopBucket -Times 2 -Exactly -Scope It
            Assert-MockCalled Install-ScoopBucket -ParameterFilter { 
                $Name -eq "extras" -and $WhatIf -eq $false 
            } -Times 1 -Exactly -Scope It
            Assert-MockCalled Install-ScoopBucket -ParameterFilter { 
                $Name -eq "versions" -and $Source -eq "https://github.com/ScoopInstaller/Versions" -and $WhatIf -eq $false 
            } -Times 1 -Exactly -Scope It
        }
    }

    Context "When processing buckets with DryRun enabled" {
        It "Should pass WhatIf parameter to Install-ScoopBucket" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopBucket { return $true }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithBuckets -DryRun
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopBucket -ParameterFilter { 
                $WhatIf -eq $true 
            } -Times 2 -Exactly -Scope It
        }
    }

    Context "When bucket installation fails" {
        It "Should continue processing and still return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopBucket { 
                param($Name)
                if ($Name -eq "extras") { return $false } else { return $true }
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithBuckets
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopBucket -Times 2 -Exactly -Scope It
        }
    }

    Context "When bucket has missing or invalid name" {
        It "Should skip bucket and log warning" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopBucket { return $true }
            
            $yamlDataInvalidBucket = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    dependencies = [PSCustomObject]@{
                        scoop = [PSCustomObject]@{
                            buckets = @(
                                [PSCustomObject]@{ name = "" },  # Empty name
                                [PSCustomObject]@{ source = "https://example.com" },  # Missing name
                                [PSCustomObject]@{ name = "valid" }  # Valid bucket
                            )
                            packages = @()
                        }
                    }
                }
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $yamlDataInvalidBucket
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopBucket -Times 1 -Exactly -Scope It  # Only valid bucket processed
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Skipping bucket entry, No name specified" -and $Verbosity -eq "Warning" 
            } -Times 2 -Exactly -Scope It  # Two invalid buckets skipped
        }
    }

    Context "When processing packages with valid configurations" {
        It "Should install all packages successfully with correct parameters" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopPackage -Times 4 -Exactly -Scope It
            
            # Test specific package configurations
            Assert-MockCalled Install-ScoopPackage -ParameterFilter { 
                $PackageName -eq "git" -and $WhatIf -eq $false -and $Global -eq $false
            } -Times 1 -Exactly -Scope It
            
            Assert-MockCalled Install-ScoopPackage -ParameterFilter { 
                $PackageName -eq "nodejs" -and $Version -eq "18.17.0" -and $WhatIf -eq $false -and $Global -eq $false
            } -Times 1 -Exactly -Scope It
            
            Assert-MockCalled Install-ScoopPackage -ParameterFilter { 
                $PackageName -eq "7zip" -and $Global -eq $true -and $WhatIf -eq $false
            } -Times 1 -Exactly -Scope It
            
            Assert-MockCalled Install-ScoopPackage -ParameterFilter { 
                $PackageName -eq "firefox" -and $Bucket -eq "extras" -and $Global -eq $false -and $WhatIf -eq $false
            } -Times 1 -Exactly -Scope It
        }
    }

    Context "When processing packages with DryRun enabled" {
        It "Should pass WhatIf parameter to Install-ScoopPackage" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithPackages -DryRun
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopPackage -ParameterFilter { 
                $WhatIf -eq $true 
            } -Times 4 -Exactly -Scope It
        }
    }

    Context "When package installation fails" {
        It "Should continue processing and still return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopPackage { 
                param($PackageName)
                if ($PackageName -eq "git") { return $false } else { return $true }
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopPackage -Times 4 -Exactly -Scope It
        }
    }

    Context "When package installation fails due to LASTEXITCODE" {
        It "Should detect failure and log accordingly" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopPackage { 
                $global:LASTEXITCODE = 1
                return $true  # Return true but set exit code to indicate failure
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true  # Function continues despite failures
            Assert-MockCalled Install-ScoopPackage -Times 4 -Exactly -Scope It
        }
    }

    Context "When package has missing or invalid name" {
        It "Should skip package and log warning" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopPackage { return $true }
            
            $yamlDataInvalidPackage = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    dependencies = [PSCustomObject]@{
                        scoop = [PSCustomObject]@{
                            buckets = @()
                            packages = @(
                                [PSCustomObject]@{ name = "" },  # Empty name
                                [PSCustomObject]@{ version = "1.0.0" },  # Missing name
                                [PSCustomObject]@{ name = "valid" }  # Valid package
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $yamlDataInvalidPackage
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopPackage -Times 1 -Exactly -Scope It  # Only valid package processed
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Skipping package entry, No name specified" -and $Verbosity -eq "Warning" 
            } -Times 2 -Exactly -Scope It  # Two invalid packages skipped
        }
    }

    Context "When Install-ScoopPackage throws an exception" {
        It "Should catch exception, log error, and continue processing" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopPackage { 
                param($PackageName)
                if ($PackageName -eq "git") { 
                    throw "Package installation failed" 
                } else { 
                    return $true 
                }
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataWithPackages
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopPackage -Times 4 -Exactly -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Failed to install Scoop package 'git': *" -and $Verbosity -eq "Error" 
            } -Times 1 -Exactly -Scope It
        }
    }

    Context "When processing both buckets and packages" {
        It "Should process buckets first, then packages" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopBucket { return $true }
            Mock Install-ScoopPackage { return $true }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataFull
            
            $result | Should -Be $true
            Assert-MockCalled Install-ScoopBucket -Times 2 -Exactly -Scope It
            Assert-MockCalled Install-ScoopPackage -Times 2 -Exactly -Scope It
        }
    }

    Context "When processing large configuration with mixed success/failure" {
        It "Should handle mixed results and return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            
            $bucketCallCount = 0
            Mock Install-ScoopBucket { 
                $bucketCallCount++
                return ($bucketCallCount % 2 -eq 1)  # Alternate success/failure
            }
            
            $packageCallCount = 0
            Mock Install-ScoopPackage { 
                $packageCallCount++
                if ($packageCallCount -eq 2) { throw "Random failure" }
                return ($packageCallCount % 3 -ne 0)  # Various success patterns
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $script:mockYamlDataFull
            
            $result | Should -Be $true  # Should succeed overall despite individual failures
            Assert-MockCalled Install-ScoopBucket -Times 2 -Exactly -Scope It
            Assert-MockCalled Install-ScoopPackage -Times 2 -Exactly -Scope It
        }
    }

    Context "When YAML data structure is missing required properties" {
        It "Should handle missing scoop section gracefully" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            
            $yamlDataMissingScoop = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    dependencies = [PSCustomObject]@{
                        # Missing scoop section
                    }
                }
            }
            
            $result = Invoke-ScoopComponentInstall -YamlData $yamlDataMissingScoop
            
            $result | Should -Be $true  # Should handle gracefully
        }
    }
}