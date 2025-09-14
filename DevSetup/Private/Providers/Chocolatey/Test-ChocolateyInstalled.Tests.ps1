BeforeAll {
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
    
    Mock Write-StatusMessage { }
}

Describe "Test-ChocolateyInstalled" {

    Context "When Get-Command finds choco in PATH" {
        It "Should return true when choco command is found" {
            Mock Get-Command { 
                return @{ Path = "C:\ProgramData\chocolatey\bin\choco.exe" } 
            }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found Chocolatey at: C:\\ProgramData\\chocolatey\\bin\\choco\.exe" -and $Verbosity -eq "Debug"
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
            Mock Get-EnvironmentVariable { return "C:\ProgramData\chocolatey" }
            Mock Test-Path { return $true }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Get-EnvironmentVariable -Times 1 -Scope It -ParameterFilter {
                $Name -eq "ChocolateyInstall"
            }
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq "C:\ProgramData\chocolatey\bin\choco.exe"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found Chocolatey at: C:\\ProgramData\\chocolatey\\bin\\choco\.exe" -and $Verbosity -eq "Debug"
            }
        }
        
        It "Should return false when ChocolateyInstall points to non-existent executable" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return "C:\ProgramData\chocolatey" }
            Mock Test-Path { return $false }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $false
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq "C:\ProgramData\chocolatey\bin\choco.exe"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey executable not found at expected path: C:\\ProgramData\\chocolatey\\bin\\choco\.exe" -and $Verbosity -eq "Debug"
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
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq "   \bin\choco.exe"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey executable not found at expected path:    \\bin\\choco\.exe" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When Join-Path throws an exception" {
        It "Should handle Join-Path exception and return false" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return "C:\ProgramData\chocolatey" }
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
            Mock Get-EnvironmentVariable { return "C:\ProgramData\chocolatey" }
            Mock Test-Path { return $true }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error finding Chocolatey command" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found Chocolatey at: C:\\ProgramData\\chocolatey\\bin\\choco\.exe" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When validating cross-platform path handling" {
        It "Should construct correct path with different install locations" {
            Mock Get-Command { return $null }
            Mock Get-EnvironmentVariable { return "D:\Tools\Chocolatey" }
            Mock Test-Path { return $true }
            
            $result = Test-ChocolateyInstalled
            
            $result | Should -Be $true
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq "D:\Tools\Chocolatey\bin\choco.exe"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Found Chocolatey at: D:\\Tools\\Chocolatey\\bin\\choco\.exe" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When validating function output type" {
        It "Should return a boolean value in success scenarios" {
            Mock Get-Command { 
                return @{ Path = "C:\ProgramData\chocolatey\bin\choco.exe" } 
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