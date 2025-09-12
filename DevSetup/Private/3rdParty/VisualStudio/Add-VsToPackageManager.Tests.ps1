BeforeAll {
    . (Join-Path $PSScriptRoot "Add-VsToPackageManager.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Update-DevSetupEnvFile.ps1")
    Mock Write-StatusMessage { }
    Mock Read-DevSetupEnvFile { 
        return @{
            devsetup = @{
                dependencies = @{
                    chocolatey = @{
                        packages = @()
                    }
                }
            }
        }
    }
    Mock Update-DevSetupEnvFile { }
}

Describe "Add-VsToPackageManager" {

    Context "When adding Visual Studio 2022 Community" {
        It "Should add package and return package name" {
            $instance = @{ DisplayName = "Visual Studio Community 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2022community"
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Found: Visual Studio Community 2022" -and $ForegroundColor -eq "Gray" -and $Indent -eq 2 }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Adding Visual Studio Community 2022" -and $ForegroundColor -eq "Gray" -and $Indent -eq 4 }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[OK]" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When adding Visual Studio 2019 Professional" {
        It "Should add package and return package name" {
            $instance = @{ DisplayName = "Visual Studio Professional 2019" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2019professional"
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }

    Context "When adding Visual Studio 2022 Enterprise" {
        It "Should add package and return package name" {
            $instance = @{ DisplayName = "Visual Studio Enterprise 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2022enterprise"
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }

    Context "When package already exists as string" {
        It "Should return package name without updating" {
            Mock Read-DevSetupEnvFile { 
                return @{
                    devsetup = @{
                        dependencies = @{
                            chocolatey = @{
                                packages = @("visualstudio2022community")
                            }
                        }
                    }
                }
            }
            $instance = @{ DisplayName = "Visual Studio Community 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2022community"
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Visual Studio is already listed as a chocolatey package." -and $Verbosity -eq "Debug" }
        }
    }

    Context "When package already exists as hashtable" {
        It "Should return package name without updating" {
            Mock Read-DevSetupEnvFile { 
                return @{
                    devsetup = @{
                        dependencies = @{
                            chocolatey = @{
                                packages = @(@{ name = "visualstudio2022community"; version = "17.0" })
                            }
                        }
                    }
                }
            }
            $instance = @{ DisplayName = "Visual Studio Community 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2022community"
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "When display name has no year" {
        It "Should write warning and return null" {
            $instance = @{ DisplayName = "Visual Studio Community" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Unable to determine Visual Studio year" -and $ForegroundColor -eq "Yellow" -and $Indent -eq 4 }
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "When display name has no type" {
        It "Should write warning and return null" {
            $instance = @{ DisplayName = "Visual Studio 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Unable to determine Visual Studio type" -and $ForegroundColor -eq "Yellow" -and $Indent -eq 4 }
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "When Read-DevSetupEnvFile returns empty data" {
        It "Should create structure and add package" {
            Mock Read-DevSetupEnvFile { 
                return @{ 
                    devsetup = @{ 
                        configuration = @{} 
                        dependencies = @{} 
                        commands = @() 
                    } 
                } 
            }
            $instance = @{ DisplayName = "Visual Studio Community 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2022community"
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It
        }
    }

    Context "When Update-DevSetupEnvFile throws exception" {
        It "Should write error and return null" {
            Mock Update-DevSetupEnvFile { throw "Update failed" }
            $instance = @{ DisplayName = "Visual Studio Community 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error updating DevSetup environment file" -and $Verbosity -eq "Error" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "[FAILED]" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When DryRun is specified" {
        It "Should call Update-DevSetupEnvFile with WhatIf" {
            $instance = @{ DisplayName = "Visual Studio Community 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile -DryRun
            $result | Should -Be "visualstudio2022community"
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "When instance is null" {
        It "Should throw due to parameter validation" {
            { Add-VsToPackageManager -Instance $null -Config "$TestDrive\config.yaml" } | Should -Throw
        }
    }

    Context "When config is empty" {
        It "Should throw due to parameter validation" {
            $instance = @{ DisplayName = "Visual Studio Community 2022" }
            { Add-VsToPackageManager -Instance $instance -Config "" } | Should -Throw
        }
    }

    Context "When display name has multiple years" {
        It "Should use the first matched year" {
            $instance = @{ DisplayName = "Visual Studio 2022 Community 2019" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2022community"
        }
    }

    Context "When display name has mixed case" {
        It "Should match type case-insensitively" {
            $instance = @{ DisplayName = "visual studio PROFESSIONAL 2022" }
            $configFile = "$TestDrive\config.yaml"
            $result = Add-VsToPackageManager -Instance $instance -Config $configFile
            $result | Should -Be "visualstudio2022professional"
        }
    }
}
