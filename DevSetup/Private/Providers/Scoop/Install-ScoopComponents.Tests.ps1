BeforeAll {
    . $PSScriptRoot\Install-ScoopComponents.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Write-ScoopCache.ps1
    . $PSScriptRoot\Install-ScoopBucket.ps1
    . $PSScriptRoot\Install-ScoopPackage.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Write-StatusMessage { }
    Mock Write-Host {}
    Mock Write-Error {}
}

Describe "Install-ScoopComponents" {

    Context "When Scoop is not installed" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $false }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ 
                buckets = @("extras")
                packages = @("git") } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When Scoop configuration is missing" {
        It "Should return false and warn" {
            Mock Test-ScoopInstalled { return $true }
            $yamlData = @{ devsetup = @{ dependencies = @{ } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When Write-ScoopCache fails" {
        It "Should return false and error" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $false }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ 
                buckets = @("extras")
                packages = @("git") } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $false
        }
    }

    Context "When only buckets are present and all install succeed" {
        It "Should return true and process all buckets" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopBucket { return $true }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ buckets = @("extras", "versions") } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When only packages are present and all install succeed" {
        It "Should return true and process all packages" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopPackage { return $true }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ packages = @("git", "nodejs") } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When buckets and packages are present and some installs fail" {
        It "Should return true and report failures" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            $bucketCallCount = 0
            Mock Install-ScoopBucket -MockWith {
                $bucketCallCount++
                if ($bucketCallCount -eq 1) { return $false } else { return $true }
            }
            $packageCallCount = 0
            Mock Install-ScoopPackage -MockWith {
                $packageCallCount++
                if ($packageCallCount -eq 2) { return $false } else { return $true }
            }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ 
                buckets = @("extras", "versions")
                packages = @("git", "nodejs") } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When no buckets or packages are present" {
        It "Should return true and skip package installation" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When an exception occurs during package install" {
        It "Should catch and continue, returning true" {
            Mock Test-ScoopInstalled { return $true }
            Mock Write-ScoopCache { return $true }
            Mock Install-ScoopBucket { return $true }
            Mock Install-ScoopPackage { throw "Unexpected error" }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ packages = @("git", "nodejs") } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $true
        }
    }

    Context "When an exception occurs in the main try block" {
        It "Should return false" {
            Mock Test-ScoopInstalled { throw "Critical error" }
            $yamlData = @{ devsetup = @{ dependencies = @{ scoop = @{ 
                buckets = @("extras")
                packages = @("git") } } } }
            $result = Install-ScoopComponents -YamlData $yamlData
            $result | Should -Be $false
        }
    }
}