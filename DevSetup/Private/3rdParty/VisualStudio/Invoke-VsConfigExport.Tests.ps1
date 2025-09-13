BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-VsConfigExport.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\Utils\Get-EnvironmentVariable.ps1")
    . (Join-Path $PSScriptRoot "Wait-ForVisualStudioConfigFile.ps1")
    Mock Write-StatusMessage { }
    Mock Get-EnvironmentVariable { "$TestDrive\UserProfile" }
    Mock Remove-Item { }
    Mock Invoke-Command {
        param($ScriptBlock)
        $script:LASTEXITCODE = 0
    }
    Mock Wait-ForVisualStudioConfigFile { $true }
    Mock Get-Content { "mocked config content" }
    Mock Test-Path {
        $true
    }
}

Describe "Invoke-VsConfigExport" {

    Context "When VS install path not found" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $false
                    }
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }
        It "Should return null and write error" {
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio installation path not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When user profile path not found" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    1 { 
                        $script:testPathCallCount++
                        return $false
                    }
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }
        It "Should return null and write error" {
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "User profile path not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When getting user profile fails" {        
        It "Should return null and write error" {
            Mock Get-EnvironmentVariable { throw "Env failed" }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get user profile path" -and $Verbosity -eq "Error" }
        }
    }

    Context "When removing temp config file fails" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            Mock Remove-Item { throw "Remove failed" }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to remove existing temporary config file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When setup command not found" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    1 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    2 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    3 { 
                        $script:testPathCallCount++
                        return $false 
                    }
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio setup command not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When setup command not found and test-path throws" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    1 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    2 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    3 { 
                        $script:testPathCallCount++
                        throw "Path error"
                    }
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }        
        }        
        It "Should return null and write error" {
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to verify Visual Studio setup command" -and $Verbosity -eq "Error" }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }    

    Context "When export command fails with non-zero exit code" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 1
            }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio configuration export failed with exit code" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Invoke-Command throws exception" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            Mock Invoke-Command { throw "Command failed" }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to run Visual Studio setup command" -and $Verbosity -eq "Error" }
        }
    }

    Context "When waiting for config file times out" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            Mock Wait-ForVisualStudioConfigFile { $false }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Timed out waiting for Visual Studio configuration export" -and $Verbosity -eq "Error" }
        }
    }

    Context "When temp config file not found after export" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    1 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    2 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    3 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    4 { 
                        $script:testPathCallCount++
                        return $false 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to export Visual Studio configuration to temporary file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When reading config file fails" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            Mock Get-Content { throw "Read failed" }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to read exported configuration file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When exported config is empty" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return null and write error" {
            Mock Get-Content { "" }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Exported Visual Studio configuration file is empty." -and $Verbosity -eq "Error" }
        }
    }

    Context "When export succeeds" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }        
        It "Should return config content and clean up" {
            Mock Invoke-Command {
                $script:LASTEXITCODE = 0
            }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            Assert-MockCalled Test-Path -Exactly 6 -Scope It  # for all path checks
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Result" -and $Verbosity -eq "Debug" }
            Assert-MockCalled Remove-Item -Exactly 2 -Scope It  # for temp file removal
            $result | Should -Be "mocked config content"
        }
    }

    Context "When cleanup fails" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    2 { 
                        $script:testPathCallCount++
                        return $false
                    }
                    default { 
                        $script:testPathCallCount++
                        return $true 
                    }
                }
            }            
        }       
        It "Should return config and write warning" {
            Mock Remove-Item { throw "Cleanup failed" }
            Mock Invoke-Command {
                $script:LASTEXITCODE = 0
            }            
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 6 -Scope It  # for all path checks
            Assert-MockCalled Remove-Item -Exactly 1 -Scope It  # for temp file removal
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to remove temporary config file" -and $Verbosity -eq "Warning" }
            $result | Should -Be "mocked config content"
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be "mocked config content"
        }

        It "Should fail on Linux" {
            Mock Test-Path { $false } -ParameterFilter { $Path -eq "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
        }

        It "Should fail on macOS" {
            Mock Test-Path { $false } -ParameterFilter { $Path -eq "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe" }
            $result = Invoke-VsConfigExport -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $null
        }
    }
}
