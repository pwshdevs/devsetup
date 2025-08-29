BeforeAll {
    . $PSScriptRoot\Read-ChocolateyCache.ps1
    . $PSScriptRoot\Write-ChocolateyCache.ps1
    . $PSScriptRoot\Get-ChocolateyCacheFile.ps1
    Mock Get-ChocolateyCacheFile { "C:\fakepath\choco.cache" }
    Mock Write-Debug { }
    Mock Write-Error { }
    Mock Write-ChocolateyCache { return $true }
}

Describe "Read-ChocolateyCache" {

    Context "When cache file exists and can be read" {
        It "Should return the cache data as an array of strings" {
            Mock Test-Path { param($Path) $true }
            Mock Get-Content { @("git|2.42.0", "nodejs|20.10.0") }
            $result = Read-ChocolateyCache
            $result | Should -Contain "git|2.42.0"
            $result | Should -Contain "nodejs|20.10.0"
        }
    }

    Context "When cache file does not exist and Write-ChocolateyCache succeeds" {
        It "Should create the cache file and return its contents" {
            Mock Test-Path { param($Path) $false }
            Mock Write-ChocolateyCache { return $true }
            Mock Get-Content { @("git|2.42.0") }
            $result = Read-ChocolateyCache
            $result | Should -Contain "git|2.42.0"
            Assert-MockCalled Write-ChocolateyCache -Exactly 1 -Scope It
        }
    }

    Context "When cache file does not exist and Write-ChocolateyCache fails" {
        It "Should throw an exception" {
            Mock Test-Path { param($Path) return $false }
            Mock Write-ChocolateyCache { return $false }
            { Read-ChocolateyCache } | Should -Throw "Failed to create Chocolatey cache file: C:\fakepath\choco.cache"
        }
    }

    Context "When reading cache file fails" {
        It "Should write error and return null" {
            Mock Test-Path { param($Path) $true }
            Mock Get-Content { throw "Read error" }
            $result = Read-ChocolateyCache
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to read Chocolatey cache file" }
        }
    }
}