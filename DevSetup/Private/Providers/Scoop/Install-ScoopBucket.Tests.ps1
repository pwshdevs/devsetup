BeforeAll {
    . $PSScriptRoot\Install-ScoopBucket.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1    
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\..\..\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1
}

Describe "Install-ScoopBucket" {
    BeforeEach {
        $global:LASTEXITCODE = 0
        Mock Write-StatusMessage { }
        Mock Invoke-Command { $global:LASTEXITCODE = 0 }
        Mock Find-Scoop { return "scoop" }
        Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
        Mock Write-ScoopCache { return $true }
    }

    Context "When Test-ScoopInstalled returns false" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $false }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should not call Find-Scoop" {
            Install-ScoopBucket -Name "extras"
            Should -Not -Invoke Find-Scoop
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { throw "Scoop check failed" }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should log error message and stack trace" {
            Install-ScoopBucket -Name "extras"
            Should -Invoke Write-StatusMessage -Times 2 -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When Find-Scoop returns null" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should not call Test-ScoopComponentInstalled" {
            Install-ScoopBucket -Name "extras"
            Should -Not -Invoke Test-ScoopComponentInstalled
        }
    }

    Context "When Find-Scoop throws an exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { throw "Find Scoop failed" }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should log error message and stack trace" {
            Install-ScoopBucket -Name "extras"
            Should -Invoke Write-StatusMessage -Times 2 -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When Test-ScoopComponentInstalled throws an exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { throw "Component check failed" }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should log error message with bucket name" {
            Install-ScoopBucket -Name "extras"
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Failed to check if Scoop bucket 'extras' is installed*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When bucket is already installed" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
        }

        It "Should return true" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $true
        }

        It "Should not execute Invoke-Command" {
            Install-ScoopBucket -Name "extras"
            Should -Not -Invoke Invoke-Command
        }

        It "Should not call Write-ScoopCache" {
            Install-ScoopBucket -Name "extras"
            Should -Not -Invoke Write-ScoopCache
        }
    }

    Context "When bucket is not installed and installation is successful" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-ScoopCache { return $true }
        }

        It "Should install official bucket successfully" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $true
            Should -Invoke Invoke-Command -Times 1
        }

        It "Should install custom bucket with source successfully" {
            $result = Install-ScoopBucket -Name "custom-bucket" -Source "https://github.com/user/scoop-bucket"
            $result | Should -Be $true
            Should -Invoke Invoke-Command -Times 1
        }

        It "Should update cache after successful installation" {
            Install-ScoopBucket -Name "extras"
            Should -Invoke Write-ScoopCache -Times 1
        }
    }

    Context "When bucket installation fails with non-zero exit code" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 1
                return $null
            }
            Mock Write-ScoopCache { return $true }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should not call Write-ScoopCache when installation fails" {
            Install-ScoopBucket -Name "extras"
            Should -Not -Invoke Write-ScoopCache
        }
    }

    Context "When bucket installation succeeds but cache update fails" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-ScoopCache { return $false }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should attempt cache update" {
            Install-ScoopBucket -Name "extras"
            Should -Invoke Write-ScoopCache -Times 1
        }
    }

    Context "When cache update throws an exception" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-ScoopCache { throw "Cache update failed" }
        }

        It "Should return false" {
            $result = Install-ScoopBucket -Name "extras"
            $result | Should -Be $false
        }

        It "Should log cache update error with bucket name" {
            Install-ScoopBucket -Name "extras"
            Should -Invoke Write-StatusMessage -ParameterFilter { 
                $Message -like "*Failed to update Scoop cache after adding bucket 'extras'*" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When using WhatIf parameter" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-ScoopCache { return $true }
        }

        It "Should return true with WhatIf when bucket not already installed" {
            $result = Install-ScoopBucket -Name "extras" -WhatIf
            $result | Should -Be $true
        }

        It "Should still check if bucket is already installed" {
            Install-ScoopBucket -Name "extras" -WhatIf
            Should -Invoke Test-ScoopComponentInstalled -Times 1
        }

        It "Should update cache even with WhatIf when bucket not installed" {
            Install-ScoopBucket -Name "extras" -WhatIf
            Should -Invoke Write-ScoopCache -Times 1
        }

        It "Should return true with WhatIf when bucket already installed" {
            Mock Test-ScoopComponentInstalled { return [InstalledState]::Pass }
            $result = Install-ScoopBucket -Name "extras" -WhatIf
            $result | Should -Be $true
        }
    }

    Context "Parameter validation and edge cases" {
        BeforeEach {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-ScoopCache { return $true }
        }

        It "Should handle empty source parameter correctly" {
            $result = Install-ScoopBucket -Name "extras" -Source ""
            $result | Should -Be $true
            Should -Invoke Invoke-Command -Times 1
        }

        It "Should pass correct parameters to Test-ScoopComponentInstalled" {
            Install-ScoopBucket -Name "test-bucket"
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Bucket -eq $true -and $Name -eq "test-bucket"
            }
        }

        It "Should handle bucket names with special characters" {
            $result = Install-ScoopBucket -Name "test-bucket-123"
            $result | Should -Be $true
            Should -Invoke Test-ScoopComponentInstalled -ParameterFilter {
                $Name -eq "test-bucket-123"
            }
        }
    }

    Context "Integration test scenarios" {
        It "Should handle complete successful installation flow" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "C:\Users\Test\scoop\shims\scoop" }
            Mock Test-ScoopComponentInstalled { return [InstalledState]::NotInstalled }
            Mock Invoke-Command {
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-ScoopCache { return $true }

            $result = Install-ScoopBucket -Name "nonportable" -Source "https://github.com/ScoopInstaller/Nonportable"

            $result | Should -Be $true
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Invoke Find-Scoop -Times 1
            Should -Invoke Test-ScoopComponentInstalled -Times 1
            Should -Invoke Invoke-Command -Times 1
            Should -Invoke Write-ScoopCache -Times 1
        }

        It "Should handle complete failure scenario with error logging" {
            Mock Test-ScoopInstalled { throw "Test failure" }

            $result = Install-ScoopBucket -Name "extras"

            $result | Should -Be $false
            Should -Invoke Write-StatusMessage -Times 2 -ParameterFilter { $Verbosity -eq "Error" }
            Should -Not -Invoke Find-Scoop
            Should -Not -Invoke Test-ScoopComponentInstalled
            Should -Not -Invoke Invoke-Command
            Should -Not -Invoke Write-ScoopCache
        }

        It "Should handle early exit when scoop not installed" {
            Mock Test-ScoopInstalled { return $false }

            $result = Install-ScoopBucket -Name "extras"

            $result | Should -Be $false
            Should -Invoke Test-ScoopInstalled -Times 1
            Should -Not -Invoke Find-Scoop
            Should -Not -Invoke Test-ScoopComponentInstalled
            Should -Not -Invoke Invoke-Command
            Should -Not -Invoke Write-ScoopCache
        }
    }
}