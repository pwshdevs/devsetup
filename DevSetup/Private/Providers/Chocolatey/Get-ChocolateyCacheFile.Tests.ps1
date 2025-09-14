BeforeAll {
    . $PSScriptRoot\Get-ChocolateyCacheFile.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-DevSetupCachePath.ps1
}

Describe "Get-ChocolateyCacheFile" {

    Context "When Get-DevSetupCachePath succeeds" {
        It "Should return the correct cache file path" {
            $expectedCachePath = Join-Path $TestDrive ".cache"
            $expectedCacheFile = Join-Path $expectedCachePath "chocolatey.cache"
            
            Mock Get-DevSetupCachePath { return $expectedCachePath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -Be $expectedCacheFile
            Assert-MockCalled Get-DevSetupCachePath -Times 1 -Scope It
        }
    }

    Context "When Get-DevSetupCachePath returns null" {
        It "Should return null and log error message" {
            Mock Get-DevSetupCachePath { return $null }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "Failed to retrieve DevSetup cache path." -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Get-DevSetupCachePath returns empty string" {
        It "Should return null and log error message" {
            Mock Get-DevSetupCachePath { return "" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "Failed to retrieve DevSetup cache path." -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Get-DevSetupCachePath returns whitespace string" {
        It "Should return null and log error message" {
            Mock Get-DevSetupCachePath { return "   " }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "Failed to retrieve DevSetup cache path." -and $Verbosity -eq "Error" 
            }
        }
    }

    Context "When Get-DevSetupCachePath throws an exception" {
        It "Should handle exception and return null" {
            Mock Get-DevSetupCachePath { throw "Cache path access error" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error retrieving DevSetup cache path:" -and $Verbosity -eq "Error" 
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "at"
            }
        }
    }

    Context "When Join-Path throws an exception" {
        It "Should handle Join-Path exception and return null" {
            $cachePath = "InvalidPath:"
            
            Mock Get-DevSetupCachePath { return $cachePath }
            Mock Join-Path { throw "Invalid path error" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error constructing Chocolatey cache file path:" -and $Verbosity -eq "Error" 
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "at"
            }
        }
    }

    Context "Path construction validation" {
        It "Should correctly combine cache path and chocolatey.cache filename" {
            $baseCachePath = Join-Path $TestDrive "custom" "cache" "directory"
            $expectedResult = Join-Path $baseCachePath "chocolatey.cache"
            
            Mock Get-DevSetupCachePath { return $baseCachePath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -Be $expectedResult
            $result | Should -Match "chocolatey\.cache$"
        }
    }

    Context "Cross-platform path handling" {
        It "Should handle Unix-style paths correctly" {
            $unixCachePath = Join-Path $TestDrive "home" "user" ".devsetup" ".cache"
            $expectedResult = Join-Path $unixCachePath "chocolatey.cache"
            
            Mock Get-DevSetupCachePath { return $unixCachePath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -Be $expectedResult
            $result.EndsWith("chocolatey.cache") | Should -BeTrue
        }

        It "Should handle Windows-style paths correctly" {
            $windowsCachePath = Join-Path $TestDrive "Users" "TestUser" "AppData" "Local" "DevSetup" "cache"
            $expectedResult = Join-Path $windowsCachePath "chocolatey.cache"
            
            Mock Get-DevSetupCachePath { return $windowsCachePath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -Be $expectedResult
            $result.EndsWith("chocolatey.cache") | Should -BeTrue
        }
    }

    Context "Return value validation" {
        It "Should return a string type" {
            $cachePath = Join-Path $TestDrive "cache"
            
            Mock Get-DevSetupCachePath { return $cachePath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -BeOfType [string]
        }

        It "Should return null (not empty string) on errors" {
            Mock Get-DevSetupCachePath { throw "Error" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyCacheFile
            
            $result | Should -BeNullOrEmpty
            $result | Should -BeExactly $null
        }
    }
}