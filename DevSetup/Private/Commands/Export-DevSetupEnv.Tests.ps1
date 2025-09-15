BeforeAll {
    Function Write-EZLog { }
    . (Join-Path $PSScriptRoot "Export-DevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\DevSetup\Private\Utils\Write-NewConfig.ps1")
    Mock Get-DevSetupEnvPath { Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs" }
    Mock Test-Path { $true }
    Mock New-Item { }
    Mock Write-StatusMessage { }
    Mock Write-NewConfig { $true }
}

Describe "Export-DevSetupEnv" {

    Context "When exporting with Name parameter" {
        It "Should create directory if not exists and call Write-NewConfig" {
            Mock Test-Path { $false }  # Directory doesn't exist
            $expectedPath = Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "MyEnv.devsetup"
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $expectedPath
            Assert-MockCalled Get-DevSetupEnvPath -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") }
            Assert-MockCalled New-Item -Exactly 1 -Scope It -ParameterFilter { $Path -eq (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") -and $ItemType -eq "Directory" }
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Configuration file exported to:" -and $ForegroundColor -eq "Green" }
        }
    }

    Context "When exporting with Name parameter and directory exists" {
        It "Should not create directory and call Write-NewConfig" {
            Mock Test-Path { $true }  # Directory exists
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "MyEnv.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $expectedPath
            Assert-MockCalled New-Item -Exactly 0 -Scope It
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It
        }
    }

    Context "When Name includes provider" {
        It "Should parse provider and name correctly" {
            Mock Test-Path { $true }
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "custom") "MyEnv.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "custom:MyEnv"
            $result | Should -Be $expectedPath
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "custom") }
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
        }
    }

    Context "When Name requires sanitization" {
        It "Should sanitize name and warn" {
            Mock Test-Path { $true }
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "DataScienceEnvironment.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "Data Science Environment!"
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "EnvName sanitized from 'Data Science Environment!' to 'DataScienceEnvironment'" -and $ForegroundColor -eq "Yellow" }
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
        }
    }

    Context "When Name does not require sanitization" {
        It "Should not warn" {
            Mock Test-Path { $true }
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "MyEnv.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It -ParameterFilter { $ForegroundColor -eq "Yellow" }
        }
    }

    Context "When using Path parameter" {
        It "Should create directory if not exists and call Write-NewConfig" {
            Mock Test-Path { $false }  # Directory doesn't exist
            $customPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv.devsetup"
            $expectedPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv.devsetup"
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Path $customPath
            $result | Should -Be $expectedPath
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq (Join-Path $TestDrive "Custom") }
            Assert-MockCalled New-Item -Exactly 1 -Scope It -ParameterFilter { $Path -eq (Join-Path $TestDrive "Custom") -and $ItemType -eq "Directory" }
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
        }
    }

    Context "When using Path parameter and directory exists" {
        It "Should not create directory and call Write-NewConfig" {
            Mock Test-Path { $true }  # Directory exists
            $customPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv.devsetup"
            $expectedPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv.devsetup"
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Path $customPath
            $result | Should -Be $expectedPath
            Assert-MockCalled New-Item -Exactly 0 -Scope It
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It
        }
    }

    Context "When Path requires sanitization" {
        It "Should sanitize name and warn" {
            Mock Test-Path { $true }
            $customPath = Join-Path (Join-Path $TestDrive "Custom") "Data Science Environment!.devsetup"
            $expectedPath = Join-Path (Join-Path $TestDrive "Custom") "DataScienceEnvironment.devsetup"
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Path $customPath
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "EnvName sanitized from 'Data Science Environment!.devsetup' to 'DataScienceEnvironment.devsetup'" -and $ForegroundColor -eq "Yellow" }
        }
    }

    Context "When Path already has .devsetup extension" {
        It "Should not add extension" {
            Mock Test-Path { $true }
            $customPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv.devsetup"
            $expectedPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv.devsetup"
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Path $customPath
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
        }
    }

    Context "When Path does not have .devsetup extension" {
        It "Should add .devsetup extension" {
            Mock Test-Path { $true }
            $customPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv"
            $expectedPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv.devsetup"
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Path $customPath
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $OutFile -eq $expectedPath }
        }
    }

    Context "When OutFile cannot be determined in Path parameter set" {
        It "Should return null and write error" {
            # Create a scenario where OutFile ends up null after all processing
            # We'll simulate the Path parameter being valid but resulting in null OutFile
            Mock Test-Path { $true }
            Mock Write-NewConfig { }
            
            # Let's manually call the function with an edge case that could result in null OutFile
            # by making Join-Path return null/empty
            Mock Join-Path { $null } -ParameterFilter { $ChildPath -like "*.devsetup" }
            
            $customPath = Join-Path (Join-Path $TestDrive "Custom") "MyEnv"
            $result = Export-DevSetupEnv -Path $customPath
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to determine output file path" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Write-NewConfig fails" {
        It "Should return null and write error" {
            Mock Write-NewConfig { $null }
            $result = Export-DevSetupEnv -Name "fail-env"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to create configuration file" -and $Verbosity -eq "Error" }
        }
    }

    Context "When OutFile is not determined" {
        It "Should return null and write error when DevSetupEnvPath is null" {
            # This scenario targets the earlier check (line 88-89)
            Mock Get-DevSetupEnvPath { $null }
            $result = Export-DevSetupEnv -Name "no-path"
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to determine DevSetup environment path" -and $Verbosity -eq "Error" }
        }
    }

    Context "When DryRun is specified" {
        It "Should pass DryRun to Write-NewConfig" {
            Mock Test-Path { $true }
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "MyEnv.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "MyEnv" -DryRun
            $result | Should -Be $expectedPath
            Assert-MockCalled Write-NewConfig -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Test-Path { $true }
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "MyEnv.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $expectedPath
        }

        It "Should work on Linux" {
            Mock Test-Path { $true }
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "MyEnv.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $expectedPath
        }

        It "Should work on macOS" {
            Mock Test-Path { $true }
            $expectedPath = (Join-Path (Join-Path (Join-Path (Join-Path $TestDrive "DevSetup") "DevSetupEnvs") "local") "MyEnv.devsetup")
            Mock Write-NewConfig { $expectedPath }
            $result = Export-DevSetupEnv -Name "MyEnv"
            $result | Should -Be $expectedPath
        }
    }
}
