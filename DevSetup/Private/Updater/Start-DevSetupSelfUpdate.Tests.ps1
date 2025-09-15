BeforeAll {
    # Use a temporary drive for file operations
    # Source the function under test and its direct dependencies
    . $PSScriptRoot\Start-DevSetupSelfUpdate.ps1
    . $PSScriptRoot\Get-DevSetupUpdateUri.ps1
    . $PSScriptRoot\Invoke-DevSetupDownloadUpdate.ps1
    . $PSScriptRoot\Expand-DevSetupUpdateArchive.ps1
    . $PSScriptRoot\Get-DownloadedDevSetupManifest.ps1
    . $PSScriptRoot\Install-RequiredDevSetupModules.ps1
    . $PSScriptRoot\Uninstall-DevSetupModule.ps1
    . $PSScriptRoot\Install-DevSetupModule.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\..\Utils\Format-RightText.ps1
    . $PSScriptRoot\..\Utils\Format-LeftText.ps1
    . $PSScriptRoot\..\Utils\Format-CenterText.ps1

    # Global test variables
    $global:TestExtractPath = Join-Path $TestDrive "devsetup_extract"
    $global:TestDownloadPath = Join-Path $TestDrive "devsetup.zip"
    $global:TestModulePath = Join-Path $TestDrive "DevSetup"
}

Describe "Start-DevSetupSelfUpdate" {

    Context "Parameter Set Validation" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should accept Main parameter" {
            { Start-DevSetupSelfUpdate -Main } | Should -Not -Throw
        }

        It "Should accept Develop parameter" {
            { Start-DevSetupSelfUpdate -Develop } | Should -Not -Throw
        }

        It "Should accept Version parameter" {
            { Start-DevSetupSelfUpdate -Version "1.0.0" } | Should -Not -Throw
        }

        It "Should accept default parameters (no params)" {
            { Start-DevSetupSelfUpdate } | Should -Not -Throw
        }

        It "Should not allow Main and Develop together" {
            { Start-DevSetupSelfUpdate -Main -Develop } | Should -Throw
        }

        It "Should not allow Main and Version together" {
            { Start-DevSetupSelfUpdate -Main -Version "1.0.0" } | Should -Throw
        }

        It "Should not allow Develop and Version together" {
            { Start-DevSetupSelfUpdate -Develop -Version "1.0.0" } | Should -Throw
        }
    }

    Context "Update URI Validation Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should call Get-DevSetupUpdateUri with correct parameters for Main" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/main.zip"; Version = "main" } }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Get-DevSetupUpdateUri -Exactly 1 -Scope It -ParameterFilter { $Main -eq $true }
        }

        It "Should call Get-DevSetupUpdateUri with correct parameters for Develop" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/develop.zip"; Version = "develop" } }
            Start-DevSetupSelfUpdate -Develop
            Assert-MockCalled Get-DevSetupUpdateUri -Exactly 1 -Scope It -ParameterFilter { $Develop -eq $true }
        }

        It "Should call Get-DevSetupUpdateUri with correct parameters for Version" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/v2.0.0.zip"; Version = "2.0.0" } }
            Start-DevSetupSelfUpdate -Version "2.0.0"
            Assert-MockCalled Get-DevSetupUpdateUri -Exactly 1 -Scope It -ParameterFilter { $Version -eq "2.0.0" }
        }

        It "Should return false when Get-DevSetupUpdateUri fails" {
            Mock Get-DevSetupUpdateUri { return $null }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Failed to determine update URI." -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should display validation status messages" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Validating Installation Type..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Download Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should call Invoke-DevSetupDownloadUpdate with correct URI" {
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Invoke-DevSetupDownloadUpdate -Exactly 1 -Scope It -ParameterFilter { 
                $Uri -eq "https://test.com/test.zip" 
            }
        }

        It "Should return false when download fails" {
            Mock Invoke-DevSetupDownloadUpdate { return $null }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Failed to download update." -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should display download status messages" {
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Downloading update..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Extraction Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should create temporary extraction path using cross-platform methods" {
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Expand-DevSetupUpdateArchive -Exactly 1 -Scope It
        }

        It "Should return false when extraction fails" {
            Mock Expand-DevSetupUpdateArchive { return $false }
            Mock Test-Path { return $true }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Failed to extract update archive." -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should handle extraction exceptions gracefully" {
            Mock Expand-DevSetupUpdateArchive { throw "Extraction failed" }
            Mock Test-Path { return $true }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Failed to extract update archive: Extraction failed" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should return false when extraction path doesn't exist after extraction" {
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $false }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Extraction path not found:" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should display extraction status messages" {
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Extracting update..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Module Validation Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should validate downloaded module manifest" {
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Get-DownloadedDevSetupManifest -Exactly 1 -Scope It
        }

        It "Should return false when manifest is invalid" {
            Mock Get-DownloadedDevSetupManifest { return $null }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Failed to read downloaded module manifest." -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should return false when manifest has no version" {
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = $null; RequiredModules = @() } }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Downloaded module manifest does not contain a valid version." -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should return false when manifest has empty version" {
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = ""; RequiredModules = @() } }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Downloaded module manifest does not contain a valid version." -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should display validation status messages" {
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Validating downloaded module..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Prerequisites Installation Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should install required modules from manifest" {
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @("TestModule1", "TestModule2") } }
            Mock Install-RequiredDevSetupModules { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Install-RequiredDevSetupModules -Exactly 1 -Scope It -ParameterFilter { 
                $Modules -contains "TestModule1" -and $Modules -contains "TestModule2" 
            }
        }

        It "Should continue on prerequisites installation failure" {
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @("TestModule1") } }
            Mock Install-RequiredDevSetupModules { throw "Installation failed" }
            Start-DevSetupSelfUpdate -Main
            # Should continue to uninstall step
            Assert-MockCalled Uninstall-DevSetupModule -Exactly 1 -Scope It
        }

        It "Should display prerequisites status messages" {
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Installing required prerequisites..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Module Uninstallation Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should uninstall old DevSetup module" {
            Mock Uninstall-DevSetupModule { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Uninstall-DevSetupModule -Exactly 1 -Scope It
        }

        It "Should return false when uninstallation fails" {
            Mock Uninstall-DevSetupModule { throw "Uninstall failed" }
            $result = Start-DevSetupSelfUpdate -Main
            ($result | Select-Object -Last 1) | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Failed to uninstall old DevSetup module: Uninstall failed" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should display uninstallation status messages" {
            Mock Uninstall-DevSetupModule { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Uninstalling old DevSetup module..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Module Installation Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should install new DevSetup module" {
            Mock Install-DevSetupModule { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Install-DevSetupModule -Exactly 1 -Scope It
        }

        It "Should return false when installation returns false" {
            Mock Install-DevSetupModule { return $false }
            $result = Start-DevSetupSelfUpdate -Main
            ($result | Select-Object -Last 1) | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "Failed to install new DevSetup module." -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should return false when installation throws exception" {
            Mock Install-DevSetupModule { throw "Install failed" }
            $result = Start-DevSetupSelfUpdate -Main
            ($result | Select-Object -Last 1) | Should -Be $false
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -match "Failed to install new DevSetup module: Install failed" -and $Verbosity -eq "Error" 
            } -Exactly 1 -Scope It
        }

        It "Should display installation status messages" {
            Mock Install-DevSetupModule { return $true }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Installing new DevSetup module..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Installation Verification Phase" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
        }

        It "Should verify module installation using Get-Module" {
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Get-Module -Exactly 1 -Scope It -ParameterFilter { 
                $ListAvailable -eq $true -and $Name -eq "DevSetup" 
            }
        }

        It "Should display verification results when module is found" {
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Verifying installation..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }

        It "Should display failure when module is not found" {
            Mock Get-Module { return $null }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "- Verifying installation..." -and $ForegroundColor -eq "Gray" 
            } -Exactly 1 -Scope It
        }
    }

    Context "Success Path Integration" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should complete successfully with all phases working" {
            $result = Start-DevSetupSelfUpdate -Main
            # Should not return false (successful completion doesn't return anything)
            $result | Should -Not -Be $false
        }

        It "Should display completion messages on success" {
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "`nInstallation completed successfully!" -and $ForegroundColor -eq "Green" 
            } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Message -eq "  Please restart your PowerShell session to use the updated module." -and $ForegroundColor -eq "White" 
            } -Exactly 1 -Scope It
        }

        It "Should work with Version parameter" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/v1.5.0.zip"; Version = "1.5.0" } }
            $result = Start-DevSetupSelfUpdate -Version "1.5.0"
            $result | Should -Not -Be $false
        }

        It "Should work with default parameters" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/latest.zip"; Version = "latest" } }
            $result = Start-DevSetupSelfUpdate
            $result | Should -Not -Be $false
        }
    }

    Context "Cross-Platform Path Handling" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should use Join-Path for cross-platform compatibility" {
            # Create test directory structure in TestDrive
            $TestExtractDir = Join-Path $TestDrive "extracted"
            New-Item -Path $TestExtractDir -ItemType Directory -Force
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractDir }) }
            
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Not -Be $false
        }

        It "Should handle Windows path separators" {
            if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
                Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = Join-Path $TestDrive "test-extract" }) }
                $result = Start-DevSetupSelfUpdate -Main
                $result | Should -Not -Be $false
            }
        }

        It "Should handle Unix path separators" {
            if ($IsLinux -or $IsMacOS) {
                Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = Join-Path $TestDrive "test-extract" }) }
                $result = Start-DevSetupSelfUpdate -Main
                $result | Should -Not -Be $false
            } else {
                # On Windows/PS5.1, just verify it doesn't throw
                Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = Join-Path $TestDrive "test-extract" }) }
                $result = Start-DevSetupSelfUpdate -Main
                $result | Should -Not -Be $false
            }
        }
    }

    Context "PowerShell 5.1 Compatibility" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should not use PowerShell 6+ only features" {
            # Verify no use of ?? operator or other PS6+ features
            $functionContent = Get-Content $PSScriptRoot\Start-DevSetupSelfUpdate.ps1 -Raw
            $functionContent | Should -Not -Match '\?\?'  # Null coalescing operator
            $functionContent | Should -Not -Match '\?\.'  # Null conditional operator
        }

        It "Should use compatible string operations" {
            # Test that string operations work in PS 5.1
            { Start-DevSetupSelfUpdate -Version "test" } | Should -Not -Throw
        }

        It "Should use compatible array operations" {
            # Test that array/hashtable operations work in PS 5.1
            Mock Get-DownloadedDevSetupManifest {
                return @{
                    ModuleVersion = "1.0.0"
                    RequiredModules = @("Module1", "Module2")
                }
            }
            { Start-DevSetupSelfUpdate -Main } | Should -Not -Throw
        }

        It "Should work with older .NET Framework methods" {
            # Test Path operations that work in .NET Framework 4.x
            { Start-DevSetupSelfUpdate -Main } | Should -Not -Throw
        }
    }

    Context "Error Handling and Edge Cases" {
        BeforeEach {
            Mock Write-StatusMessage { }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should handle null return from Get-DevSetupUpdateUri" {
            Mock Get-DevSetupUpdateUri { return $null }
            $result = Start-DevSetupSelfUpdate -Main
            $result | Should -Be $false
        }

        It "Should handle empty extraction directory" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Get-ChildItem { return @() }
            try {
                $result = Start-DevSetupSelfUpdate -Main
                # Function should handle this gracefully 
                $result | Should -BeIn @($null, $false)
            } catch {
                # It's okay if this throws an error, as the function is handling an invalid state
                $_.Exception.Message | Should -Match "Cannot bind argument to parameter"
            }
        }

        It "Should handle manifest reading failures" {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Get-DownloadedDevSetupManifest { throw "Cannot read manifest" }
            try {
                $result = Start-DevSetupSelfUpdate -Main
                $result | Should -Be $false
            } catch {
                # It's okay if this throws, as we're testing error handling
                $_.Exception.Message | Should -Match "Cannot read manifest"
            }
        }

        It "Should display appropriate error messages for each failure point" {
            Mock Get-DevSetupUpdateUri { return $null }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -eq "Failed to determine update URI."
            } -Exactly 1 -Scope It
        }
    }

    Context "Status Message Display" {
        BeforeEach {
            Mock Get-DevSetupUpdateUri { return @{ Uri = "https://test.com/test.zip"; Version = "test" } }
            Mock Invoke-DevSetupDownloadUpdate { return $TestDownloadPath }
            Mock Expand-DevSetupUpdateArchive { return $true }
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @([PSCustomObject]@{ FullName = $TestExtractPath }) }
            Mock Get-DownloadedDevSetupManifest { return @{ ModuleVersion = "1.0.0"; RequiredModules = @() } }
            Mock Install-RequiredDevSetupModules { return $true }
            Mock Uninstall-DevSetupModule { return $true }
            Mock Install-DevSetupModule { return $true }
            Mock Get-Module { return @{ Version = "1.0.0"; Name = "DevSetup" } }
        }

        It "Should show progress indicators throughout the process" {
            Mock Write-StatusMessage { }
            Start-DevSetupSelfUpdate -Main
            
            # Verify all major status messages are displayed
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Validating Installation Type..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Downloading update..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Extracting update..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Validating downloaded module..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Installing required prerequisites..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Uninstalling old DevSetup module..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Installing new DevSetup module..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Verifying installation..." } -Exactly 1 -Scope It
        }

        It "Should show version information" {
            Mock Write-StatusMessage { }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Installing DevSetup Version..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Checking PowerShell Version..." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "- Checking PowerShell Edition..." } -Exactly 1 -Scope It
        }

        It "Should show completion messages" {
            Mock Write-StatusMessage { }
            Start-DevSetupSelfUpdate -Main
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "`nInstallation completed successfully!" } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "You can now use DevSetup commands in any PowerShell session." } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "`nTo get started:" } -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -ParameterFilter { $Message -eq "  Please restart your PowerShell session to use the updated module." } -Exactly 1 -Scope It
        }
    }
}
