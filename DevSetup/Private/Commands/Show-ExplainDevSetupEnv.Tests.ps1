BeforeAll {
    . (Join-Path $PSScriptRoot "Show-ExplainDevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\Private\Utils\Format-PrettyTable.ps1")
    Mock Write-StatusMessage { }
    Mock Get-DevSetupEnvPath { Join-Path $TestDrive "devsetup" }
    Mock Read-DevSetupEnvFile {
        return @{
            devsetup = @{
                configuration = @{
                    description = "Test description"
                    version = "1.0.0"
                    createdBy = "Test User"
                    createdDate = "2023-01-01"
                    lastUpdatedDate = "2023-01-02"
                    os = @{
                        name = "Windows"
                    }
                }
                dependencies = @{
                    chocolatey = @{
                        packages = @(@{ name = "git"; version = "2.0.0" })
                    }
                    powershell = @{
                        modules = @(@{ name = "PSScriptAnalyzer"; minimumVersion = "1.0.0" })
                    }
                }
                commands = @(@{ name = "test command" })
            }
        }
    }
    Mock Format-PrettyTable { }
    Mock Test-Path { return $true }
}

Describe "Show-ExplainDevSetupEnv" {

    Context "When name is provided without provider" {
        It "Should use local provider and construct correct path" {
            $expectedPath = Join-Path (Join-Path $TestDrive "devsetup") "local" | Join-Path -ChildPath "testenv.devsetup"
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $expectedPath }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $Config -eq $expectedPath }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Reading environment file" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When name is provided with provider" {
        It "Should parse provider and name correctly" {
            $expectedPath = Join-Path (Join-Path $TestDrive "devsetup") "remote" | Join-Path -ChildPath "testenv.devsetup"
            Show-ExplainDevSetupEnv -Name "remote:testenv"
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $expectedPath }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $Config -eq $expectedPath }
        }
    }

    Context "When name has multiple colons" {
        It "Should use first part as provider" {
            $expectedPath = Join-Path (Join-Path $TestDrive "devsetup") "remote" | Join-Path -ChildPath "extra.devsetup"
            Show-ExplainDevSetupEnv -Name "remote:extra:testenv"
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $expectedPath }
        }
    }

    Context "When path is provided and file exists" {
        It "Should use provided path and extract name" {
            $testFile = Join-Path $TestDrive "test.devsetup"
            New-Item -ItemType File -Path $testFile
            Show-ExplainDevSetupEnv -Path $testFile
            Assert-MockCalled Test-Path -Exactly 2 -Scope It -ParameterFilter { $Path -eq $testFile }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $Config -eq $testFile }
        }
    }

    Context "When path is provided but file does not exist" {
        It "Should write error and return early" {
            $testPath = Join-Path $TestDrive "nonexistent.devsetup"
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $testPath }
            Show-ExplainDevSetupEnv -Path $testPath
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Invalid Path provided" -and $Verbosity -eq "Error" }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
        }
    }

    Context "When constructed file path does not exist" {
        It "Should write error and return early" {
            Mock Test-Path { return $false } -ParameterFilter { $Path -match "\.devsetup$" }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file not found" -and $Verbosity -eq "Error" }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
        }
    }

    Context "When Read-DevSetupEnvFile returns null" {
        It "Should write error and return early" {
            Mock Read-DevSetupEnvFile { return $null }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to read or parse" -and $Verbosity -eq "Error" }
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
        }
    }

    Context "When Read-DevSetupEnvFile throws exception" {
        It "Should write error and return early" {
            Mock Read-DevSetupEnvFile { throw "Parse error" }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to read or parse" -and $Verbosity -eq "Error" }
        }
    }

    Context "When YAML data is missing devsetup section" {
        It "Should handle gracefully" {
            Mock Read-DevSetupEnvFile { return @{ } }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
        }
    }

    Context "When configuration section is missing" {
        It "Should handle missing configuration gracefully" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        dependencies = @{
                            chocolatey = @{
                                packages = @(@{ name = "git"; version = "2.0.0" })
                            }
                        }
                        commands = @()
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Malformed devsetup environment file" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When dependencies section is missing" {
        It "Should handle missing dependencies gracefully" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        configuration = @{
                            description = "Test"
                            version = "1.0"
                            createdBy = "Test"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{ name = "Windows" }
                        }
                        commands = @()
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Malformed devsetup environment file" }
        }
    }

    Context "When commands section is missing" {
        It "Should handle missing commands gracefully" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        configuration = @{
                            description = "Test"
                            version = "1.0"
                            createdBy = "Test"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{ name = "Windows" }
                        }
                        dependencies = @{
                            chocolatey = @{
                                packages = @(@{ name = "git"; version = "2.0.0" })
                            }
                        }
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When dependencies have empty packages and modules" {
        It "Should handle empty collections and show no packages message" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        configuration = @{
                            description = "Test"
                            version = "1.0"
                            createdBy = "Test"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{ name = "Windows" }
                        }
                        dependencies = @{
                            chocolatey = @{ packages = @() }
                            powershell = @{ modules = @() }
                        }
                        commands = @()
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "No packages or modules defined" -and $ForegroundColor -eq "Yellow" }
        }
    }

    Context "When dependencies have only packages" {
        It "Should display packages table correctly" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        configuration = @{
                            description = "Test"
                            version = "1.0"
                            createdBy = "Test"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{ name = "Windows" }
                        }
                        dependencies = @{
                            chocolatey = @{
                                packages = @(
                                    @{ name = "git"; version = "2.0.0" }
                                    @{ name = "nodejs"; version = "18.0.0" }
                                )
                            }
                        }
                        commands = @()
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When dependencies have only modules" {
        It "Should display modules table correctly" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        configuration = @{
                            description = "Test"
                            version = "1.0"
                            createdBy = "Test"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{ name = "Windows" }
                        }
                        dependencies = @{
                            powershell = @{
                                modules = @(
                                    @{ name = "PSScriptAnalyzer"; minimumVersion = "1.0.0" }
                                )
                            }
                        }
                        commands = @()
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When dependencies have mixed packages and modules" {
        It "Should display all items with correct colors" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        configuration = @{
                            description = "Test"
                            version = "1.0"
                            createdBy = "Test"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{ name = "Windows" }
                        }
                        dependencies = @{
                            chocolatey = @{
                                packages = @(@{ name = "git"; version = "2.0.0" })
                            }
                            powershell = @{
                                modules = @(@{ name = "PSScriptAnalyzer"; minimumVersion = "1.0.0" })
                            }
                            scoop = @{
                                packages = @(@{ name = "curl"; version = "1.0.0" })
                            }
                            homebrew = @{
                                packages = @(@{ name = "wget"; version = "1.0.0" })
                            }
                        }
                        commands = @(@{ name = "test command" })
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When dependencies have unknown package manager" {
        It "Should use default color (DarkGray) for unknown managers" {
            Mock Read-DevSetupEnvFile {
                return @{
                    devsetup = @{
                        configuration = @{
                            description = "Test"
                            version = "1.0"
                            createdBy = "Test"
                            createdDate = "2023-01-01"
                            lastUpdatedDate = "2023-01-02"
                            os = @{ name = "Windows" }
                        }
                        dependencies = @{
                            unknownmanager = @{
                                packages = @(@{ name = "unknown-package"; version = "1.0.0" })
                            }
                            anotherUnknown = @{
                                packages = @(@{ name = "another-package"; version = "2.0.0" })
                            }
                        }
                        commands = @()
                    }
                }
            }
            Mock Format-PrettyTable { param($Rows) 
                # Verify that unknown managers get DarkGray color
                $unknownPackages = $Rows | Where-Object { $_.Provider -in @("unknownmanager", "anotherUnknown") }
                if ($unknownPackages) {
                    foreach ($pkg in $unknownPackages) {
                        if ($pkg.Color -ne "DarkGray") {
                            throw "Expected unknown package manager to have DarkGray color, got $($pkg.Color)"
                        }
                    }
                }
            }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
        }
    }

    Context "When name is empty string" {
        It "Should throw due to parameter validation" {
            { Show-ExplainDevSetupEnv -Name "" } | Should -Throw
        }
    }

    Context "When path is empty string" {
        It "Should throw due to parameter validation" {
            { Show-ExplainDevSetupEnv -Path "" } | Should -Throw
        }
    }

    Context "When neither name nor path is provided" {
        It "Should throw due to parameter set requirements" {
            { Show-ExplainDevSetupEnv } | Should -Throw
        }
    }

    Context "When both name and path are provided" {
        It "Should throw due to parameter set conflict" {
            { Show-ExplainDevSetupEnv -Name "test" -Path "test.devsetup" } | Should -Throw
        }
    }

    Context "When Get-DevSetupEnvPath throws exception" {
        It "Should handle gracefully" {
            Mock Get-DevSetupEnvPath { throw "Path error" }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "When Test-Path throws exception" {
        It "Should handle gracefully" {
            Mock Test-Path { throw "Path test error" }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "When Format-PrettyTable throws exception" {
        It "Should continue execution" {
            Mock Format-PrettyTable { throw "Table format error" }
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 1 -Scope It
        }
    }

    Context "When second Format-PrettyTable throws exception" {
        BeforeEach {
            $script:callCount = 0;
            Mock Format-PrettyTable {
                switch ($script:callCount) {
                    0 { 
                        $script:callCount++
                        return $true
                    }
                    1 {
                        throw "Table format error"
                    }
                    default { 
                        return
                    }
                }
            }
        }
        It "Should continue execution" {
            Show-ExplainDevSetupEnv -Name "testenv"
            Assert-MockCalled Format-PrettyTable -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to format" -and $Verbosity -eq "Error" }
        }
    }    
}
