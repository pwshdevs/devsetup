BeforeAll {
    . $PSScriptRoot\Get-ScoopPackagesAvailable.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }
    Mock Write-Host {}
    Mock Write-Error {}
}

Describe "Get-ScoopPackagesAvailable" {

    Context "When Scoop is not installed" {
        It "Should return null and warn about Scoop not being installed" {
            Mock Test-ScoopInstalled { return $false }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Scoop is not installed. Cannot check for available packages." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Test-ScoopInstalled throws an exception" {
        It "Should return null and log error with stack trace" {
            Mock Test-ScoopInstalled { throw "Critical error checking Scoop" }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not get available Scoop packages: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Find-Scoop returns null" {
        It "Should return null and warn about failing to find Scoop command" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return $null }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "Failed to find Scoop command. Cannot check for available packages." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Find-Scoop throws an exception" {
        It "Should return null and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { throw "Error finding Scoop executable" }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Error finding Scoop command: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When scoop search command fails with non-zero exit code" {
        It "Should return null and warn about no packages found" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 1
                return $null
            }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "No Scoop packages found or scoop search command failed." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When scoop search returns empty results" {
        It "Should return null and warn about no packages found" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $null
            }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { 
                $Message -eq "No Scoop packages found or scoop search command failed." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When Invoke-Command throws an exception" {
        It "Should return null and log error with stack trace" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { throw "Command execution failed" }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not execute 'scoop search': *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When parsing scoop search output fails" {
        It "Should return null and log parsing error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            # Mock search output that would cause parsing issues
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("Searching in all buckets...", "", "Results from local buckets...", "", "git")
            }
            # Mock the parsing logic to throw an exception
            Mock ForEach-Object { throw "Parsing error" }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -like "Could not parse 'scoop search' output: *" -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When scoop search returns valid output with packages" {
        It "Should return parsed packages hashtable with correct structure" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            # Mock typical scoop search output
            $mockSearchOutput = @(
                "Searching in all buckets...",
                "",
                "Results from local buckets...",
                "",
                "git                    2.39.0.windows.2    main",
                "nodejs                 18.13.0             main",
                "python                 3.11.1              main",
                "vscode                 1.74.2              extras"
            )
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $mockSearchOutput
            }
            
            $result = Get-ScoopPackagesAvailable
            
            # Now the function works correctly and returns a hashtable
            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
            $result.Keys.Count | Should -Be 4
            $result["git"] | Should -Not -Be $null
            $result["git"].Name | Should -Be "git"
            $result["git"].Version | Should -Be "2.39.0.windows.2"
            $result["git"].Source | Should -Be "main"
            $result["nodejs"].Version | Should -Be "18.13.0"
            $result["vscode"].Source | Should -Be "extras"
        }
    }

    Context "When scoop search returns header-only output" {
        It "Should return empty hashtable when no packages are found after headers" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            # Mock search output with only headers
            $mockSearchOutput = @(
                "Searching in all buckets...",
                "",
                "Results from local buckets...",
                ""
            )
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $mockSearchOutput
            }
            
            $result = Get-ScoopPackagesAvailable
            
            # The function should return an empty hashtable since no packages are found after skipping headers
            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
            $result.Keys.Count | Should -Be 0
        }
    }

    Context "When scoop search returns malformed package lines" {
        It "Should handle malformed package lines gracefully and process valid ones" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            # Mock search output with various malformed lines
            $mockSearchOutput = @"
Searching in all buckets...

Results from local buckets...

git                    2.39.0.windows.2    main

   
incomplete-package
another-package        1.0.0
full-package           2.0.0               extras
"@
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $mockSearchOutput
            }
            
            $result = Get-ScoopPackagesAvailable
            
            # The function should handle malformed lines gracefully and process valid ones
            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
            # Should have processed valid entries
            $result["git"] | Should -Not -Be $null
            $result["git"].Version | Should -Be "2.39.0.windows.2"
            $result["another-package"] | Should -Not -Be $null
            $result["another-package"].Version | Should -Be "1.0.0"
            $result["full-package"] | Should -Not -Be $null
            $result["full-package"].Source | Should -Be "extras"
            # Single-word entries might still be processed depending on $Parts.Count check
            if ($result["incomplete-package"]) {
                $result["incomplete-package"].Name | Should -Be "incomplete-package"
            }
        }
    }

    Context "Integration test with mocked global LASTEXITCODE" {
        It "Should properly handle LASTEXITCODE from scoop search command" {
            # Ensure LASTEXITCODE starts clean
            $global:LASTEXITCODE = 0
            
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            Mock Invoke-Command { 
                # Simulate scoop search failing
                $global:LASTEXITCODE = 2
                return $null
            }
            
            $result = Get-ScoopPackagesAvailable
            
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "No Scoop packages found or scoop search command failed." -and $Verbosity -eq "Warning" 
            }
        }
    }

    Context "When scoop search returns mixed valid and invalid lines" {
        It "Should process valid lines and handle invalid ones gracefully" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            $mockSearchOutput = @"
Searching in all buckets...

Results from local buckets...

git                    2.39.0.windows.2    main
broken-line-no-spaces
nodejs                 18.13.0             main

python                 3.11.1              main
"@
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $mockSearchOutput
            }
            
            $result = Get-ScoopPackagesAvailable
            
            # Should process all non-empty lines that pass the $Parts.Count > 0 check
            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
            $result["git"] | Should -Not -Be $null
            $result["nodejs"] | Should -Not -Be $null
            $result["python"] | Should -Not -Be $null
            $result["git"].Version | Should -Be "2.39.0.windows.2"
            $result["nodejs"].Version | Should -Be "18.13.0"
            # Single-word entry may or may not be processed depending on implementation
            if ($result["broken-line-no-spaces"]) {
                $result["broken-line-no-spaces"].Name | Should -Be "broken-line-no-spaces"
            }
        }
    }

    Context "Performance test with large search results" {
        It "Should handle large search results efficiently and return proper hashtable" {
            Mock Test-ScoopInstalled { return $true }
            Mock Find-Scoop { return "scoop" }
            
            # Generate a large mock search output
            $mockSearchOutput = @("Searching in all buckets...", "", "Results from local buckets...", "")
            for ($i = 1; $i -le 1000; $i++) {
                $mockSearchOutput += "package$i                1.0.$i              main"
            }
            
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $mockSearchOutput
            }
            
            # Measure execution time
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Get-ScoopPackagesAvailable
            $stopwatch.Stop()
            
            # Function should return a hashtable with all 1000 packages
            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
            $result.Keys.Count | Should -Be 1000
            $result["package1"] | Should -Not -Be $null
            $result["package1000"] | Should -Not -Be $null
            
            # Verify it completes in reasonable time (less than 10 seconds)
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 10000
        }
    }
}