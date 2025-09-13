BeforeAll {
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\Get-ScoopCacheFile.ps1
    
    # Mock Write-StatusMessage to avoid external dependencies
    function Write-StatusMessage { 
        param($Message, $Verbosity = "Default")
        # Mock implementation
    }
}

Describe "Write-ScoopCache" {

    BeforeEach {
        # Reset all mocks and global variables before each test
        Mock Write-StatusMessage { }
        $global:LASTEXITCODE = 0
    }

    Context "Error Handling - Get-ScoopCacheFile fails" {
        It "Should return false when Get-ScoopCacheFile throws an exception" {
            # Arrange
            Mock Get-ScoopCacheFile { throw "Cache path error" }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
            Assert-VerifiableMock
        }
    }

    Context "Error Handling - Test-ScoopInstalled fails" {
        It "Should return false when Test-ScoopInstalled throws an exception" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { throw "Test error" }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
            Assert-VerifiableMock
        }
    }

    Context "When Scoop is not installed" {
        It "Should return false when Scoop is not installed" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $false }

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
        }
    }

    Context "Error Handling - Find-Scoop fails" {
        It "Should return false when Find-Scoop throws an exception" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { throw "Find error" }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
            Assert-VerifiableMock
        }
    }

    Context "When Scoop command cannot be found" {
        It "Should return false when Find-Scoop returns null" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { $null }

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
        }

        It "Should return false when Find-Scoop returns empty string" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "" }

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
        }
    }

    Context "Export Operation Failures" {
        It "Should return false when Invoke-Command throws an exception" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { throw "Command failed" }

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
        }

        It "Should return false when scoop export exits with non-zero code" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 1
                return @("some output")
            }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
            Assert-VerifiableMock
        }

        It "Should return false when scoop export returns no data" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $null
            }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
            Assert-VerifiableMock
        }

        It "Should return false when scoop export returns empty array" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @()
            }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
            Assert-VerifiableMock
        }
    }

    Context "Write Operation Failures" {
        It "Should return false when Set-Content throws an exception" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("package1", "package2")
            }
            Mock Set-Content { throw "Access denied" }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $false
            Assert-VerifiableMock
        }
    }

    Context "Successful Operations" {
        It "Should return true when all operations succeed" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("package1", "package2", "package3")
            }
            Mock Set-Content { }
            Mock Write-StatusMessage { } -Verifiable

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $true
            Assert-VerifiableMock
        }

        It "Should call Set-Content with correct parameters" {
            # Arrange
            $testPath = "$TestDrive\scoop.cache"
            $testData = @("package1", "package2")
            Mock Get-ScoopCacheFile { $testPath }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return $testData
            }
            Mock Set-Content { } -ParameterFilter {
                $Path -eq $testPath -and
                $Force -eq $true
            } -Verifiable
            Mock Write-StatusMessage { }

            # Act
            $result = Write-ScoopCache

            # Assert
            $result | Should -Be $true
            Assert-VerifiableMock
        }
    }

    Context "Function Properties" {
        It "Should have CmdletBinding attribute" {
            $function = Get-Command Write-ScoopCache
            $function.CmdletBinding | Should -Be $true
        }

        It "Should support ShouldProcess" {
            $function = Get-Command Write-ScoopCache
            $function.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $function.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It "Should return boolean type" {
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $false }
            
            $result = Write-ScoopCache
            
            $result | Should -BeOfType [bool]
        }
    }

    Context "WhatIf and ShouldProcess functionality" {
        It "Should not write to cache file when WhatIf is specified" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("package1", "package2")
            }
            Mock Set-Content { }

            # Act
            $result = Write-ScoopCache -WhatIf

            # Assert
            $result | Should -Be $true
            Should -Invoke Set-Content -Times 0 -Exactly
        }

        It "Should return true and log debug message when WhatIf is used" {
            # Arrange
            Mock Get-ScoopCacheFile { "$TestDrive\scoop.cache" }
            Mock Test-ScoopInstalled { $true }
            Mock Find-Scoop { "scoop" }
            Mock Invoke-Command { 
                $global:LASTEXITCODE = 0
                return @("package1", "package2")
            }
            Mock Set-Content { }

            # Act
            $result = Write-ScoopCache -WhatIf

            # Assert
            $result | Should -Be $true
            Should -Invoke Write-StatusMessage -ParameterFilter {
                $Message -like "*Skipping writing Scoop cache file due to ShouldProcess*" -and $Verbosity -eq "Debug"
            } -Times 1 -Exactly
        }
    }
}
