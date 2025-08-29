BeforeAll {
    . $PSScriptRoot\Install-ChocolateyPackages.ps1
    . $PSScriptRoot\Install-ChocolateyPackage.ps1
    . $PSScriptRoot\Write-ChocolateyCache.ps1
    . $PSScriptRoot\Read-ChocolateyCache.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    Mock Test-RunningAsAdmin { $true }
    Mock Write-ChocolateyCache { $true }
    Mock Write-Warning { }
    Mock Write-StatusMessage { } -Verifiable
    Mock Install-ChocolateyPackage { $true }
    Mock Write-Error {}
    Mock Write-Host {}
}

Describe "Install-ChocolateyPackages" {

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-RunningAsAdmin { $false }
            $result = Install-ChocolateyPackages -YamlData @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result | Should -Be $false
        }
    }

    Context "When Chocolatey packages config is missing" {
        It "Should write warning and return" {
            $yamlData = @{ devsetup = @{ dependencies = @{ } } }
            $result = Install-ChocolateyPackages -YamlData $yamlData
            $result | Should -Be $null
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "not found" }
        }
    }

    Context "When Write-ChocolateyCache fails" {
        It "Should write warning and return false" {
            Mock Write-ChocolateyCache { $false }
            $yamlData = @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @("git") } } } }
            $result = Install-ChocolateyPackages -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to write Chocolatey cache" }
        }
    }

    Context "When all packages install successfully (string format)" {
        It "Should process all packages and return true" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git", "nodejs")
                        }
                    }
                }
            }
            $result = Install-ChocolateyPackages -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 2 -Scope It
            #Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Object -match "installation completed" }
        }
    }

    Context "When all packages install successfully (object format)" {
        It "Should process all packages and return true" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                @{ name = "git"; version = "2.42.0" },
                                @{ name = "nodejs"; params = "/silent" }
                            )
                        }
                    }
                }
            }
            $result = Install-ChocolateyPackages -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 2 -Scope It
        }
    }

    Context "When some packages fail to install" {
        It "Should continue processing and return true" {
            $callCount = 0
            Mock Install-ChocolateyPackage -MockWith {
                param($PackageName, $Version, $Param)
                $callCount++
                if ($callCount -eq 1) { $true } else { $false }
            }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git", "nodejs")
                        }
                    }
                }
            }
            $result = Install-ChocolateyPackages -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 2 -Scope It
            #Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Object -eq "[FAILED]" }
        }
    }

    Context "When package entry is empty or missing name" {
        It "Should skip invalid entries and continue" {
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @(
                                $null,
                                @{ version = "1.0.0" },
                                "git"
                            )
                        }
                    }
                }
            }
            $result = Install-ChocolateyPackages -YamlData $yamlData
            $result | Should -Be $true
            Assert-MockCalled Install-ChocolateyPackage -Exactly 1 -Scope It
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "no name specified" }
        }
    }

    Context "When an exception occurs during installation" {
        It "Should write error and return false" {
            Mock Install-ChocolateyPackage { throw "Unexpected error" }
            $yamlData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @("git")
                        }
                    }
                }
            }
            $result = Install-ChocolateyPackages -YamlData $yamlData
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Error installing Chocolatey packages" }
        }
    }
}