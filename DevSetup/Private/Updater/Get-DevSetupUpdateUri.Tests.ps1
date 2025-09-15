BeforeAll {
    Function Invoke-WebRequest {
        param (
            [string]$Uri,
            [switch]$UseBasicParsing
        )
    }
    . $PSScriptRoot\Get-DevSetupUpdateUri.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
    Mock Invoke-WebRequest {
        if ($Uri -eq "https://api.github.com/repos/pwshdevs/devsetup/releases/latest") {
            return @{ Content = @(
                @{
                    zipball_url = "https://github.com/pwshdevs/devsetup/archive/latest.zip"
                    tag_name = "latest"
                }
            ) | ConvertTo-Json }
        } elseif ($Uri -eq "https://api.github.com/repos/pwshdevs/devsetup/releases") {
            return @{ Content = @(
                @{
                    zipball_url = "https://github.com/pwshdevs/devsetup/archive/v1.0.4.zip"
                    tag_name = "v1.0.4"
                }
                @{
                    zipball_url = "https://github.com/pwshdevs/devsetup/archive/v1.0.3.zip"
                    tag_name = "v1.0.3"
                }
                @{
                    zipball_url = "https://github.com/pwshdevs/devsetup/archive/v1.0.2.zip"
                    tag_name = "v1.0.2"
                }
            ) | ConvertTo-Json }
        } else {
            throw "Unexpected Uri: $Uri"
        }
    }
}

Describe "Get-DevSetupUpdateUri" {

    Context "When Main switch is used" {
        BeforeEach {
            Mock Write-StatusMessage { }
        }  
        It "Should not throw" {
            { Get-DevSetupUpdateUri -Main } | Should -Not -Throw
        }

        It "Should return the main branch URL" {
            $result = Get-DevSetupUpdateUri -Main
            $result.Uri | Should -Be "https://github.com/pwshdevs/devsetup/archive/main.zip"
            $result.Version | Should -Be "main"
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Main branch selected." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
        }
    }

    Context "When Develop switch is used" {
        BeforeEach {
            Mock Write-StatusMessage { }
        } 

        It "Should not throw" {
            { Get-DevSetupUpdateUri -Develop } | Should -Not -Throw
        }

        It "Should return the develop branch URL" {
            $result = Get-DevSetupUpdateUri -Develop
            $result.Uri | Should -Be "https://github.com/pwshdevs/devsetup/archive/develop.zip"
            $result.Version | Should -Be "develop"
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Development branch selected. This may be unstable." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
        }
    }
    Context "When no switch is used and version is latest" {
        BeforeEach {
            Mock Write-StatusMessage { }
        } 
        
        It "Should not throw" {
            { Get-DevSetupUpdateUri } | Should -Not -Throw
        }
        
        It "Should return the latest release URL" {
            $result = Get-DevSetupUpdateUri
            $result.Uri | Should -Be "https://github.com/pwshdevs/devsetup/archive/v1.0.4.zip"
            $result.Version | Should -Be "latest"
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq "https://api.github.com/repos/pwshdevs/devsetup/releases" -and $UseBasicParsing -eq $true } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Fetching release information from GitHub..." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Fetched 3 releases from GitHub." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Looking for version: latest" -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
        }
    }
    Context "When no switch is used and a specific version is given" {
        BeforeEach {
            Mock Write-StatusMessage { }
        }

        It "Should not throw" {
            { Get-DevSetupUpdateUri -Version "1.0.3" } | Should -Not -Throw
        }

        It "Should return the URI for that version if it exists" {
            $result = Get-DevSetupUpdateUri -Version "1.0.3"
            $result.Uri | Should -Be "https://github.com/pwshdevs/devsetup/archive/v1.0.3.zip"
            $result.Version | Should -Be "1.0.3"
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq "https://api.github.com/repos/pwshdevs/devsetup/releases" -and $UseBasicParsing -eq $true } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Fetching release information from GitHub..." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Fetched 3 releases from GitHub." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Looking for version: 1.0.3" -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
        }
        It "Should call write-statusmessage and return null if version does not exist" {
            $result = Get-DevSetupUpdateUri -Version "9.9.9"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter {
                $Verbosity -eq "Error" -and $Message -match "No release found matching version: 9.9.9"
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Fetching release information from GitHub..." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Fetched 3 releases from GitHub." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Looking for version: 9.9.9" -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
        }
    }

    Context "When multiple switches are used" {
        BeforeEach {
            Mock Write-StatusMessage { }
        }        
        It "Should throw an error due to parameter set conflict for Main and Develop" {
            { Get-DevSetupUpdateUri -Main -Develop } | Should -Throw
        }
        It "Should throw an error due to parameter set conflict for Main and Version" {
            { Get-DevSetupUpdateUri -Main -Version "1.0.3" } | Should -Throw
        }
        It "Should throw an error due to parameter set conflict for Develop and Version" {
            { Get-DevSetupUpdateUri -Develop -Version "1.0.3" } | Should -Throw
        }
    }

    Context "When no parameters are provided" {
        BeforeEach {
            Mock Write-StatusMessage { }
        }
        It "Should default to latest version" {
            $result = Get-DevSetupUpdateUri -Version $null
            $result.Uri | Should -Be "https://github.com/pwshdevs/devsetup/archive/v1.0.4.zip"
            $result.Version | Should -Be "latest"
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq "https://api.github.com/repos/pwshdevs/devsetup/releases" -and $UseBasicParsing -eq $true } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Fetching release information from GitHub..." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Fetched 3 releases from GitHub." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Looking for version: latest" -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
        }
    }
}