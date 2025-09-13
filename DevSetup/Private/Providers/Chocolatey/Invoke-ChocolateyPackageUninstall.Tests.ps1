BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-ChocolateyPackageUninstall.ps1")
    . (Join-Path $PSScriptRoot "Uninstall-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "Write-ChocolateyCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Test-RunningAsAdmin.ps1")
    Mock Write-StatusMessage { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Write-ChocolateyCache { return $true }
    Mock Uninstall-ChocolateyPackage { return $true }
}

Describe "Invoke-ChocolateyPackageUninstall" {

    Context "When not running as admin" {
        It "Should return false and write error" {
            Mock Test-RunningAsAdmin { return $false }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "requires administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Test-RunningAsAdmin throws exception" {
        It "Should return false and write error" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When YAML data is null" {
        It "Should throw" {
            { Invoke-ChocolateyPackageUninstall -YamlData $null } | Should -Throw
        }
    }

    Context "When YAML data has no devsetup" {
        It "Should return without processing" {
            $yamlData = @{ }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When YAML data has no dependencies" {
        It "Should return without processing" {
            $yamlData = @{ devsetup = @{ } }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When YAML data has no chocolatey" {
        It "Should return without processing" {
            $yamlData = @{ devsetup = @{ dependencies = @{ } } }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When YAML data has no packages" {
        It "Should return without processing" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ } } } }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When Write-ChocolateyCache fails" {
        It "Should return false and write error" {
            Mock Write-ChocolateyCache { return $false }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to write Chocolatey cache" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When Write-ChocolateyCache throws exception" {
        It "Should return false and write error" {
            Mock Write-ChocolateyCache { throw "Cache write failed" }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When single package as string" {
        It "Should uninstall package and return true" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $PackageName -eq "git" -and $WhatIf -eq $false }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Uninstalling Chocolatey package: git" -and $ForegroundColor -eq "Gray" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[OK]" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "uninstallation completed" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When single package as hashtable with version" {
        It "Should uninstall package with version and return true" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(@{ name = "git"; version = "2.0.0" })
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $PackageName -eq "git" -and $WhatIf -eq $false }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "version: 2.0.0" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When single package as hashtable without version" {
        It "Should uninstall package and show latest version" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(@{ name = "git" })
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "version: latest" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When multiple packages" {
        It "Should uninstall all packages and return true" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git", @{ name = "nodejs"; version = "14.0.0" })
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-ChocolateyPackage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Processed 2 packages" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When package is null" {
        It "Should skip null package" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @($null, "git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-ChocolateyPackage -Exactly 1 -Scope It
        }
    }

    Context "When package has no name" {
        It "Should skip package and write warning" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(@{ }, "git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Uninstall-ChocolateyPackage -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "has no name specified" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When Uninstall-ChocolateyPackage returns false" {
        It "Should write failed and continue" {
            Mock Uninstall-ChocolateyPackage { return $false }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red" }
        }
    }

    Context "When Uninstall-ChocolateyPackage throws exception" {
        It "Should return false and write error" {
            Mock Uninstall-ChocolateyPackage { throw "Uninstall failed" }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When DryRun is specified" {
        It "Should pass WhatIf to Uninstall-ChocolateyPackage" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageUninstall -YamlData $yamlData -DryRun
            $result | Should -Be $true
            Assert-MockCalled Uninstall-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "When YamlData is empty" {
        It "Should write error and return false" {
            $result = Invoke-ChocolateyPackageUninstall -YamlData @{}
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }
}