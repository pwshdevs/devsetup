BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-ChocolateyPackageInstall.ps1")
    . (Join-Path $PSScriptRoot "Install-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "Write-ChocolateyCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Write-StatusMessage { }
    Mock Test-RunningAsAdmin { $true }
    Mock Write-ChocolateyCache { $true }
    Mock Install-ChocolateyPackage { $true }
}

Describe "Invoke-ChocolateyPackageInstall" {

    Context "When not running as administrator" {
        It "Should return false and write error" {
            Mock Test-RunningAsAdmin { $false }
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "requires administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Test-RunningAsAdmin throws exception" {
        It "Should return false and write error" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error" }
        }
    }

    Context "When YamlData is null" {
        It "Should should throw" {
            { Invoke-ChocolateyPackageInstall -YamlData $null } | Should -Throw
        }
    }

    Context "When devsetup section is missing" {
        It "Should return false and write warning" {
            $yamlData = @{ }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When dependencies section is missing" {
        It "Should return false and write warning" {
            $yamlData = @{ devsetup = @{ } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When chocolatey section is missing" {
        It "Should return false and write warning" {
            $yamlData = @{ devsetup = @{ dependencies = @{ } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When packages section is missing" {
        It "Should return false and write warning" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When packages array is empty" {
        It "Should return false" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Chocolatey packages not found in YAML configuration. Skipping installation." }
        }
    }

    Context "When Write-ChocolateyCache fails" {
        It "Should return false and write error" {
            Mock Write-ChocolateyCache { $false }
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to write Chocolatey cache" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Write-ChocolateyCache throws exception" {
        It "Should return false and write error" {
            Mock Write-ChocolateyCache { throw "Cache write failed" }
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error writing Chocolatey cache" -and $Verbosity -eq "Error" }
        }
    }

    Context "When package is object with name only" {
        It "Should install with latest version" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git" }) } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $PackageName -eq "git" -and -not $Version }
        }
    }

    Context "When package is object with version" {
        It "Should install with specified version" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git"; version = "2.42.0" }) } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $PackageName -eq "git" -and $Version -eq "2.42.0" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "version: 2.42.0" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When package is object with params" {
        It "Should install with params" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git"; params = "/silent" }) } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $PackageName -eq "git" -and $Param -eq "/silent" }
        }
    }

    Context "When package is object with name, version, and params" {
        It "Should install with all parameters" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git"; version = "2.42.0"; params = "/silent" }) } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $PackageName -eq "git" -and $Version -eq "2.42.0" -and $Param -eq "/silent" }
        }
    }

    Context "When package object has no name" {
        It "Should skip and write warning" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ version = "1.0.0" }, "git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Message -match "no name specified" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When package name is empty string" {
        It "Should skip and write warning" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "" }, "git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Message -match "no name specified" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When Install-ChocolateyPackage succeeds" {
        It "Should write OK message" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[OK]" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When Install-ChocolateyPackage fails" {
        It "Should write FAILED message and continue" {
            Mock Install-ChocolateyPackage { $false }
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @( @{ name = "git" }, @{ name = "nodejs" } ) } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Message -match "[FAILED]" -and $ForegroundColor -eq "Red" }
        }
    }

    Context "When Install-ChocolateyPackage throws exception" {
        It "Should write FAILED message and error, then continue" {
            Mock Install-ChocolateyPackage { throw "Install failed" }
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @( @{ name = "git" }, @{ name = "nodejs" } ) } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Message -match "[FAILED]" -and $ForegroundColor -eq "Red" }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Message -match "Error installing package" -and $Verbosity -eq "Error" }
        }
    }

    Context "When DryRun is specified" {
        It "Should pass WhatIf to Install-ChocolateyPackage" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git" }) } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData -DryRun
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "When multiple packages with mixed formats" {
        It "Should process all correctly" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git" },
                                @{ name = "nodejs"; version = "18.17.0" },
                                @{ name = "vscode"; params = "/silent" },
                                @{ name = "python"; version = "3.11.0"; params = "/quiet" }
                            )
                        }
                    }
                }
            }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 4 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Processed 4 packages" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When successful installation" {
        It "Should return true and write completion message" {
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result = Invoke-ChocolateyPackageInstall -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "installation completed" -and $ForegroundColor -eq "Green" }
        }
    }
}