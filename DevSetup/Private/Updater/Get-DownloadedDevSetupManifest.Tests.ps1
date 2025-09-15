BeforeAll {
    Function Import-PowerShellDataFile {
        Param([string]$Path)
     }
    $global:LASTEXITCODE = 0
    . $PSScriptRoot\Get-DownloadedDevSetupManifest.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
}

Describe "Get-DownloadedDevSetupManifest" {
    Context "When Invalid flags are used" {
        It "Should throw an error due to missing parameter values" {
            { Get-DownloadedDevSetupManifest -ModulePath $null} | Should -Throw
        }
        It "Should throw an error when ModulePath is blank" {
            { Get-DownloadedDevSetupManifest -ModulePath "" } | Should -Throw
        }
    }

    Context "When a valid ModulePath is provided" {
        BeforeEach {
            Mock Write-StatusMessage { }
        }
        It "Should return null when the ModulePath does not exist" {
            Mock Test-Path { $false } -ParameterFilter { $Path -eq (Join-Path $TestDrive "nonexistent") }
            $result = Get-DownloadedDevSetupManifest -ModulePath (Join-Path $TestDrive "nonexistent")
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Module path not found: $([regex]::Escape((Join-Path $TestDrive "nonexistent")))" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        
        }

        It "Should return null when the ModulePath is not a directory" {
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "file.txt") }
            Mock Get-Item { return @{ PSIsContainer = $false } } -ParameterFilter { $Path -eq (Join-Path $TestDrive "file.txt") }
            $result = Get-DownloadedDevSetupManifest -ModulePath (Join-Path $TestDrive "file.txt")
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Module path is not a directory: $([regex]::Escape((Join-Path $TestDrive "file.txt")))" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should return null when the DevSetup.psd1 file is missing" {
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "nodir") }
            Mock Get-Item { return @{ PSIsContainer = $true } } -ParameterFilter { $Path -eq (Join-Path $TestDrive "nodir") }
            Mock Test-Path { $false } -ParameterFilter { $Path -eq (Join-Path (Join-Path $TestDrive "nodir") "DevSetup.psd1") }
            $result = Get-DownloadedDevSetupManifest -ModulePath (Join-Path $TestDrive "nodir")
            $result | Should -Be $null
        }

        It "Should return null when the DevSetup.psd1 file does not contain a Version" {
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "noversion") }
            Mock Get-Item { return @{ PSIsContainer = $true } } -ParameterFilter { $Path -eq (Join-Path $TestDrive "noversion") }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path (Join-Path $TestDrive "noversion") "DevSetup.psd1") }
            $result = Get-DownloadedDevSetupManifest -ModulePath (Join-Path $TestDrive "noversion")
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Failed to read version from module manifest at path: $([regex]::Escape((Join-Path (Join-Path $TestDrive "noversion") "DevSetup.psd1")))" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should return null when importing the DevSetup.psd1 file throws an error" {
            Mock Write-StatusMessage { }            
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "error") }
            Mock Get-Item { return @{ PSIsContainer = $true } } -ParameterFilter { $Path -eq (Join-Path $TestDrive "error") }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path (Join-Path $TestDrive "error") "DevSetup.psd1") }
            Mock Import-PowerShellDataFile { throw "Simulated import error" }
            $result = Get-DownloadedDevSetupManifest -ModulePath (Join-Path $TestDrive "error")
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Error reading module manifest at path:" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" 
            } -Exactly 2 -Scope It
        }

        It "Should return the version string when the DevSetup.psd1 file is valid" {
            Mock Write-StatusMessage {
                Write-Error $Message
            }
            $FolderPath = Join-Path $TestDrive "valid"
            $PsdPath = Join-Path $FolderPath "DevSetup.psd1"
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $FolderPath }
            Mock Get-Item { return @{ PSIsContainer = $true } } -ParameterFilter { $Path -eq $FolderPath }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $PsdPath }
            Mock Import-PowerShellDataFile { return @{ ModuleVersion = [version]"1.2.3" } } -ParameterFilter { $Path -eq $PsdPath }
            $result = Get-DownloadedDevSetupManifest -ModulePath $FolderPath
            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
            $result.ModuleVersion | Should -BeOfType [version]
        }
    }
}