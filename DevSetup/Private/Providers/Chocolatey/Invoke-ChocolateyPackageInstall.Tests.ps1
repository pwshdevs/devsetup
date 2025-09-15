BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-ChocolateyPackageInstall.ps1")
    . (Join-Path $PSScriptRoot "Install-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "Write-ChocolateyCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Test-RunningAsAdmin.ps1")
    
    Mock Write-StatusMessage { }
}

Describe "Invoke-ChocolateyPackageInstall" {

    Context "When not running as administrator" {
        It "Should return false and write error message" {
            Mock Test-RunningAsAdmin { return $false }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "requires administrator privileges" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-RunningAsAdmin throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Write-ChocolateyCache fails" {
        It "Should return false when Write-ChocolateyCache returns false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $false }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to write Chocolatey cache" -and $Verbosity -eq "Error"
            }
        }
        
        It "Should handle Write-ChocolateyCache exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { throw "Cache write failed" }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error writing Chocolatey cache" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When installing single package with version" {
        It "Should install package with version and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git"; version = "2.42.0" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Installing Chocolatey packages from configuration:" -and $ForegroundColor -eq "Cyan"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Installing Chocolatey package: git \(version: 2\.42\.0\)" -and $ForegroundColor -eq "Gray"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey packages installation completed! Processed 1 packages" -and $ForegroundColor -eq "Green"
            }
            Assert-MockCalled Install-ChocolateyPackage -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "git" -and $Version -eq "2.42.0" -and $WhatIf -eq $false
            }
        }
    }

    Context "When installing single package without version" {
        It "Should install package with latest version and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "nodejs" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Installing Chocolatey package: nodejs \(version: latest\)" -and $ForegroundColor -eq "Gray"
            }
            Assert-MockCalled Install-ChocolateyPackage -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "nodejs" -and $Version -eq $null
            }
        }
    }

    Context "When installing package with custom parameters" {
        It "Should install package with params and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "googlechrome"; params = "/nogoogle" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "googlechrome" -and $Param -eq "/nogoogle"
            }
        }
        
        It "Should install package with version and params" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "vscode"; version = "1.75.0"; params = "/silent" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "vscode" -and $Version -eq "1.75.0" -and $Param -eq "/silent"
            }
        }
    }

    Context "When installing multiple packages" {
        It "Should install all packages and return true" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git"; version = "2.42.0" },
                                @{ name = "nodejs"; version = "18.17.0" },
                                @{ name = "vscode"; params = "/silent" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Processed 3 packages" -and $ForegroundColor -eq "Green"
            }
            Assert-MockCalled Install-ChocolateyPackage -Times 3 -Scope It
        }
    }

    Context "When individual package installation fails" {
        It "Should mark package as failed but continue processing others" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { 
                param($PackageName)
                if ($PackageName -eq "failing-package") { return $false }
                return $true
            }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" },
                                @{ name = "failing-package" },
                                @{ name = "nodejs" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Processed 2 packages" -and $ForegroundColor -eq "Green"
            }
        }
    }

    Context "When Install-ChocolateyPackage throws an exception" {
        It "Should handle exception and continue processing" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { 
                param($PackageName)
                if ($PackageName -eq "exception-package") { 
                    throw "Package install failed" 
                }
                return $true
            }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" },
                                @{ name = "exception-package" },
                                @{ name = "nodejs" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error installing package exception-package" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Processed 2 packages" -and $ForegroundColor -eq "Green"
            }
        }
    }

    Context "When using DryRun parameter" {
        It "Should pass WhatIf to Install-ChocolateyPackage" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData -DryRun
            
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Times 1 -Scope It -ParameterFilter {
                $PackageName -eq "git" -and $WhatIf -eq $true
            }
        }
    }

    Context "When validating parameter validation" {
        It "Should throw when YamlData is null" {
            { Invoke-ChocolateyPackageInstall -YamlData $null } | Should -Throw
        }
        
        It "Should handle empty YamlData gracefully" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData @{}
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Processed 0 packages" -and $ForegroundColor -eq "Green"
            }
        }
    }

    Context "When YAML structure is missing or incomplete" {
        It "Should handle missing devsetup section gracefully" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            
            $yamlData = @{
                other = @{
                    data = "value"
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey packages installation completed! Processed 0 packages" -and $ForegroundColor -eq "Green"
            }
        }
        
        It "Should handle missing dependencies section gracefully" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            
            $yamlData = @{
                devsetup = @{
                    other = "data"
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Processed 0 packages" -and $ForegroundColor -eq "Green"
            }
        }
        
        It "Should handle missing chocolatey section gracefully" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        npm = @{
                            packages = @("lodash")
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Processed 0 packages" -and $ForegroundColor -eq "Green"
            }
        }
        
        It "Should handle missing packages array gracefully" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            other = "data"
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Processed 0 packages" -and $ForegroundColor -eq "Green"
            }
        }
    }

    Context "When processing packages with formatting validation" {
        It "Should display proper formatting with indent and width settings" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Write-ChocolateyCache { return $true }
            Mock Install-ChocolateyPackage { return $true }
            
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git"; version = "2.42.0" }
                            )
                        }
                    }
                }
            }
            
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Times 1 -Scope It -ParameterFilter {
                $Message -match "Installing Chocolatey package: git \(version: 2\.42\.0\)" -and 
                $ForegroundColor -eq "Gray" -and 
                $Indent -eq 2 -and 
                $Width -eq 112 -and 
                $NoNewline -eq $true
            }
        }
    }
}