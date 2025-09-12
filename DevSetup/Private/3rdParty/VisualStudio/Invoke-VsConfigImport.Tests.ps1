BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-VsConfigImport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Get-EnvironmentVariable.ps1")
    Mock Write-StatusMessage { }
    Mock Get-EnvironmentVariable { "$TestDrive\Users\TestUser" }
    Mock Remove-Item { }
    Mock Set-Content { }
}

Describe "Invoke-VsConfigImport" {

    Context "When config is empty" {
        It "Should throw when config is empty" {
            { Invoke-VsConfigImport -Config "" -VsInstallPath "$TestDrive\VS" } | Should -Throw
        }
    }

    Context "When user profile path not found" {
        It "Should return false and write error" {
            Mock Test-Path { $false }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "User profile path not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When getting user profile fails" {
        It "Should return false and write error" {
            Mock Get-EnvironmentVariable { throw "Env failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get user profile path" -and $Verbosity -eq "Error" }
        }
    }

    Context "When config file removal fails" {
        It "Should return false and write error" {
            Mock Test-Path { $true }
            Mock Remove-Item { throw "Remove failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to create config file path" -and $Verbosity -eq "Error" }
        }
    }

    Context "When writing config to file fails on psv6+" {
        It "Should return false and write error" {
            Mock Test-Path { $true }
            Mock Set-Content { throw "Write failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to write configuration to file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When writing config to file on psv5 fails" {
        It "Should return false and write error" {
            Mock Test-Path { $true }
            Mock Set-Content { throw "Write failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to write configuration to file" -and $Verbosity -eq "Error" }
        }
    }    

    Context "When VS install path not found" {
        It "Should return false and write error" {
            Mock Test-Path { param($Path) 
                if ($Path -like "*TestUser*") { return $true }  # User profile exists
                if ($Path -like "*.vssconfig*") { return $true }  # Config file exists after writing  
                if ($Path -eq "$TestDrive\VS") { return $false }  # VS install path doesn't exist
                if ($Path -like "*setup.exe*") { return $true }  # Setup exists
                return $true
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio installation path not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When config file not found after writing" {
        It "Should return false and write error" {
            Mock Test-Path { param($Path) 
                if ($Path -like "*.vssconfig*") { 
                    return $false  # Config file doesn't exist after writing
                }
                if ($Path -like "*TestUser*" -and $Path -notlike "*.vssconfig*") { 
                    return $true  # User profile exists
                }
                if ($Path -eq "$TestDrive\VS") { 
                    return $true  # VS install path exists
                }
                if ($Path -like "*setup.exe*") { 
                    return $true  # Setup exists
                }
                return $true
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Configuration file not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When setup command not found" {
        It "Should return false and write error" {
            Mock Test-Path { param($Path) 
                if ($Path -like "*TestUser*") { return $true }  # User profile exists
                if ($Path -eq "$TestDrive\VS") { return $true }  # VS install path exists
                if ($Path -like "*.vssconfig*") { return $true }  # Config file exists
                if ($Path -like "*setup.exe*") { return $false }  # Setup command doesn't exist
                return $true
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio setup command not found" -and $Verbosity -eq "Error" }
        }
    }    

    Context "When installer succeeds" {
        It "Should return true and write success messages" {
            Mock Test-Path { $true }  # All paths exist
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 0
                return "Installation successful"
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $true
            Assert-MockCalled Set-Content -Exactly 1 -Scope It -ParameterFilter { $Path -like "*.vssconfig*" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio configuration saved to" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Running Visual Studio installer..." -and $Verbosity -eq "Debug" }
        }
    }

    Context "When installer succeeds on psv5" {
        It "Should return true and write success messages" {
            Mock Test-Path { $true }  # All paths exist
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 0
                return "Installation successful"
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $true
            Assert-MockCalled Set-Content -Exactly 1 -Scope It -ParameterFilter { $Path -like "*.vssconfig*" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio configuration saved to" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Running Visual Studio installer..." -and $Verbosity -eq "Debug" }
        }
    }    

    Context "When installer fails with non-zero exit code" {
        It "Should return false and write error" {
            Mock Test-Path { $true }  # All paths exist
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 1
                return "Installation failed"
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio configuration import failed with exit code" -and $Verbosity -eq "Error" }
        }
    }

    Context "When installer succeeds with zero exit code but no success message" {
        It "Should return true" {
            Mock Test-Path { $true }  # All paths exist
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 0
                return ""
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $true
        }
    }
    
    Context "When installer succeeds with zero exit code with success message" {
        It "Should return true" {
            Mock Test-Path { $true }  # All paths exist
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 0
                return "works"
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $true
        }
    }    

    Context "When Invoke-Command throws exception" {
        It "Should return false and write error" {
            Mock Test-Path { $true }  # All paths exist
            Mock Invoke-Command { throw "Command failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to process Visual Studio configuration" -and $Verbosity -eq "Error" }
        }
    }

    Context "When config is piped" {
        It "Should accept pipeline input and return true" {
            Mock Test-Path { $true }  # All paths exist
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 0
                return "Installation successful"
            }
            $config = "test config"
            $result = ($config | Invoke-VsConfigImport -VsInstallPath "$TestDrive\VS")
            $result | Should -Be $true
        }
    }
}
