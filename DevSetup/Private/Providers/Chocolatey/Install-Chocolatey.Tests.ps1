BeforeAll {
    . $PSScriptRoot\Install-Chocolatey.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    
    Mock Write-StatusMessage { }    
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Test-OperatingSystem { param($Windows) $true }
    Mock Test-ChocolateyInstalled { return $false }
    Mock Set-ExecutionPolicy { }
    Mock New-Object -MockWith {
        $mockWebClient = New-Object PSObject
        Add-Member -InputObject $mockWebClient -MemberType ScriptMethod -Name DownloadString -Value { param($url) return "# Chocolatey install script content" }
        Add-Member -InputObject $mockWebClient -MemberType ScriptMethod -Name Dispose -Value { }
        return $mockWebClient
    } -ParameterFilter { $TypeName -eq "System.Net.WebClient" }
    Mock Invoke-Expression { }
}

Describe "Install-Chocolatey" {

    Context "When not running on Windows" {
        It "Should skip installation and write status message" {
            Mock Test-OperatingSystem { param($Windows) return $false }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -match "Chocolatey is not available on this platform" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-OperatingSystem throws an exception" {
        It "Should handle operating system check exception and return false" {
            Mock Test-OperatingSystem { throw "Operating system check failed" }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -match "Error checking operating system" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { 
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When not running as administrator" {
        It "Should write error message and return false" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { return $false }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -match "Chocolatey installation requires administrator privileges" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Chocolatey is already installed" {
        It "Should return true and show already installed message" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -match "Chocolatey is already installed" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
        }
    }

    Context "When Test-ChocolateyInstalled throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { throw "Test-ChocolateyInstalled failed" }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error checking Chocolatey installation" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When Chocolatey is not installed and installation succeeds" {
        It "Should install successfully and verify with Test-ChocolateyInstalled" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { return $true }
            $script:installCheckCount = 0
            Mock Test-ChocolateyInstalled -MockWith {
                $script:installCheckCount++
                if ($script:installCheckCount -eq 1) { return $false }  # Initial check
                else { return $true }  # Post-install verification
            }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $true
            Assert-MockCalled Set-ExecutionPolicy -Exactly 1 -Scope It -ParameterFilter {
                $ExecutionPolicy -eq "Bypass" -and $Scope -eq "Process" -and $Force -eq $true
            }
            Assert-MockCalled New-Object -Exactly 1 -Scope It -ParameterFilter {
                $TypeName -eq "System.Net.WebClient"
            }
            Assert-MockCalled Invoke-Expression -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "[OK]" -and $ForegroundColor -eq "Green"
            }
        }
    }

    Context "When Chocolatey installation fails verification" {
        It "Should return false and write FAILED when Test-ChocolateyInstalled still returns false" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $false }  # Always returns false
            
            $result = Install-Chocolatey
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "[FAILD]" -and $ForegroundColor -eq "Red"
            }
        }
    }

    Context "When installation process fails" {
        It "Should handle installation exception and return false" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $false }
            Mock Invoke-Expression { throw "Network connection failed" }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error during Chocolatey installation" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "[FAILED]" -and $ForegroundColor -eq "Red"
            }
        }
    }

    Context "When verification fails with exception" {
        It "Should handle verification exception and return false" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { return $true }
            $script:installCheckCount = 0
            Mock Test-ChocolateyInstalled -MockWith {
                $script:installCheckCount++
                if ($script:installCheckCount -eq 1) { return $false }  # Initial check
                else { throw "Verification failed" }  # Post-install verification throws
            }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error verifying Chocolatey installation" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When an unexpected error occurs" {
        It "Should return false and write comprehensive error message" {
            Mock Test-OperatingSystem { param($Windows) return $true }
            Mock Test-RunningAsAdmin { throw "Unexpected system error" }
            
            $result = Install-Chocolatey
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error"
            }
        }
    }
}