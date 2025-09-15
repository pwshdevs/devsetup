BeforeAll {
    $global:LASTEXITCODE = 0
    Function Expand-Archive {
        param (
            [string]$Path,
            [string]$DestinationPath,
            [switch]$Force
        )
    }

    Mock Expand-Archive {
        switch($Path) {
            (Join-Path $TestDrive "test.zip") { 
                # Simulate successful expansion
                #Write-Output "test.zip expanded successfully"
                $global:LASTEXITCODE = 0
                return
            }
            (Join-Path $TestDrive "bad.zip") {
                #Write-Output "bad.zip encountered an error"
                # Simulate failed expansion
                throw "Simulated bad zip"
                return
            }
            (Join-Path $TestDrive "testdest.zip") {
                switch($DestinationPath) {
                    (Join-Path $TestDrive "extracted") {
                        #Write-Output "testdest.zip expanded successfully"
                        # Simulate successful extraction
                        $global:LASTEXITCODE = 0
                        return
                    } 
                    (Join-Path $TestDrive "badextract") {
                        #Write-Output "testdest.zip encountered an error"
                        # Simulate failed extraction
                        throw "Simulated bad destination"
                        return
                    } 
                    default {
                        #Write-Output "Invalid destination: $DestinationPath"
                        # Simulate invalid destination
                        $global:LASTEXITCODE = 1
                        throw "Invalid destination: $DestinationPath"
                    } 
                }
            }
            default {
                Write-Error "File not found: $Path"
                # Simulate file not found
                $global:LASTEXITCODE = 1
                throw "File not found: $Path"
            }
        }
        # Simulate successful expansion
        $global:LASTEXITCODE = 1
    }
    . $PSScriptRoot\Expand-DevSetupUpdateArchive.ps1
    . $PSScriptRoot\..\Utils\Write-StatusMessage.ps1
}

Describe "Expand-DevSetupUpdateArchive" {

    Context "When the archive file does not exist" {
        It "Should return false and log an error" {
            Mock Write-StatusMessage { }
            $Archive = (Join-Path $TestDrive "nonexistent.zip")
            $result = Expand-DevSetupUpdateArchive -Path $Archive -DestinationPath (Join-Path $TestDrive "temp")
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter {
                $Message -match "Archive file not found at path: $([regex]::Escape($Archive))" -and $Verbosity -eq "Error"
            }
        }
    }

    Context "When the archive expansion fails" {
        It "Should return false and log an error" {
            Mock Write-StatusMessage { }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "bad.zip") }
            $badArchive = (Join-Path $TestDrive "bad.zip")
            $goodDestination = (Join-Path $TestDrive "extracted")
            $result = Expand-DevSetupUpdateArchive -Path $badArchive -DestinationPath $goodDestination
            $result | Should -Be $false
            Assert-MockCalled Expand-Archive -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $badArchive -and $DestinationPath -eq $goodDestination -and $Force
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter {
                $Message -match "Expanding archive file from $([regex]::Escape($badArchive)) to $([regex]::Escape($goodDestination))" -and $Verbosity -eq "Debug"
            } -Exactly 1
        }
    }

    Context "When the archive expansion fails with bad destination" {
        It "Should return false and log an error" {
            Mock Write-StatusMessage { }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "testdest.zip") }
            $goodArchive = (Join-Path $TestDrive "testdest.zip")
            $badDestination = (Join-Path $TestDrive "badextract")
            $result = Expand-DevSetupUpdateArchive -Path $goodArchive -DestinationPath $badDestination
            $result | Should -Be $false
            Assert-MockCalled Expand-Archive -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $goodArchive -and $DestinationPath -eq $badDestination -and $Force
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter {
                $Message -match "Expanding archive file from $([regex]::Escape($goodArchive)) to $([regex]::Escape($badDestination))" -and $Verbosity -eq "Debug"
            } -Exactly 1
        }
    }

    Context "When the archive expansion fails with invalid destination" {
        It "Should return false and log an error" {
            Mock Write-StatusMessage { }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "testdest.zip") }
            $goodArchive = (Join-Path $TestDrive "testdest.zip")
            $invalidDestination = (Join-Path $TestDrive "invalid\path")
            $result = Expand-DevSetupUpdateArchive -Path $goodArchive -DestinationPath $invalidDestination
            $result | Should -Be $false
            Assert-MockCalled Expand-Archive -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $goodArchive -and $DestinationPath -eq $invalidDestination -and $Force
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter {
                $Message -match "Expanding archive file from $([regex]::Escape($goodArchive)) to $([regex]::Escape($invalidDestination))" -and $Verbosity -eq "Debug"
            } -Exactly 1
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter {
                $Message -match "Failed to expand archive:" -and $Verbosity -eq "Error"
            } -Exactly 1
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter {
                $Verbosity -eq "Error"
            } -Exactly 2
        }
    }

    Context "When the archive expansion succeeds" {
        It "Should return true and log debug messages" {
            Mock Write-StatusMessage { }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq (Join-Path $TestDrive "test.zip") }
            $goodArchive = (Join-Path $TestDrive "test.zip")
            $goodDestination = (Join-Path $TestDrive "extracted")
            $result = Expand-DevSetupUpdateArchive -Path $goodArchive -DestinationPath $goodDestination
            $result | Should -Be $true
            Assert-MockCalled Expand-Archive -Exactly 1 -Scope It -ParameterFilter {
                $Path -eq $goodArchive -and $DestinationPath -eq $goodDestination -and $Force
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter {
                $Message -match "Expanding archive file from $([regex]::Escape($goodArchive)) to $([regex]::Escape($goodDestination))" -and $Verbosity -eq "Debug"
            } -Exactly 1
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter {
                $Message -match "Expansion completed successfully." -and $Verbosity -eq "Debug"
            } -Exactly 1
        }
    }
}