BeforeAll {
    . $PSScriptRoot\Get-ChocolateyVersion.ps1
    . $PSScriptRoot\..\..\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    . $PSScriptRoot\Find-Chocolatey.ps1
}

Describe "Get-ChocolateyVersion" {
    Context "When Chocolatey is not installed" {
        It "Should return null and log warning when Test-ChocolateyInstalled returns false" {
            # Arrange
            Mock Test-ChocolateyInstalled { return $false }
            Mock Write-StatusMessage { }
            Mock Find-Chocolatey { }
            Mock Invoke-Command { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Chocolatey is not installed. Cannot retrieve version." -and $Verbosity -eq "Warning" 
            }
            Assert-MockCalled Find-Chocolatey -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
        
        It "Should return null and log error when Test-ChocolateyInstalled throws exception" {
            # Arrange
            Mock Test-ChocolateyInstalled { throw "Test error from Test-ChocolateyInstalled" }
            Mock Write-StatusMessage { }
            Mock Find-Chocolatey { }
            Mock Invoke-Command { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Error checking if Chocolatey is installed:*" -and $Verbosity -eq "Error" 
            } -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" 
            } -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
    }
    
    Context "When Find-Chocolatey fails" {
        It "Should return null and log error when Find-Chocolatey throws exception" {
            # Arrange
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { throw "Find-Chocolatey error" }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { }
            Mock Test-Path { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Error locating Chocolatey command:*" -and $Verbosity -eq "Error" 
            } -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" 
            } -Scope It
            Assert-MockCalled Test-Path -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
        
        It "Should return null and log warning when Find-Chocolatey returns null" {
            # Arrange
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $null }
            Mock Write-StatusMessage { }
            Mock Test-Path { }
            Mock Invoke-Command { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Could not find Chocolatey command. Cannot retrieve version." -and $Verbosity -eq "Warning" 
            }
            Assert-MockCalled Test-Path -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
        
        It "Should return null and log warning when Find-Chocolatey returns empty string" {
            # Arrange
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "" }
            Mock Write-StatusMessage { }
            Mock Test-Path { }
            Mock Invoke-Command { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Could not find Chocolatey command. Cannot retrieve version." -and $Verbosity -eq "Warning" 
            }
            Assert-MockCalled Test-Path -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
        
        It "Should return null and log warning when Find-Chocolatey returns whitespace" {
            # Arrange
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "   " }
            Mock Write-StatusMessage { }
            Mock Test-Path { }
            Mock Invoke-Command { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Could not find Chocolatey command. Cannot retrieve version." -and $Verbosity -eq "Warning" 
            }
            Assert-MockCalled Test-Path -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
        
        It "Should return null and log warning when choco command path does not exist" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "nonexistent\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Write-StatusMessage { }
            Mock Test-Path { return $false }
            Mock Invoke-Command { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $testChocoPath
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Chocolatey command path '$testChocoPath' does not exist. Cannot retrieve version." -and $Verbosity -eq "Warning" 
            }
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
        
        It "Should return null and log error when Test-Path throws exception" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "problematic\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Write-StatusMessage { }
            Mock Test-Path { throw "Test-Path access denied" }
            Mock Invoke-Command { }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $testChocoPath
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Error verifying Chocolatey command path:*" -and $Verbosity -eq "Error" 
            } -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" 
            } -Scope It
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
        }
    }
    
    Context "When version retrieval succeeds" {
        It "Should return version string when Invoke-Command succeeds with version output and exit code 0" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "1.4.0" 
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -Be "1.4.0"
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $testChocoPath
            }
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It -ParameterFilter {
                $ScriptBlock.ToString() -match "--version"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It
        }
        
        It "Should return version string with whitespace when output has whitespace and exit code 0" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "chocolatey\bin\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("  1.4.0`r`n  ") # Return as array with complex whitespace
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -Be "  1.4.0`r`n  "
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It
        }
        
        It "Should handle different version formats correctly when exit code 0" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "custom\path\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "2.1.0-beta1" 
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -Be "2.1.0-beta1"
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It
        }
        
        It "Should return version string with complex whitespace as-is" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "program files\chocolatey\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                # Create a string with multiple types of whitespace
                $whiteSpaceString = "`t`r`n  1.5.0  `r`n`t"
                return $whiteSpaceString
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -Be "`t`r`n  1.5.0  `r`n`t"
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It
        }
    }
    
    Context "When version retrieval fails" {
        It "Should return null and log warning when Invoke-Command returns empty output" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "empty\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $null 
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Failed to retrieve Chocolatey version." -and $Verbosity -eq "Warning" 
            }
        }
        
        It "Should return null and log warning when Invoke-Command returns empty string" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "chocolatey\tools\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "" 
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Failed to retrieve Chocolatey version." -and $Verbosity -eq "Warning" 
            }
        }
        
        It "Should return null and log warning when LASTEXITCODE is not 0" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "error\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 1
                return "Some error output" 
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Failed to retrieve Chocolatey version." -and $Verbosity -eq "Warning" 
            }
        }
        
        It "Should return null and log warning when LASTEXITCODE is not 0 and output is empty" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "failed\path\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 2
                return $null 
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Failed to retrieve Chocolatey version." -and $Verbosity -eq "Warning" 
            }
        }
        
        It "Should return null and log error when Invoke-Command throws exception" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "error\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { throw "Command execution failed" }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "An error occurred while trying to get Chocolatey version:*" -and $Verbosity -eq "Error" 
            } -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" 
            } -Scope It
        }
    }
    
    Context "Integration scenarios" {
        It "Should use the correct chocolatey path from Find-Chocolatey" {
            # Arrange
            $customChocoPath = Join-Path $TestDrive "Custom\Path\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $customChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "1.4.0" 
            } -Verifiable -ParameterFilter {
                $ScriptBlock.ToString() -match "--version" -and $ScriptBlock.ToString() -match "\`$chocoCommand"
            }
            
            # Act
            $result = Get-ChocolateyVersion

            # Assert
            $result | Should -Be "1.4.0"
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $customChocoPath
            }
            Assert-VerifiableMock
        }
        
        It "Should suppress stderr output from chocolatey command" {
            # Arrange
            $testChocoPath = Join-Path $TestDrive "bin\choco"
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $testChocoPath }
            Mock Test-Path { return $true }
            Mock Write-StatusMessage { }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "1.4.0" 
            }
            
            # Act
            $result = Get-ChocolateyVersion
            
            # Assert
            $result | Should -Be "1.4.0"
            Assert-MockCalled Test-ChocolateyInstalled -Exactly 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
        }
    }
}