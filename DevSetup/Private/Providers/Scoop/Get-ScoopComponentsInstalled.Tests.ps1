BeforeAll {
    . $PSScriptRoot\Get-ScoopComponentsInstalled.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }
    Mock Write-Host {}
    Mock Write-Error {}
}

Describe "Get-ScoopComponentsInstalled" {

    Context "When Scoop is not installed" {
        It "Should return null and warn about Scoop not being installed" {
            Mock Test-ScoopInstalled { return $false }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Scoop is not installed. Cannot check for installed components." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        It "Should return null and log error with stack trace" {
            Mock Test-ScoopInstalled { throw "Critical error checking Scoop" }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not get installed Scoop components: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Find-Scoop returns null" {
        It "Should return null and warn about failing to find Scoop command" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Failed to find Scoop command. Cannot check for installed components." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Find-Scoop throws an exception" {
        It "Should return null and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { throw "Error finding Scoop executable" }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Error finding Scoop command: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When scoop export command fails with non-zero exit code" {
        It "Should return null and warn about no components found" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 1
                return $null
            }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "No Scoop components found or scoop list command failed." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When scoop export returns empty results" {
        It "Should return null and warn about no components found" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "No Scoop components found or scoop list command failed." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Invoke-Command throws an exception" {
        It "Should return null and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { throw "Command execution failed" }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not execute 'scoop export': *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When ConvertFrom-Json fails with invalid JSON" {
        It "Should return null and log JSON parsing error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return "invalid json content"
            }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not parse 'scoop export' output: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When everything succeeds with valid JSON" {
        It "Should return parsed components list" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $mockScoopExport = @{
                apps = @(
                    @{
                        Name = "git"
                        Info = ""
                        Source = "main"
                        Updated = "2023-01-01T00:00:00.000Z"
                        Version = "2.39.0.windows.2"
                    },
                    @{
                        Name = "nodejs"
                        Info = ""
                        Source = "main"
                        Updated = "2023-01-15T00:00:00.000Z"
                        Version = "18.13.0"
                    }
                )
                buckets = @(
                    @{
                        Name = "main"
                        Source = "https://github.com/ScoopInstaller/Main"
                        Updated = "2023-01-01T00:00:00.000Z"
                    },
                    @{
                        Name = "extras"
                        Source = "https://github.com/ScoopInstaller/Extras"
                        Updated = "2023-01-10T00:00:00.000Z"
                    }
                )
            }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return ($mockScoopExport | ConvertTo-Json -Depth 10)
            }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Not -Be $null
            $result.apps | Should -HaveCount 2
            $result.buckets | Should -HaveCount 2
            $result.apps[0].Name | Should -Be "git"
            $result.apps[0].Version | Should -Be "2.39.0.windows.2"
            $result.apps[1].Name | Should -Be "nodejs"
            $result.buckets[0].Name | Should -Be "main"
            $result.buckets[1].Name | Should -Be "extras"
        }
    }

    Context "When scoop export returns minimal valid JSON" {
        It "Should return parsed components with empty arrays" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $mockScoopExport = @{
                apps = @()
                buckets = @()
            }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return ($mockScoopExport | ConvertTo-Json -Depth 10)
            }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Not -Be $null
            $result.apps | Should -HaveCount 0
            $result.buckets | Should -HaveCount 0
        }
    }

    Context "When scoop export returns JSON with only apps" {
        It "Should return parsed components with apps but no buckets property" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $mockScoopExport = @{
                apps = @(
                    @{
                        Name = "curl"
                        Version = "7.87.0_1"
                        Source = "main"
                    }
                )
            }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return ($mockScoopExport | ConvertTo-Json -Depth 10)
            }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Not -Be $null
            $result.apps | Should -HaveCount 1
            $result.apps[0].Name | Should -Be "curl"
            $result.PSObject.Properties.Name -contains "buckets" | Should -Be $false
        }
    }

    Context "Integration test with mocked global LASTEXITCODE" {
        It "Should properly handle LASTEXITCODE from scoop export command" {
            # Ensure LASTEXITCODE starts clean
            $global:LASTEXITCODE = 0
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { 
                # Simulate scoop export failing
                $global:LASTEXITCODE = 2
                return $null
            }
            
            $result = Get-ScoopComponentsInstalled
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No Scoop components found or scoop list command failed." -and $Verbosity -eq "Warning" 
            }
        }
    }
}