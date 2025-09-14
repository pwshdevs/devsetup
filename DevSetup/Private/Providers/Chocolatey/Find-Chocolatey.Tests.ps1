BeforeAll {
    . $PSScriptRoot\Find-Chocolatey.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
}

Describe "Find-Chocolatey" {

    Context "When Chocolatey is found via Get-Command" {
        It "Should return the path from Get-Command when choco is in PATH" {
            $expectedPath = Join-Path $TestDrive "chocolatey" "bin" "choco.exe"
            Mock Get-Command { 
                return @{ Path = $expectedPath }
            } -ParameterFilter { $Name -eq "choco" }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Found Chocolatey at: $([regex]::Escape($expectedPath))" -and $Verbosity -eq "Debug" 
            }
        }
    }

    Context "When Get-Command fails but ChocolateyInstall environment variable exists" {
        It "Should return path from ChocolateyInstall environment variable" {
            $chocolateyInstallPath = Join-Path $TestDrive "Chocolatey"
            $expectedPath = Join-Path $chocolateyInstallPath "bin" "choco.exe"
            
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { 
                return $chocolateyInstallPath
            } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $expectedPath }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Found Chocolatey at: $([regex]::Escape($expectedPath))" -and $Verbosity -eq "Debug" 
            }
        }
    }

    Context "When ChocolateyInstall environment variable is not set" {
        It "Should return null and log debug message" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { return $null } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "ChocolateyInstall environment variable is not set." -and $Verbosity -eq "Debug" 
            }
        }
    }

    Context "When ChocolateyInstall path exists but choco.exe does not exist" {
        It "Should return null and log debug message about missing executable" {
            $chocolateyInstallPath = Join-Path $TestDrive "Chocolatey"
            $expectedPath = Join-Path $chocolateyInstallPath "bin" "choco.exe"
            
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { 
                return $chocolateyInstallPath
            } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $expectedPath }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "Chocolatey executable not found at expected path: $expectedPath" -and $Verbosity -eq "Debug" 
            }
        }
    }

    Context "When Get-Command throws an exception" {
        It "Should handle Get-Command exception and continue with environment variable lookup" {
            $chocolateyInstallPath = Join-Path $TestDrive "Chocolatey"
            $expectedPath = Join-Path $chocolateyInstallPath "bin" "choco.exe"
            
            Mock Get-Command { throw "Command not found error" } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { 
                return $chocolateyInstallPath
            } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $expectedPath }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error finding Chocolatey command:" -and $Verbosity -eq "Error" 
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Found Chocolatey at: $([regex]::Escape($expectedPath))" -and $Verbosity -eq "Debug" 
            }
        }
    }

    Context "When Get-EnvironmentVariable throws an exception" {
        It "Should handle Get-EnvironmentVariable exception and return null" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { throw "Environment variable access error" } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error retrieving ChocolateyInstall environment variable:" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Join-Path throws an exception" {
        It "Should handle Join-Path exception and return null" {
            $chocolateyInstallPath = "InvalidPath:"
            
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { 
                return $chocolateyInstallPath
            } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Join-Path { throw "Invalid path error" }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error constructing Chocolatey path:" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When all operations succeed via Get-Command" {
        It "Should not attempt environment variable lookup when Get-Command succeeds" {
            $expectedPath = Join-Path $TestDrive "chocolatey" "bin" "choco.exe"
            Mock Get-Command { 
                return @{ Path = $expectedPath }
            } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { throw "Should not be called" }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            $result | Should -Be $expectedPath
            Assert-MockCalled Get-EnvironmentVariable -Times 0 -Scope It
        }
    }

    Context "Integration scenarios" {
        It "Should return path when both methods would work but Get-Command takes precedence" {
            $commandPath = Join-Path $TestDrive "system" "choco.exe"
            $envInstallPath = Join-Path $TestDrive "custom" "chocolatey"
            $envPath = Join-Path $envInstallPath "bin" "choco.exe"
            
            Mock Get-Command { 
                return @{ Path = $commandPath }
            } -ParameterFilter { $Name -eq "choco" }
            Mock Get-EnvironmentVariable { 
                return $envInstallPath
            } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true }
            Mock Write-StatusMessage { }
            
            $result = Find-Chocolatey
            
            # Should return the Get-Command path, not the environment variable path
            $result | Should -Be $commandPath
            # Environment variable should not be called since Get-Command succeeded
            Assert-MockCalled Get-EnvironmentVariable -Times 0 -Scope It
        }
    }
}