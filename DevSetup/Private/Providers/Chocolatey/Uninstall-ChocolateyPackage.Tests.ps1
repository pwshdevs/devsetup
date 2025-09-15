BeforeAll {
    . $PSScriptRoot\Uninstall-ChocolateyPackage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    . $PSScriptRoot\Find-Chocolatey.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    
    Mock Write-StatusMessage { }
}

Describe "Uninstall-ChocolateyPackage" {

    Context "When not running as administrator" {
        It "Should throw exception and return false" {
            Mock Test-RunningAsAdmin { return $false }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-RunningAsAdmin throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { throw "Admin check failed" }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error checking administrator privileges" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Chocolatey is not installed" {
        It "Should return false and write warning message" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $false }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey is not installed. Cannot uninstall package 'git'." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When Test-ChocolateyInstalled throws an exception" {
        It "Should handle exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { throw "Installation check failed" }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
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
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { throw "Cannot locate chocolatey" }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
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
        It "Should return false when Find-Chocolatey returns null" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return $null }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot uninstall package 'git'." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return false when Find-Chocolatey returns empty string" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "" }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot uninstall package 'git'." -and $Verbosity -eq "Warning"
            }
        }
        
        It "Should return false when Find-Chocolatey returns whitespace" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "   " }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git"
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Could not find Chocolatey command. Cannot uninstall package 'git'." -and $Verbosity -eq "Warning"
            }
        }
    }

    Context "When Invoke-Command execution fails" {
        It "Should handle Invoke-Command exception and return false" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { throw "Command execution failed" }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git" -Confirm:$false
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Uninstalling Chocolatey package: git" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error uninstalling package 'git'" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When package uninstallation fails with non-zero exit code" {
        It "Should return false when LASTEXITCODE is not 0" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 1
            }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git" -Confirm:$false
            
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Uninstalling Chocolatey package: git" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to uninstall Chocolatey package 'git'." -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When SupportsShouldProcess is tested" {
        It "Should support -WhatIf parameter" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git" -WhatIf
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Uninstalling Chocolatey package: git" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Operation to uninstall package 'git' was cancelled." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Invoke-Command -Times 0 -Scope It
        }
        
        It "Should support -Confirm parameter" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
            }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git" -Confirm:$false
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Uninstalling Chocolatey package: git" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey package 'git' uninstalled successfully." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
        }
    }

    Context "When package is uninstalled successfully" {
        It "Should return true and write debug messages when ShouldProcess is confirmed" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
            }
            
            $result = Uninstall-ChocolateyPackage -PackageName "nodejs" -Confirm:$false
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Uninstalling Chocolatey package: nodejs" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey package 'nodejs' uninstalled successfully." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
        }
        
        It "Should return true and show cancellation message when ShouldProcess is declined" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { }
            
            $result = Uninstall-ChocolateyPackage -PackageName "vscode" -WhatIf
            
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Uninstalling Chocolatey package: vscode" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Operation to uninstall package 'vscode' was cancelled." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Invoke-Command -Times 0 -Scope It
        }
    }

    Context "When validating command construction and execution" {
        It "Should execute the uninstall command with correct parameters" {
            Mock Test-RunningAsAdmin { return $true }
            Mock Test-ChocolateyInstalled { return $true }
            Mock Find-Chocolatey { return "C:\ProgramData\chocolatey\bin\choco.exe" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
            }
            
            $result = Uninstall-ChocolateyPackage -PackageName "git" -Confirm:$false
            
            $result | Should -Be $true
            Assert-MockCalled Invoke-Command -Times 1 -Scope It
            Assert-MockCalled Find-Chocolatey -Times 1 -Scope It
        }
    }
}