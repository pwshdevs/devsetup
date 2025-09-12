BeforeAll {
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
    Mock Write-StatusMessage { }
    Mock Get-DevSetupEnvPath { Join-Path $TestDrive "DevSetup" | Join-Path -ChildPath "DevSetupEnvs" }
    Mock Get-DevSetupLocalEnvPath { Join-Path $TestDrive "DevSetup" | Join-Path -ChildPath "LocalEnvs" }
    Mock Test-Path { $true }
    Mock Read-DevSetupEnvFile { @{ devsetup = @{ } } }
    Mock Invoke-PowershellModulesInstall { }
    Mock Invoke-ChocolateyPackageInstall { }
    Mock Install-ScoopComponents { }
    Mock Invoke-HomebrewComponentsInstall { }
    Mock Test-OperatingSystem { $true }
    Mock Invoke-WebRequest { }
    Mock Read-Host { "Y" }
    $Script:LASTEXITCODE = 0
    Mock Invoke-Command { $script:LASTEXITCODE = 0 }
}

Describe "Install-DevSetupEnv" {

    Context "Basic Name parameter usage" {
        It "Should handle simple environment name correctly" {
            $expectedPath = Join-Path (Join-Path $TestDrive "DevSetup" | Join-Path -ChildPath "DevSetupEnvs") "local" | Join-Path -ChildPath "myenv.devsetup"
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $expectedPath }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $Config -eq $expectedPath }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Installing DevSetup environment from:" -and $ForegroundColor -eq "Cyan" }
        }
    }

    Context "Provider parsing in Name parameter" {
        It "Should correctly parse provider from name with colon" {
            $expectedPath = Join-Path (Join-Path $TestDrive "DevSetup" | Join-Path -ChildPath "DevSetupEnvs") "github" | Join-Path -ChildPath "myenv.devsetup"
            Install-DevSetupEnv -Name "github:myenv"
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $expectedPath }
        }
    }

    Context "Complex provider names" {
        It "Should handle multiple colons in provider name" {
            $expectedPath = Join-Path (Join-Path $TestDrive "DevSetup" | Join-Path -ChildPath "DevSetupEnvs") "github" | Join-Path -ChildPath "org.devsetup"
            Install-DevSetupEnv -Name "github:org:repo:myenv"
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq $expectedPath }
        }
    }

    Context "Path resolution failures" {
        It "Should handle Get-DevSetupEnvPath exceptions gracefully" {
            Mock Get-DevSetupEnvPath { throw "Path resolution failed" }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get environment path" -and $Verbosity -eq "Error" }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "Direct path specification" {
        BeforeEach {
            $script:callCount = 0
            Mock Test-Path { 
                switch($script:callCount) {
                    0 { $script:callCount++; return $true }
                    1 { $script:callCount++; return $true }
                    default { $script:callCount++; return $true }
                }
            }
        }
        It "Should accept and validate custom file paths" {
            $testPath = Join-Path $TestDrive "custom" | Join-Path -ChildPath "path" | Join-Path -ChildPath "config.devsetup"
            Install-DevSetupEnv -Path $testPath
            Assert-MockCalled Test-Path -Exactly 2 -Scope It
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $Config -eq $testPath }
        }
    }

    Context "Invalid path handling" {
        It "Should report error for non-existent paths" {
            $testPath = Join-Path $TestDrive "missing.devsetup"
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $testPath }
            Install-DevSetupEnv -Path $testPath
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Invalid Path provided" -and $Verbosity -eq "Error" }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "URL validation" {
        It "Should reject URLs not pointing to .devsetup files" {
            Install-DevSetupEnv -Url "https://example.com/config.json"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "URL must point to a .devsetup file" -and $Verbosity -eq "Error" }
            Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope It
        }
    }

    Context "URL download scenarios" {
        It "Should download new files from valid URLs" {
            $expectedPath = Join-Path (Join-Path $TestDrive "DevSetup" | Join-Path -ChildPath "LocalEnvs") "remote.devsetup"
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $expectedPath }
            Install-DevSetupEnv -Url "https://example.com/remote.devsetup"
            Assert-MockCalled Get-DevSetupLocalEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope It -ParameterFilter { $Uri -eq "https://example.com/remote.devsetup" -and $OutFile -eq $expectedPath }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Downloading DevSetup environment from:" -and $ForegroundColor -eq "Cyan" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Saving Devsetup environment file to:" -and $ForegroundColor -eq "Cyan" }
        }
    }

    Context "File overwrite prompts" {
        BeforeEach {
            $script:callCount = 0
            Mock Test-Path { 
                switch($script:callCount) {
                    0 { $script:callCount++; return $true }
                    1 { $script:callCount++; return $true }
                    default { $script:callCount++; return $true }
                }
            }
        }        
        It "Should handle user confirmation for overwriting existing files" {
            Mock Read-Host { "Y" }
            Install-DevSetupEnv -Url "https://example.com/existing.devsetup"
            Assert-MockCalled Read-Host -Exactly 1 -Scope It
            Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope It
        }
    }

    Context "User decline overwrite" {
        It "Should respect user choice to not overwrite files" {
            $expectedPath = Join-Path (Join-Path $TestDrive "DevSetup" | Join-Path -ChildPath "LocalEnvs") "existing.devsetup"
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $expectedPath }
            Mock Read-Host { "N" }
            Install-DevSetupEnv -Url "https://example.com/existing.devsetup"
            Assert-MockCalled Read-Host -Exactly 1 -Scope It
            Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope It
        }
    }

    Context "Download failures" {
        It "Should handle network errors during download" {
            Mock Test-Path { $false }
            Mock Invoke-WebRequest { throw "Network connection failed" }
            Install-DevSetupEnv -Url "https://example.com/config.devsetup"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to download devsetup env file" -and $Verbosity -eq "Error" }
        }
    }

    Context "Local path resolution errors" {
        It "Should handle Get-DevSetupLocalEnvPath failures" {
            Mock Get-DevSetupLocalEnvPath { throw "Local path resolution error" }
            Install-DevSetupEnv -Url "https://example.com/config.devsetup"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get environment path" -and $Verbosity -eq "Error" }
        }
    }

    Context "Missing environment files" {
        It "Should detect and report missing .devsetup files" {
            Mock Test-Path { $false } -ParameterFilter { $Path -match "\.devsetup$" }
            Install-DevSetupEnv -Name "missing"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file not found" -and $Verbosity -eq "Error" }
            Assert-MockCalled Read-DevSetupEnvFile -Exactly 0 -Scope It
        }
    }

    Context "YAML parsing errors" {
        It "Should handle Read-DevSetupEnvFile exceptions" {
            Mock Read-DevSetupEnvFile { throw "YAML syntax error" }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to read or parse environment file" -and $Verbosity -eq "Error" }
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 0 -Scope It
        }
    }

    Context "Invalid YAML content" {
        It "Should detect null return from Read-DevSetupEnvFile" {
            Mock Read-DevSetupEnvFile { $null }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to parse YAML configuration" -and $Verbosity -eq "Error" }
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 0 -Scope It
        }
    }

    Context "PowerShell module installation failures" {
        It "Should handle Invoke-PowershellModulesInstall exceptions" {
            Mock Invoke-PowershellModulesInstall { throw "Module installation failed" }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "An error occurred during PowerShell module installation" -and $Verbosity -eq "Error" }
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 0 -Scope It
        }
    }

    Context "Windows platform detection" {
        It "Should invoke Windows-specific package managers on Windows" {
            Mock Test-OperatingSystem { $true }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 0 -Scope It
        }
    }

    Context "Non-Windows platform detection" {
        It "Should invoke Homebrew on non-Windows platforms" {
            Mock Test-OperatingSystem { $false } -ParameterFilter { $Windows }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 0 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 0 -Scope It
            Assert-MockCalled Invoke-HomebrewComponentsInstall -Exactly 1 -Scope It
        }
    }

    Context "Chocolatey installation failures" {
        It "Should handle Invoke-ChocolateyPackageInstall exceptions" {
            Mock Invoke-ChocolateyPackageInstall { throw "Chocolatey installation error" }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "An error occurred during Chocolatey package installation" -and $Verbosity -eq "Error" }
            Assert-MockCalled Install-ScoopComponents -Exactly 0 -Scope It
        }
    }

    Context "Scoop installation failures" {
        It "Should handle Install-ScoopComponents exceptions" {
            Mock Install-ScoopComponents { throw "Scoop installation error" }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "An error occurred during Scoop component installation" -and $Verbosity -eq "Error" }
        }
    }

    Context "Homebrew installation failures" {
        It "Should handle Invoke-HomebrewComponentsInstall exceptions" {
            Mock Test-OperatingSystem { $false } -ParameterFilter { $Windows }
            Mock Invoke-HomebrewComponentsInstall { throw "Homebrew installation error" }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "An error occurred during Homebrew component installation" -and $Verbosity -eq "Error" }
        }
    }

    Context "Dry run mode" {
        It "Should propagate DryRun flag to all installation functions" {
            Install-DevSetupEnv -Name "myenv" -DryRun
            Assert-MockCalled Invoke-PowershellModulesInstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
            Assert-MockCalled Invoke-ChocolateyPackageInstall -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
        }
    }

    Context "Simple command execution" {
        BeforeEach {
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ commands = @(@{ command = "echo 'Hello World'"; packageName = "greeter" }) } } }
        }
        It "Should execute commands without parameters" {
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Executing configuration commands" -and $ForegroundColor -eq "Cyan" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Executing command for: greeter" -and $ForegroundColor -eq "Gray" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command completed successfully" -and $Verbosity -eq "Verbose" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command greeter completed successfully" }
        }
    } 

    Context "Simple command execution" {
        BeforeEach {
            $script:LASTEXITCODE = 1
            Mock Invoke-Command { $script:LASTEXITCODE = 1; return "Simulated command failure" }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ commands = @(@{ command = "echo 'Hello World'"; packageName = "greeter" }) } } }
        }
        It "Should execute commands without parameters and write error and continue when command returns non-zero exit code" {
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command failed with exit code" -and $Verbosity -eq "Error" }
        }
    }
    
    Context "Simple command execution" {
        BeforeEach {
            Mock Invoke-Command { throw "Simulated command failure" }
            Mock Read-DevSetupEnvFile { return @{ devsetup = @{ commands = @(@{ command = "echo 'Hello World'"; packageName = "greeter" }) } } }
        }
        It "Should write status and continue when command throws exception" {
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command execution failed" -and $Verbosity -eq "Error" }
        }
    }    

    Context "Command execution with hashtable parameters" {
        It "Should handle commands with hashtable parameter objects" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "setup.exe"; packageName = "installer"; params = @{ arg1 = "value1"; arg2 = "value2" } }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Parameter: arg1 = value1" -and $Verbosity -eq "Debug" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Parameter: arg2 = value2" -and $Verbosity -eq "Debug" }
        }
    }

    Context "Command execution with PSCustomObject parameters" {
        It "Should handle commands with PSCustomObject parameter objects" {
            $paramsObj = [PSCustomObject]@{ setting1 = "config1"; setting2 = "config2" }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "configure.exe"; packageName = "config"; params = $paramsObj }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Parameter: setting1 = config1" -and $Verbosity -eq "Debug" }
        }
    }

    Context "Successful command execution" {
        It "Should report successful command completion" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "successful.exe"; packageName = "success" }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command completed successfully" -and $Verbosity -eq "Verbose" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command success completed successfully" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "Command execution with exit code failure" {
        It "Should detect and report non-zero exit codes" {
            Mock Invoke-Command { $script:LASTEXITCODE = 2; return "Command failed with error" }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "failing.exe"; packageName = "failure" }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command failed with exit code 2" -and $Verbosity -eq "Error" }
        }
    }

    Context "Command execution with exit code failure and params" {
        It "Should detect and report non-zero exit codes" {
            Mock Invoke-Command { $script:LASTEXITCODE = 2; return "Command failed with error" }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "failing.exe"; packageName = "failure"; params = @{ arg1 = "value1"; arg2 = "value2" } }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command failed with exit code 2" -and $Verbosity -eq "Error" }
        }
    }    

    Context "Command execution exceptions" {
        It "Should handle Invoke-Command exceptions" {
            Mock Invoke-Command { throw "Command execution error" }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "error.exe"; packageName = "error" }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command execution error" -and $Verbosity -eq "Error" }
        }
    }

    Context "Command execution exceptions with params" {
        It "Should handle Invoke-Command exceptions" {
            Mock Invoke-Command { throw "Command execution error" }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ command = "error.exe"; packageName = "error"; params = @{ setting1 = "value1"; setting2 = "value2" } }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Command execution error" -and $Verbosity -eq "Error" }
        }
    }    

    Context "Invalid command entries" {
        It "Should skip commands missing the command property" {
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ commands = @(@{ packageName = "invalid" }) } } }
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Skipping command entry with missing command property" -and $Verbosity -eq "Warning" }
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
    }

    Context "Empty command configurations" {
        It "Should handle configurations with no commands" {
            Install-DevSetupEnv -Name "myenv"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "No commands found in configuration to execute" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "Parameter validation - empty Name" {
        It "Should reject empty Name parameter" {
            { Install-DevSetupEnv -Name "" } | Should -Throw
        }
    }

    Context "Parameter validation - empty Path" {
        It "Should reject empty Path parameter" {
            { Install-DevSetupEnv -Path "" } | Should -Throw
        }
    }

    Context "Parameter validation - empty Url" {
        It "Should reject empty Url parameter" {
            { Install-DevSetupEnv -Url "" } | Should -Throw
        }
    }

    Context "Parameter validation - no parameters" {
        It "Should require at least one parameter set" {
            { Install-DevSetupEnv } | Should -Throw
        }
    }

    Context "Parameter validation - conflicting parameters" {
        It "Should reject multiple parameter sets" {
            { Install-DevSetupEnv -Name "test" -Path "test.devsetup" } | Should -Throw
        }
    }
}