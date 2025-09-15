BeforeAll {
    $global:LASTEXITCODE = 0;
    Function Invoke-WebRequest {
        param (
            [string]$Uri,
            [string]$OutFile
        )
        if($uri -eq "http://api.github.com/repos/pwshdevs/devsetup/zipball/v1.0.0.zip" -or $uri -eq "http://api.github.com/repos/pwshdevs/devsetup/archive/main.zip" -or
           $uri -eq "http://api.github.com/repos/pwshdevs/devsetup/zipball/v1.0.2.zip" -or $uri -eq "http://api.github.com/repos/pwshdevs/devsetup/archive/develop.zip") {
            $global:LASTEXITCODE = 0
            # Simulate successful download by creating an empty file
            New-Item -Path $OutFile -ItemType File -Force | Out-Null
        } elseif($Uri -eq "http://api.github.com/repos/pwshdevs/devsetup/zipball/v1.0.3.zip") {
            # Simulate download but file not found after download
            $global:LASTEXITCODE = 0
        } elseif($Uri -eq "http://api.github.com/repos/pwshdevs/devsetup/zipball/write-fail.zip") {
            $global:LASTEXITCODE = 1
            throw "Unable to save file"
        } else {
            $global:LASTEXITCODE = 1
        }
    }
    $global:ArchivePath = Join-Path $TestDrive "devsetup.zip"
    . $PSScriptRoot\Invoke-DevSetupDownloadUpdate.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
}

Describe "Invoke-DevSetupDownloadUpdate" {

    Context "When Invalid flags are used" {
        BeforeEach {
            Mock Write-StatusMessage { }
        }  
        It "Should throw an error due to missing parameter values" {
            { Invoke-DevSetupDownloadUpdate -Uri } | Should -Throw
        }
        It "Should throw an error when both Uri is blank" {
            { Invoke-DevSetupDownloadUpdate -Uri "" } | Should -Throw
        }
    }

    Context "When Invalid Url is provided" {
        BeforeEach {
            Mock Write-StatusMessage { }
        }
        It "Should return false and log error for invalid URL" {
            $result = Invoke-DevSetupDownloadUpdate -Uri "https://invalid-url.com/file.zip"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Invalid download URL: https://invalid-url.com/file.zip" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }
    }

    Context "When Valid Url is provided" {
        BeforeEach {
            Mock Write-StatusMessage {
            }
            Mock Join-Path {
                return $ArchivePath
            }
        }
        AfterEach {
            if (Test-Path $ArchivePath) {
                Remove-Item $ArchivePath -Force
            }
        }
        It "Should return true and log info for valid URL" {
            $result = Invoke-DevSetupDownloadUpdate -Uri "http://api.github.com/repos/pwshdevs/devsetup/zipball/v1.0.0.zip"
            $result | Should -Be $ArchivePath
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Downloading update to temporary path: $([regex]::Escape($ArchivePath))" -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Starting download from http://api.github.com/repos/pwshdevs/devsetup/zipball/v1.0.0.zip to $([regex]::Escape($ArchivePath))" -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Download completed successfully." -and $Verbosity -eq "Debug" 
            } -Exactly 1 -Scope It
        }

        It "Should return false and log error if invoke-webrequest throws" {
            $result = Invoke-DevSetupDownloadUpdate -Uri "http://api.github.com/repos/pwshdevs/devsetup/zipball/write-fail.zip"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Failed to download update: Unable to save file" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" 
            } -Exactly 2 -Scope It
        }
    }

    Context "When Valid Url is provided but file is missing after download" {
        BeforeEach {
            Mock Write-StatusMessage {
            }
            Mock Join-Path {
                return $ArchivePath
            }
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $ArchivePath }
        }
        AfterEach {
            if (Test-Path $ArchivePath) {
                Remove-Item $ArchivePath -Force
            }
        }
        It "Should return false and log error if file is missing after download" {
            $result = Invoke-DevSetupDownloadUpdate -Uri "http://api.github.com/repos/pwshdevs/devsetup/zipball/v1.0.3.zip"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Download completed but file not found at $([regex]::Escape($ArchivePath))" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -ParameterFilter { $Path -eq $ArchivePath } -Exactly 1 -Scope It
        }
    }
}