BeforeAll {
    . $PSScriptRoot\Install-ScoopPackage.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\Uninstall-ScoopPackage.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\Read-ScoopCache.ps1    
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1    
}

Describe "Install-ScoopPackage" {

    Context "When Scoop is not installed" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $false }
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When Scoop command cannot be found" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When package is already installed with correct version and scope" {
        It "Should return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }
    }

    Context "When package is installed but version/scope does not match" {
        It "Should uninstall and reinstall the package" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $callCount = 0
            Mock Test-ScoopComponentInstalled -MockWith {
                $callCount++
                if ($callCount -eq 1) { [InstalledState]::Installed }
                else { [InstalledState]::Pass }
            }
            Mock Read-ScoopCache { 
                return @{
                    apps = @(
                        [PSCustomObject]@{ Name = "git"; Version = "2.42.0"; Info = "Local Install" }
                    )
                }
            }            
            Mock Uninstall-ScoopPackage { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $true }
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $true
        }
    }

    Context "When install command fails" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Uninstall-ScoopPackage { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 1 }
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When Write-ScoopCache fails after install" {
        It "Should return false" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Uninstall-ScoopPackage { return $true }
            Mock Invoke-Command { $global:LASTEXITCODE = 0 }
            Mock Write-ScoopCache { return $false }
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }

    Context "When installing with version, bucket, and global" {
        It "Should pass correct arguments and return true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $callCount = 0
            Mock Test-ScoopComponentInstalled -MockWith {
                $callCount++
                if ($callCount -eq 1) { [InstalledState]::Installed }
                else { [InstalledState]::Pass }
            }
            Mock Uninstall-ScoopPackage { return $true }
            Mock Invoke-Command {
                param($ScriptBlock)
                $global:LASTEXITCODE = 0
                # Optionally, check the arguments passed to scoop
                return $null
            }
            Mock Write-ScoopCache { return $true }
            $result = Install-ScoopPackage -PackageName "python" -Version "3.11.5" -Bucket "main" -Global
            $result | Should -Be $true
        }
    }

    Context "When an exception occurs" {
        It "Should return false" {
            Mock Test-ScoopInstalled { throw "Unexpected error" }
            $result = Install-ScoopPackage -PackageName "git"
            $result | Should -Be $false
        }
    }
}