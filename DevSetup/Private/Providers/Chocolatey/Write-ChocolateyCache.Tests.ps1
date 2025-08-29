BeforeAll {
    . $PSScriptRoot\Write-ChocolateyCache.ps1
    . $PSScriptRoot\Test-ChocolateyInstalled.ps1
    . $PSScriptRoot\Get-ChocolateyCacheFile.ps1
    Mock Write-Error { }
    Mock Write-Debug { }
}

Describe "Write-ChocolateyCache" {

    Context "When Chocolatey is not installed" {
        It "Should return false and write error" {
            Mock Test-ChocolateyInstalled { return $false }
            Mock Get-ChocolateyCacheFile { return "C:\fakepath\choco.cache" }
            $result = Write-ChocolateyCache
            $result | Should -Be $false
        }
    }

    Context "When cache file is written successfully" {
        It "Should return true and write debug" {
            Mock Test-ChocolateyInstalled { return $true }
            Mock Get-ChocolateyCacheFile { return "C:\fakepath\choco.cache" }
            Mock Invoke-Expression { "git|2.42.0`nnodejs|20.10.0" }
            $script:setContentCalled = $false
            Mock Set-Content -MockWith {
                param($Path, $Value, $Force)
                $script:setContentCalled = $true
            }
            $result = Write-ChocolateyCache
            $result | Should -Be $true
            $script:setContentCalled | Should -Be $true
        }
    }

    Context "When writing cache file fails" {
        It "Should return false and write error" {
            Mock Test-ChocolateyInstalled { return $true }
            Mock Get-ChocolateyCacheFile { return "C:\fakepath\choco.cache" }
            Mock Invoke-Expression { "git|2.42.0`nnodejs|20.10.0" }
            Mock Set-Content { throw "Failed to write file" }
            $result = Write-ChocolateyCache
            $result | Should -Be $false
        }
    }

    Context "When choco command throws an exception" {
        It "Should return false and write error" {
            Mock Test-ChocolateyInstalled { return $true }
            Mock Get-ChocolateyCacheFile { return "C:\fakepath\choco.cache" }
            Mock Invoke-Expression { throw "choco failed" }
            $result = Write-ChocolateyCache
            $result | Should -Be $false
        }
    }
}