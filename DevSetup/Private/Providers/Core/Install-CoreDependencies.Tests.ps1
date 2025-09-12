BeforeAll {
    . (Join-Path $PSScriptRoot "Install-CoreDependencies.ps1")
    . (Join-Path $PSScriptRoot "Install-Nuget.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Get-DevSetupManifest.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Powershell\Install-PowershellModule.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Chocolatey\Install-Chocolatey.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Chocolatey\Install-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Scoop\Install-Scoop.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Install-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Write-StatusMessage { }
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Test-RunningAsAdmin { return $true }
    Mock Install-Homebrew { return $true }
}

Describe "Install-CoreDependencies" {

    Context "When NuGet installation fails" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $false }
            Mock Test-OperatingSystem { param($os) return $true }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When manifest is missing or has no required modules" {
        It "Should return true and write warning" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return $null }
            Mock Test-OperatingSystem { param($os) return $true }
            $result = Install-CoreDependencies
            $result | Should -Be $true

            Mock Get-DevSetupManifest { return @{ RequiredModules = $null } }
            $result = Install-CoreDependencies
            $result | Should -Be $true
        }
    }

    Context "When required module installation fails" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git", "PSReadLine") } }
            Mock Test-OperatingSystem { param($os) return $false }
            $script:callCount = 0
            Mock Install-PowershellModule -MockWith {
                param($ModuleName, $Force, $AllowClobber, $Scope)
                $script:callCount++
                if ($script:callCount -eq 1) { return $true }
                else { return $false }
            }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When required modules include empty names" {
        It "Should skip empty module names and return true" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git", $null, "PSReadLine") } }
            Mock Install-PowershellModule { return $true }
            Mock Test-OperatingSystem { param($os) return $false }
            $result = Install-CoreDependencies
            $result | Should -Be $true
        }
    }

    Context "When all core dependencies install successfully on Windows" {
        It "Should install everything and return true" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git", "PSReadLine") } }
            Mock Install-PowershellModule { return $true }
            Mock Install-Chocolatey { return $true }
            Mock Install-ChocolateyPackage { return $true }
            Mock Install-Scoop { return $true }
            Mock Test-OperatingSystem { param($os) if ($os -eq 'Windows') { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $true
        }
    }

    Context "When Chocolatey installation fails on Windows" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowershellModule { return $true }
            Mock Install-Chocolatey { return $false }
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When Git installation fails on Windows" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowershellModule { return $true }
            Mock Install-Chocolatey { return $true }
            Mock Install-ChocolateyPackage { return $false }
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When Scoop installation fails on Windows" {
        It "Should return false and write error" {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowershellModule { return $true }
            Mock Install-Chocolatey { return $true }
            Mock Install-ChocolateyPackage { return $true }
            Mock Install-Scoop { return $false }
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            $result = Install-CoreDependencies
            $result | Should -Be $false
        }
    }

    Context "When all core dependencies install successfully on non-Windows" {
        BeforeEach {
            Mock Write-StatusMessage { Write-Error $Message }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-NuGet { return $true }
            Mock Install-PowershellModule { return $true }
            Mock Test-OperatingSystem { return $false }
            Mock Install-Homebrew { return $true }
        }
        It "Should skip Windows-only installs and return true" {
            $result = Install-CoreDependencies
            $result | Should -Be $true
            Assert-MockCalled Install-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Homebrew installation succeeded" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When install-homebrew fails on non-Windows" {
        BeforeEach {
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-NuGet { return $true }
            Mock Install-PowershellModule { return $true }
            Mock Test-OperatingSystem { return $false }
            Mock Install-Homebrew { return $false }
        }
        It "Should skip Windows-only installs and return false" {
            $result = Install-CoreDependencies
            $result | Should -Be $false
            Assert-MockCalled Install-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to install Homebrew" -and $Verbosity -eq "Error" }
        }
    }

    Context "When PATH needs to be refreshed on Windows" {
        BeforeEach {
            Mock Install-NuGet { return $true }
            Mock Get-DevSetupManifest { return @{ RequiredModules = @("posh-git") } }
            Mock Install-PowershellModule { return $true }
            Mock Install-Chocolatey { return $true }
            Mock Install-ChocolateyPackage { return $true }
            Mock Install-Scoop { return $true }
            Mock Test-OperatingSystem { param($Windows) if ($Windows) { return $true } else { return $false } }
            
            # Store original PATH to restore later
            $script:originalPath = $env:PATH
            
            # Store original environment variable values
            $script:originalUserPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $script:originalMachinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        }

        AfterEach {
            # Restore original PATH and environment variables
            if ($script:originalPath) {
                $env:PATH = $script:originalPath
            }
        }

        It "Should execute PATH refresh logic when User/Machine paths have new entries" {
            # Set up a scenario where current PATH is minimal
            $originalPath = $env:PATH
            $env:PATH = "C:\Windows\system32"
            
            try {
                $result = Install-CoreDependencies
                $result | Should -Be $true
                
                # The PATH should be longer than the original minimal path
                # This indirectly tests that the PATH refresh logic was executed
                $env:PATH.Length | Should -BeGreaterThan "C:\Windows\system32".Length
            }
            finally {
                # Restore original PATH
                $env:PATH = $originalPath
            }
        }

        It "Should handle scenario where all paths already exist in current PATH" {
            # Set up current PATH that already contains all User and Machine paths
            $currentUserPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $currentMachinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
            
            # Build a comprehensive PATH that includes everything
            $allPaths = @()
            if ($currentUserPath) { $allPaths += $currentUserPath.Split(';') | Where-Object { $_ } }
            if ($currentMachinePath) { $allPaths += $currentMachinePath.Split(';') | Where-Object { $_ } }
            $env:PATH = ($allPaths | Select-Object -Unique) -join ';'
            
            $pathBefore = $env:PATH
            $result = Install-CoreDependencies
            $result | Should -Be $true
            
            # PATH should remain essentially the same (no duplicates added)
            $env:PATH.Length | Should -BeGreaterOrEqual $pathBefore.Length
            # No significant increase in length (allowing for minor formatting differences)
            ($env:PATH.Length - $pathBefore.Length) | Should -BeLessThan 100
        }

        It "Should add paths from User and Machine PATH that are not in current session PATH" {
            # This test specifically targets the missed coverage lines (134, 141, 148)
            
            # Create a minimal current PATH that doesn't include common User/Machine paths
            $env:PATH = "C:\Windows\System32"
            
            # Get the actual current User and Machine paths from registry
            $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
            $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
            
            $pathBefore = $env:PATH
            $result = Install-CoreDependencies
            $result | Should -Be $true
            
            # The function should have added User and Machine paths to the current PATH
            # This will hit lines 134, 141, and 148 if User/Machine paths exist and are not in current PATH
            if ($userPath -or $machinePath) {
                # PATH should be significantly longer than the minimal starting PATH
                $env:PATH | Should -Not -Be $pathBefore
                $env:PATH.Length | Should -BeGreaterThan $pathBefore.Length
                
                # If User path exists, check that unique User paths were added
                if ($userPath) {
                    $userPaths = $userPath.Split(';') | Where-Object { $_ -and $pathBefore -notlike "*$_*" }
                    foreach ($path in $userPaths) {
                        if ($path) {
                            $env:PATH | Should -BeLike "*$path*"
                        }
                    }
                }
                
                # If Machine path exists, check that unique Machine paths were added
                if ($machinePath) {
                    $machinePaths = $machinePath.Split(';') | Where-Object { $_ -and $pathBefore -notlike "*$_*" }
                    foreach ($path in $machinePaths) {
                        if ($path) {
                            $env:PATH | Should -BeLike "*$path*"
                        }
                    }
                }
            }
        }

        It "Should handle empty User and Machine PATH variables" {
            # Mock empty PATH variables to test the null handling
            $originalGetEnv = ${function:global:GetEnvironmentVariable}
            
            # Create a mock that returns empty for PATH variables
            ${function:global:GetEnvironmentVariable} = {
                param($Name, $Target)
                if ($Name -eq "PATH") {
                    return $null
                }
                return $originalGetEnv.Invoke($Name, $Target)
            }
            
            try {
                $pathBefore = $env:PATH
                $result = Install-CoreDependencies
                $result | Should -Be $true
                
                # PATH should remain unchanged if no User/Machine paths exist
                $env:PATH | Should -Be $pathBefore
            }
            finally {
                # Restore original function
                if ($originalGetEnv) {
                    ${function:global:GetEnvironmentVariable} = $originalGetEnv
                }
            }
        }
    }    
}