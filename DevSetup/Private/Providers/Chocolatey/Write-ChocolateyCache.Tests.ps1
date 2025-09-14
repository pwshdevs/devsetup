BeforeAll {
    . $PSScriptRoot\Write-ChocolateyCache.ps1
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    . $PSScriptRoot\Get-ChocolateyCacheFile.ps1
    . $PSScriptRoot\Find-Chocolatey.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    
    Mock Write-StatusMessage { }
}

Describe "Write-ChocolateyCache" {

    Context "When Get-ChocolateyCacheFile throws an exception" {       
        It "Should handle exception and return false" {
            Mock Get-ChocolateyCacheFile { throw "Cache file path error" }
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error determining Chocolatey cache file path" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Chocolatey is not installed" {       
        It "Should return false and write error message" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $false }
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey is not installed. Cannot write cache file." -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-ChocolateyInstalled throws an exception" {       
        It "Should handle exception and return false" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { throw "Installation check failed" }
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking if Chocolatey is installed" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Find-Chocolatey throws an exception" {       
        It "Should handle exception and return false" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { throw "Cannot locate chocolatey" }
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error locating Chocolatey command" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Find-Chocolatey returns null or empty" {        
        It "Should return false when Find-Chocolatey returns null (via exception path)" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" } -Verifiable
            Mock Test-ChocolateyInstalled { return $true } -Verifiable
            Mock Find-Chocolatey { return $null } -Verifiable
            Mock Invoke-Command { }  # Should not be called normally
            Mock Set-Content { }     # Should not be called
            
            $result = Write-ChocolateyCache
            
            # Main assertion - function should return false
            $result | Should -Be $false
        }
        
        It "Should return false when Find-Chocolatey returns empty string (via exception path)" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" } -Verifiable
            Mock Test-ChocolateyInstalled { return $true } -Verifiable
            Mock Find-Chocolatey { return "" } -Verifiable
            Mock Invoke-Command { }  # Should not be called normally
            Mock Set-Content { }     # Should not be called
            
            $result = Write-ChocolateyCache
            
            # Main assertion - function should return false
            $result | Should -Be $false
        }
        
        It "Should return false when Find-Chocolatey returns whitespace (via validation path)" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" } -Verifiable
            Mock Test-ChocolateyInstalled { return $true } -Verifiable
            Mock Find-Chocolatey { return "   " } -Verifiable
            Mock Invoke-Command { }  # Should not be called
            Mock Set-Content { }     # Should not be called
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot write cache file." -and $Verbosity -eq "Warning"
            }
            Assert-MockCalled Invoke-Command -Exactly 0 -Scope It
            Assert-MockCalled Set-Content -Exactly 0 -Scope It
        }
    }

    Context "When Invoke-Command execution fails" {       
        It "Should handle Invoke-Command exception and return false" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { throw "Command execution failed" }
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to write Chocolatey cache file" -and $Verbosity -eq "Error"
            }
        }
        
        It "Should return false when LASTEXITCODE is not 0" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 1
                return @("git|2.42.0")
            }
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Retrieved Chocolatey packages successfully." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to retrieve Chocolatey packages or no packages found." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return false when no packages are returned" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Write-ChocolateyCache
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Retrieved Chocolatey packages successfully." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to retrieve Chocolatey packages or no packages found." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When Set-Content fails" {      
        It "Should handle Set-Content exception and return false" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0", "nodejs|20.10.0")
            }
            Mock Set-Content { throw "Access denied to cache file" }
            
            $result = Write-ChocolateyCache -Confirm:$false
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Retrieved Chocolatey packages successfully." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to write Chocolatey cache file" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When SupportsShouldProcess is tested" {
        It "Should support -WhatIf parameter" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0", "nodejs|20.10.0")
            }
            Mock Set-Content { }
            
            $result = Write-ChocolateyCache -WhatIf
            
            $result | Should -Be $true
            Assert-MockCalled Set-Content -Times 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Operation to write Chocolatey cache was cancelled." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should support -Confirm parameter" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0", "nodejs|20.10.0")
            }
            Mock Set-Content { }
            
            $result = Write-ChocolateyCache -Confirm:$false
            
            $result | Should -Be $true
            Assert-MockCalled Set-Content -Times 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey cache written successfully to:" -and $Verbosity -eq "Debug"
            }
        }
    }

    Context "When cache is written successfully" {
        It "Should return true and write debug messages when ShouldProcess is confirmed" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" } -Verifiable
            Mock Test-ChocolateyInstalled { return $true } -Verifiable
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" } -Verifiable
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0", "nodejs|20.10.0")
            } -Verifiable
            Mock Set-Content { } -Verifiable
            
            $result = Write-ChocolateyCache -Confirm:$false
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Retrieved Chocolatey packages successfully." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey cache written successfully to:" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Set-Content -Times 1 -Scope It -ParameterFilter {
                $Path -eq "TestDrive:\choco.cache" -and $Force -eq $true
            }
        }
        
        It "Should return true and show cancellation message when ShouldProcess is declined" {
            Mock Get-ChocolateyCacheFile { return "TestDrive:\choco.cache" } -Verifiable
            Mock Test-ChocolateyInstalled { return $true } -Verifiable
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" } -Verifiable
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("git|2.42.0", "nodejs|20.10.0")
            } -Verifiable
            Mock Set-Content { } -Verifiable
            
            $result = Write-ChocolateyCache -WhatIf
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Retrieved Chocolatey packages successfully." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Operation to write Chocolatey cache was cancelled." -and $Verbosity -eq "Warning"
            }
            Assert-MockCalled Set-Content -Times 0 -Scope It
        }
    }
}