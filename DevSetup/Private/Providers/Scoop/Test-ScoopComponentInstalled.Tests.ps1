BeforeAll {
    . $PSScriptRoot\Test-ScoopComponentInstalled.ps1
    . $PSScriptRoot\Read-ScoopCache.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1     
}

Describe "Test-ScoopComponentInstalled" {

    Context "When Scoop is not installed" {
        It "Should return NotInstalled for package" {
            Mock Test-ScoopInstalled { return $false }
            $result = Test-ScoopComponentInstalled -Package -Name "git"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
        It "Should return NotInstalled for bucket" {
            Mock Test-ScoopInstalled { return $false }
            $result = Test-ScoopComponentInstalled -Bucket -Name "extras"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }

    Context "When cache cannot be read" {
        It "Should return NotInstalled for package" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { return $null }
            $result = Test-ScoopComponentInstalled -Package -Name "git"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
        It "Should return NotInstalled for bucket" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { return $null }
            $result = Test-ScoopComponentInstalled -Bucket -Name "extras"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }

    Context "When package is not found in cache" {
        It "Should return NotInstalled" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { return @{ apps = @(); buckets = @() } }
            $result = Test-ScoopComponentInstalled -Package -Name "git"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }

    Context "When bucket is not found in cache" {
        It "Should return NotInstalled" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { return @{ apps = @(); buckets = @() } }
            $result = Test-ScoopComponentInstalled -Bucket -Name "extras"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }

    Context "When package is found without version or global" {
        It "Should return Installed + RequiredVersionMet + MinimumVersionMet + GlobalVersionMet" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { 
                return @{
                    apps = @(
                        [PSCustomObject]@{ Name = "git"; Version = "2.42.0"; Info = "Local Install" }
                    )
                }
            }
            $result = Test-ScoopComponentInstalled -Package -Name "git"
            $expected = [InstalledState]::Installed + [InstalledState]::RequiredVersionMet + [InstalledState]::MinimumVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When package is found with matching version" {
        It "Should return Installed + RequiredVersionMet + MinimumVersionMet + GlobalVersionMet" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { 
                return @{
                    apps = @(
                        [PSCustomObject]@{ Name = "git"; Version = "2.42.0"; Info = "Local Install" }
                    )
                }
            }
            $result = Test-ScoopComponentInstalled -Package -Name "git" -Version "2.42.0"
            $expected = [InstalledState]::Installed + [InstalledState]::RequiredVersionMet + [InstalledState]::MinimumVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When package is found but version does not match" {
        It "Should return Installed + GlobalVersionMet" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { 
                return @{
                    apps = @(
                        [PSCustomObject]@{ Name = "git"; Version = "2.41.0"; Info = "Local Install" }
                    )
                }
            }
            $result = Test-ScoopComponentInstalled -Package -Name "git" -Version "2.42.0"
            $expected = [InstalledState]::Installed + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When package is found with Global switch and global install" {
        It "Should return Installed + RequiredVersionMet + MinimumVersionMet + GlobalVersionMet" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { 
                return @{
                    apps = @(
                        [PSCustomObject]@{ Name = "git"; Version = "2.42.0"; Info = "Global Install" }
                    )
                }
            }
            $result = Test-ScoopComponentInstalled -Package -Name "git" -Global
            $expected = [InstalledState]::Installed + [InstalledState]::RequiredVersionMet + [InstalledState]::MinimumVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When bucket is found in cache" {
        It "Should return Installed + RequiredVersionMet + MinimumVersionMet + GlobalVersionMet" {
            Mock Test-ScoopInstalled { return $true }
            Mock Read-ScoopCache { 
                return @{
                    buckets = @(
                        [PSCustomObject]@{ Name = "extras" }
                    )
                }
            }
            $result = Test-ScoopComponentInstalled -Bucket -Name "extras"
            $expected = [InstalledState]::Installed + [InstalledState]::RequiredVersionMet + [InstalledState]::MinimumVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }
}