BeforeAll {
    . $PSScriptRoot\Read-ChocolateyCache.ps1
    . $PSScriptRoot\Get-ChocolateyCacheFile.ps1
    . $PSScriptRoot\Write-ChocolateyCache.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    
    Mock Write-StatusMessage { }
}

Describe "Read-ChocolateyCache" {

    Context "When Get-ChocolateyCacheFile throws an exception" {
        It "Should handle exception and return null" {
            Mock Get-ChocolateyCacheFile { throw "Cache file path error" }
            
            $result = Read-ChocolateyCache
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to get Chocolatey cache file path" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When cache file exists and can be read successfully" {
        It "Should return cache data as array of strings" {
            $testCacheFile = "TestDrive:\choco.cache"
            $testData = @("package1 1.0.0", "package2 2.0.0", "package3 3.0.0")
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { return $testData }
            
            $result = Read-ChocolateyCache
            
            $result | Should -Be $testData
            $result | Should -HaveCount 3
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq $testCacheFile
            }
            Assert-MockCalled Get-Content -Times 1 -Scope It -ParameterFilter {
                $Path -eq $testCacheFile
            }
        }
    }

    Context "When cache file does not exist and needs to be created" {
        It "Should create cache file and then read it successfully" {
            $testCacheFile = "TestDrive:\choco.cache"
            $testData = @("package1 1.0.0", "package2 2.0.0")
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $false }
            Mock Write-ChocolateyCache { return $true }
            Mock Get-Content { return $testData }
            
            $result = Read-ChocolateyCache
            
            $result | Should -Be $testData
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey cache file not found: $([regex]::Escape($testCacheFile))" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Creating new Chocolatey cache file..." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-ChocolateyCache -Times 1 -Scope It
            Assert-MockCalled Get-Content -Times 1 -Scope It
        }
    }

    Context "When Write-ChocolateyCache fails to create cache file" {
        It "Should return null when Write-ChocolateyCache returns false" {
            $testCacheFile = "TestDrive:\choco.cache"
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $false }
            Mock Write-ChocolateyCache { return $false }
            
            $result = Read-ChocolateyCache
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to create Chocolatey cache file: $([regex]::Escape($testCacheFile))" -and $Verbosity -eq "Error"
            }
        }
        
        It "Should handle Write-ChocolateyCache exception and return null" {
            $testCacheFile = "TestDrive:\choco.cache"
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $false }
            Mock Write-ChocolateyCache { throw "Cache write failed" }
            
            $result = Read-ChocolateyCache
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error creating Chocolatey cache file" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Test-Path throws an exception" {
        It "Should handle Test-Path exception and return null" {
            $testCacheFile = "TestDrive:\choco.cache"
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { throw "Path test failed" }
            
            $result = Read-ChocolateyCache
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Error ensuring Chocolatey cache file exists" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When Get-Content throws an exception" {
        It "Should handle Get-Content exception and return null" {
            $testCacheFile = "TestDrive:\choco.cache"
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { throw "File read failed" }
            
            $result = Read-ChocolateyCache
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Failed to read Chocolatey cache file" -and $Verbosity -eq "Error"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            }
        }
    }

    Context "When cache file exists but is empty" {
        It "Should return empty result when cache file has no content" {
            $testCacheFile = "TestDrive:\choco.cache"
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { return @() }
            
            $result = Read-ChocolateyCache
            
            $result | Should -Be @()
            Assert-MockCalled Get-Content -Times 1 -Scope It
        }
        
        It "Should return null when cache file returns null content" {
            $testCacheFile = "TestDrive:\choco.cache"
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { return $null }
            
            $result = Read-ChocolateyCache
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Get-Content -Times 1 -Scope It
        }
    }

    Context "When validating cross-platform file paths" {
        It "Should work with Windows-style paths" {
            $testCacheFile = "C:\Users\Test\AppData\Local\DevSetup\choco.cache"
            $testData = @("package1 1.0.0")
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { return $testData }
            
            $result = Read-ChocolateyCache
            
            $result | Should -Be $testData
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq $testCacheFile
            }
        }
        
        It "Should work with Unix-style paths" {
            $testCacheFile = "/home/user/.local/share/DevSetup/choco.cache"
            $testData = @("package1 1.0.0")
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { return $testData }
            
            $result = Read-ChocolateyCache
            
            $result | Should -Be $testData
            Assert-MockCalled Test-Path -Times 1 -Scope It -ParameterFilter {
                $Path -eq $testCacheFile
            }
        }
    }

    Context "When validating function integration scenarios" {
        It "Should handle complete workflow from missing cache to successful read" {
            $testCacheFile = "TestDrive:\integration.cache"
            $testData = @("git 2.42.0", "nodejs 18.17.0", "vscode 1.82.0")
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $false }
            Mock Write-ChocolateyCache { return $true }
            Mock Get-Content { return $testData }
            
            $result = Read-ChocolateyCache
            
            $result | Should -Be $testData
            $result | Should -HaveCount 3
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Chocolatey cache file not found" -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Creating new Chocolatey cache file..." -and $Verbosity -eq "Debug"
            }
            Assert-MockCalled Write-ChocolateyCache -Times 1 -Scope It
            Assert-MockCalled Get-Content -Times 1 -Scope It
        }
    }

    Context "When validating output type and format" {
        It "Should return array of strings for multi-line cache" {
            $testCacheFile = "TestDrive:\choco.cache"
            $testData = @("package1 1.0.0", "package2 2.0.0", "package3 3.0.0")
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { return $testData }
            
            $result = Read-ChocolateyCache
            
            # PowerShell automatically converts single strings to arrays when expected
            $result | Should -HaveCount 3
            $result[0] | Should -Be "package1 1.0.0"
            $result[1] | Should -Be "package2 2.0.0"  
            $result[2] | Should -Be "package3 3.0.0"
        }
        
        It "Should return single string for single-line cache" {
            $testCacheFile = "TestDrive:\choco.cache"
            $testData = "single-package 1.0.0"
            
            Mock Get-ChocolateyCacheFile { return $testCacheFile }
            Mock Test-Path { return $true }
            Mock Get-Content { return $testData }
            
            $result = Read-ChocolateyCache
            
            $result | Should -BeOfType [System.String]
            $result | Should -Be $testData
        }
    }
}