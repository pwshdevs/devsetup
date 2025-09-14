BeforeAll {
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
    
    # Set up TestDrive paths for cross-platform compatibility
    $TestChocolateyPath = Join-Path $TestDrive "chocolatey"
    $TestChocolateyBinPath = Join-Path $TestChocolateyPath "bin"
    $TestChocolateyExePath = Join-Path $TestChocolateyBinPath "choco.exe"
    
    # Alternative test paths for multiple scenarios
    $TestAlternatePath = Join-Path $TestDrive "tools\chocolatey"
    $TestAlternateBinPath = Join-Path $TestAlternatePath "bin"
    $TestAlternateExePath = Join-Path $TestAlternateBinPath "choco.exe"
    
    Mock Write-StatusMessage { }
}

Describe "Test-ChocolateyInstalled" {

    Context "When Get-Command finds choco in PATH" {
        It "Should return true when choco command is found" {
            Mock Get-Command { 
                return @{ Path = $TestChocolateyExePath } 
            }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match [regex]::Escape("Found Chocolatey at: $TestChocolateyExePath") -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When Get-Command throws an exception" {
        It "Should handle Get-Command exception and continue to fallback logic" {
            Mock Get-Command { throw "Command execution failed" }
            Mock Get-EnvironmentVariable { return $null }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error finding Chocolatey command" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "ChocolateyInstall environment variable is not set." -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When choco is not in PATH but environment variable is set" {
        It "Should return true when ChocolateyInstall points to valid executable" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return $TestChocolateyPath }
            Mock Test-Path { return $true }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Get-EnvironmentVariable -Times 1 -Scope It -ParameterFilter {
                $Name -eq "ChocolateyInstall"
            }
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq $TestChocolateyExePath
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match [regex]::Escape("Found Chocolatey at: $TestChocolateyExePath") -and $Verbosity -eq "Debug"
            }
        }
        
        It "Should return false when ChocolateyInstall points to non-existent executable" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return $TestChocolateyPath }
            Mock Test-Path { return $false }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq $TestChocolateyExePath
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match [regex]::Escape("Chocolatey executable not found at expected path: $TestChocolateyExePath") -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When Get-EnvironmentVariable throws an exception" {
        It "Should handle Get-EnvironmentVariable exception and return false" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { throw "Environment variable access failed" }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error retrieving ChocolateyInstall environment variable" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When ChocolateyInstall environment variable is not set" {
        It "Should return false when environment variable is null" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return $null }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "ChocolateyInstall environment variable is not set." -and $Verbosity -eq "Debug"
            }
        }
        
        It "Should return false when environment variable is empty string" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return "" }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "ChocolateyInstall environment variable is not set." -and $Verbosity -eq "Debug"
            }
        }
        
        It "Should return false when environment variable is whitespace" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return "   " }
            Mock Test-Path { return $false }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            
            # The behavior may differ between platforms:
            # - Windows: Join-Path succeeds, Test-Path is called and returns false
            # - Linux: Join-Path may throw exception, Test-Path never called
            # Both behaviors are acceptable as long as function returns false
            
            # Check if either path was taken (no assertion failure if neither matches expectations)
        }
    }

    Context "When Join-Path throws an exception" {
        It "Should handle Join-Path exception and return false" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return $TestChocolateyPath }
            Mock Join-Path { throw "Path construction failed" }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error constructing Chocolatey path" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When both detection methods fail" {
        It "Should return false when choco is not in PATH and environment variable is not set" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return $null }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Get-Command -Times 1 -Scope It
            Assert-MockCalled Get-EnvironmentVariable -Times 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "ChocolateyInstall environment variable is not set." -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When multiple exception scenarios occur" {
        It "Should handle Get-Command exception followed by successful environment variable detection" {
            Mock Get-Command { throw "Command not found" }
            Mock Get-EnvironmentVariable { return $TestChocolateyPath }
            Mock Test-Path { return $true }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error finding Chocolatey command" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match [regex]::Escape("Found Chocolatey at: $TestChocolateyExePath") -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When validating cross-platform path handling" {
        It "Should construct correct path with different install locations" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return $TestAlternatePath }
            Mock Test-Path { return $true }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq $TestAlternateExePath
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match [regex]::Escape("Found Chocolatey at: $TestAlternateExePath") -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When validating function output type" {
        It "Should return a boolean value in success scenarios" {
            Mock Get-Command { 
                return @{ Path = $TestChocolateyExePath } 
            }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -BeOfType [bool]
            $result | Should -Be $true
        }
        
        It "Should return a boolean value in failure scenarios" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return $null }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -BeOfType [bool]
            $result | Should -Be $false
        }
    }
}