BeforeAll {
    Function Write-EZLog { }
    . (Join-Path $PSScriptRoot "Install-DevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Read-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupLocalEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Scoop\Install-ScoopComponents.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Chocolatey\Invoke-ChocolateyPackageInstall.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Powershell\Invoke-PowershellModulesInstall.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Providers\Homebrew\Invoke-HomebrewComponentsInstall.ps1")
    Mock Get-DevSetupEnvPath { "$TestDrive\DevSetup\DevSetupEnvs" }
    Mock Get-DevSetupLocalEnvPath { "$TestDrive\DevSetup\LocalEnvs" }
    Mock Test-Path { $true }
    Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
    Mock Invoke-PowershellModulesInstall { Param($YamlData, $DryRun) $true }
    Mock Invoke-ChocolateyPackageInstall { Param($YamlData) $true }
    Mock Install-ScoopComponents { Param($YamlData) $true }
    Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $true } }
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Write-StatusMessage { }
    Mock Write-EZLog { }
    Mock Invoke-HomebrewComponentsInstall { Param($YamlData, $DryRun) $true }
    Mock Invoke-WebRequest { }
    Mock Read-Host { "Y" }
    Mock Invoke-Command { }
}

Describe "Install-DevSetupEnv" {

    Context "When environment file does not exist for Name" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            $result = Install-DevSetupEnv -Name "missing-env"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When YAML parsing fails" {
        It "Should write error and return" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { $null }
            $result = Install-DevSetupEnv -Name "bad-yaml"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to parse YAML" -and $Verbosity -eq "Error" }
        }
    }

    Context "When all installers succeed on Windows" {
        It "Should call all Windows installers and write status" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $true } }
            $result = Install-DevSetupEnv -Name "basic-env"
            $result | Should -Be $null
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Installing DevSetup environment from:" }
        }
    }

    Context "When all installers succeed on non-Windows" {
        It "Should call Homebrew installer and write status" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Install-DevSetupEnv -Name "basic-env"
            $result | Should -Be $null
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 0 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 0 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Installing DevSetup environment from:" }
        }
    }

    Context "When a component installer fails" {
        It "Should continue calling other installers" {
            Mock Test-OperatingSystem { return $true }
            $script:callCount = 0
            Mock Invoke-PowershellModulesInstall { $script:callCount++; $false }
            Mock Invoke-ChocolateyPackageInstall { $script:callCount++; $true }
            Mock Install-ScoopComponents { $script:callCount++; $true }
            Mock Invoke-HomebrewComponentsInstall { $script:callCount++; $true }
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }

            $result = Install-DevSetupEnv -Name "partial-fail"
            Assert-MockCalled Test-OperatingSystem -Exactly 1 -Scope It -ParameterFilter { $Windows -eq $true }
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 0 -Scope It
            $result | Should -Be $null
            $script:callCount | Should -Be 3
        }
    }

    Context "When an exception occurs during install" {
        It "Should write error and return" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { throw "Unexpected error" }
            $result = Install-DevSetupEnv -Name "exception-env"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When using Path parameter with valid path" {
        It "Should use the provided path and install" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Install-DevSetupEnv -Path "$TestDrive\valid.yaml"
            $result | Should -Be $null
            Assert-MockCalled Test-Path -Exactly 2 -Scope It -ParameterFilter { $Path -eq "$TestDrive\valid.yaml" }
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It
        }
    }

    Context "When using Path parameter with invalid path" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            $result = Install-DevSetupEnv -Path "$TestDrive\invalid.yaml"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Invalid Path provided" -and $Verbosity -eq "Error" }
        }
    }

    Context "When using Url parameter and download succeeds" {
        BeforeEach {
            # Ensure the local file does not exist before the test
            $localPath = "$TestDrive\DevSetup\LocalEnvs\config.yaml"
            Remove-Item -Path $localPath -ErrorAction SilentlyContinue
        }

        It "Should download file and install" {
            $script:testPathCallCount = 0
            Mock Test-Path {
                $script:testPathCallCount++
                if ($script:testPathCallCount -eq 1) { return $false }  # File doesn't exist initially
                else { return $true }  # File exists after download
            }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            Mock Invoke-WebRequest { }
            $result = Install-DevSetupEnv -Url "https://example.com/config.yaml"
            $result | Should -Be $null
            Assert-MockCalled Test-Path -Exactly 2 -Scope It
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It
            Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It
        }
    }

    Context "When using Url parameter and file exists, user chooses to overwrite" {
        It "Should overwrite and install" {
            Mock Test-Path { $true }  # File exists
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            Mock Invoke-WebRequest { }
            Mock Read-Host { "Y" }
            $result = Install-DevSetupEnv -Url "https://example.com/config.yaml"
            $result | Should -Be $null
            Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
        }
    }

    Context "When using Url parameter and file exists, user chooses not to overwrite" {
        It "Should not download and return" {
            Mock Test-Path { $true }  # File exists
            Mock Read-Host { "N" }
            $result = Install-DevSetupEnv -Url "https://example.com/config.yaml"
            $result | Should -Be $null
            Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope It
        }
    }

    Context "When download fails" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            Mock Invoke-WebRequest { throw "Download failed" }
            $result = Install-DevSetupEnv -Url "https://example.com/config.yaml"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to download devsetup env file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Name includes provider" {
        It "Should parse provider and name correctly" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Install-DevSetupEnv -Name "custom:MyEnv"
            $result | Should -Be $null
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
        }
    }

    Context "When Name does not include provider" {
        It "Should default to local provider" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Install-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $null
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
        }
    }

    Context "When DryRun is specified on Windows" {
        It "Should pass DryRun to installers" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Install-DevSetupEnv -Name "dry-run-env" -DryRun
            $result | Should -Be $null
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 0 -Scope It
        }
    }

    Context "When DryRun is specified on non-Windows" {
        It "Should pass DryRun to Homebrew installer" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Install-DevSetupEnv -Name "dry-run-env" -DryRun
            $result | Should -Be $null
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 0 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 0 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
        }
    }

    Context "When commands are present in YAML" {
        It "Should execute commands" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "echo hello"; packageName = "test" }) } } }
            Mock Test-OperatingSystem { return $true }
            Mock Invoke-Command { }
            $result = Install-DevSetupEnv -Name "with-commands"
            $result | Should -Be $null
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Executing configuration commands" }
        }
    }

    Context "When commands are missing command property" {
        It "Should skip and warn" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ packageName = "test" }) } } }
            Mock Test-OperatingSystem { return $true }
            $result = Install-DevSetupEnv -Name "missing-command"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Skipping command entry with missing command property" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When no commands are present" {
        It "Should write no commands message" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Install-DevSetupEnv -Name "no-commands"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "No commands found in configuration to execute" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $true }
            $result = Install-DevSetupEnv -Name "win-env"
            $result | Should -Be $null
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It
        }

        It "Should work on Linux" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Install-DevSetupEnv -Name "linux-env"
            $result | Should -Be $null
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 1 -Scope It
        }

        It "Should work on macOS" {
            Mock Test-Path { $true }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
            Mock Test-OperatingSystem { return $false }
            $result = Install-DevSetupEnv -Name "mac-env"
            $result | Should -Be $null
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 1 -Scope It
        }
    }
}