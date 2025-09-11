BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-VsConfigImport.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Get-EnvironmentVariable.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Get-PwshVersion.ps1")
    Mock Write-StatusMessage { }
    Mock Get-EnvironmentVariable { "$TestDrive\Users\TestUser" }
    Mock Remove-Item { }
    Mock Out-File { }
    Mock Invoke-Command {
        param($ScriptBlock)
        $script:LASTEXITCODE = 0
    }
    Mock Get-PwshVersion { @{ Major = 6; Minor = 2; Patch = 0 } }
}

Describe "Invoke-VsConfigImport" {

    Context "When config is empty" {
        It "Should throw when config is empty" {
            { Invoke-VsConfigImport -Config "" -VsInstallPath "$TestDrive\VS" } | Should -Throw
        }
    }

    Context "When user profile path not found" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $false
                    }
                    1 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    2 { 
                        $script:testPathCallCount++
                        return $true 
                    }
                    default { 
                        return $false 
                    }
                }
            }            
        }
        It "Should return false and write error" {
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
                    default { 
                        return $false 
                    }
                }
            }            
        }        
        It "Should return false and write error" {
            Mock Remove-Item { throw "Remove failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to create config file path" -and $Verbosity -eq "Error" }
        }
    }

    Context "When writing config to file fails on psv6+" {
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
                    default { 
                        return $false 
                    }
                }
            }            
        }        
        It "Should return false and write error" {
            Mock Out-File { throw "Write failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to write configuration to file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When writing config to file on psv5 fails" {
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
                    default { 
                        return $false 
                    }
                }
            }            
        } 
        Mock Get-PwshVersion { @{ Major = 5; Minor = 1; Patch = 0 } }       
        It "Should return false and write error" {
            Mock Out-File { throw "Write failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to write configuration to file" -and $Verbosity -eq "Error" }
        }
    }    

    Context "When VS install path not found" {
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
                        return $false 
                    }
                    3 { 
                        $script:testPathCallCount++
                        return $false 
                    }
                }
            }            
        }        
        It "Should return false and write error" {
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio installation path not found" -and $Verbosity -eq "Error" }
        }
    }

    Context "When config file not found after writing" {
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
                }
            }            
        }         
        It "Should return false and write error" {
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Configuration file not found" -and $Verbosity -eq "Error" }
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
                        return $true
                    }
                    4 {
                        $script:testPathCallCount++
                        return $false
                    }
                }
            }            
        }         
        It "Should return false and write error" {
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio setup command not found" -and $Verbosity -eq "Error" }
        }
    }    

    Context "When installer succeeds" {
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
                        return $true
                    }
                }
            }            
        }         
        It "Should return true and write success messages" {
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $true
            Assert-MockCalled Out-File -Exactly 1 -Scope It -ParameterFilter { $Encoding -eq ([System.Text.Encoding]::UTF8) }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio configuration saved to" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Running Visual Studio installer..." -and $Verbosity -eq "Debug" }
        }
    }

    Context "When installer succeeds on psv5" {
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
                        return $true
                    }
                }
            }            
        }  
        Mock Get-PwshVersion { @{ Major = 5; Minor = 1; Patch = 0 } }       
        It "Should return true and write success messages" {
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $true
            Assert-MockCalled Out-File -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio configuration saved to" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Running Visual Studio installer..." -and $Verbosity -eq "Debug" }
        }
    }    

    Context "When installer fails with non-zero exit code" {
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
                        return $true
                    }
                }
            }            
        }         
        It "Should return false and write error" {
            Mock Invoke-Command {
                param($ScriptBlock)
                $script:LASTEXITCODE = 1
            }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Visual Studio configuration import failed with exit code" -and $Verbosity -eq "Error" }
        }
    }

    Context "When installer succeeds with zero exit code but no success message" {
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
                        return $true
                    }
                }
            }            
        }         
        It "Should return true" {
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
                        return $true
                    }
                }
            }            
        }         
        It "Should return true" {
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
                        return $true
                    }
                }
            }            
        }         
        It "Should return false and write error" {
            Mock Invoke-Command { throw "Command failed" }
            $result = Invoke-VsConfigImport -Config "test config" -VsInstallPath "$TestDrive\VS"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to process Visual Studio configuration" -and $Verbosity -eq "Error" }
        }
    }

    Context "When config is piped" {
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
                        return $true
                    }
                }
            }            
        }         
        It "Should accept pipeline input and return true" {
            $config = "test config"
            $result = ($config | Invoke-VsConfigImport -VsInstallPath "$TestDrive\VS")
            $result | Should -Be $true
        }
    }
}
