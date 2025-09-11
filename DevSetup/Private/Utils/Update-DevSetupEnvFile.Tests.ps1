BeforeAll {
    Function ConvertTo-Yaml { }
    . (Join-Path $PSScriptRoot "Update-DevSetupEnvFile.ps1")
    . (Join-Path $PSScriptRoot "Write-StatusMessage.ps1")
    Mock Write-StatusMessage { }
    Mock ConvertTo-Yaml { "mocked yaml content" }
    Mock Set-Content { }
}

Describe "Update-DevSetupEnvFile" {

    Context "When DevSetupEnvData is null" {
        It "Should throw" {
            { Update-DevSetupEnvFile -EnvFilePath "$TestDrive\test.env" -DevSetupEnvData $null } | Should -Throw
        }
    }

    Context "When DevSetupEnvData is invalid type" {
        It "Should write error and return" {
            Mock Test-Path { return $true }
            Update-DevSetupEnvFile -EnvFilePath "$TestDrive\test.env" -DevSetupEnvData "invalid string"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Invalid data format" -and $Verbosity -eq "Error" }
            Assert-MockCalled ConvertTo-Yaml -Exactly 0 -Scope It
            Assert-MockCalled Set-Content -Exactly 0 -Scope It
        }
    }

    Context "When ConvertTo-Yaml throws exception" {
        It "Should write error and return" {
            Mock Test-Path { return $true }
            Mock ConvertTo-Yaml { throw "YAML conversion failed" }
            Update-DevSetupEnvFile -EnvFilePath "$TestDrive\test.env" -DevSetupEnvData @{ key = "value" }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
            Assert-MockCalled Set-Content -Exactly 0 -Scope It
        }
    }

    Context "When ShouldProcess is false" {
        It "Should not write to file" {
            $envFile = "$TestDrive\test.env"
            New-Item -ItemType File -Path $envFile
            Update-DevSetupEnvFile -EnvFilePath $envFile -DevSetupEnvData @{ key = "value" } -WhatIf
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Set-Content -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It -ParameterFilter { $Message -match "Environment file updated successfully" }
        }
    }

    Context "When Set-Content throws exception" {
        It "Should write error and return" {
            Mock Set-Content { throw "Write failed" }
            $envFile = "$TestDrive\test.env"
            New-Item -ItemType File -Path $envFile
            Update-DevSetupEnvFile -EnvFilePath $envFile -DevSetupEnvData @{ key = "value" }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
            Assert-MockCalled Set-Content -Exactly 1 -Scope It
        }
    }

    Context "When update succeeds with Hashtable" {
        It "Should convert to YAML and write file" {
            $envFile = "$TestDrive\test.env"
            New-Item -ItemType File -Path $envFile
            Update-DevSetupEnvFile -EnvFilePath $envFile -DevSetupEnvData @{ key = "value" }
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Set-Content -Exactly 1 -Scope It -ParameterFilter { $Path -eq $envFile -and $Encoding -eq ([System.Text.Encoding]::UTF8) -and $Value -eq "mocked yaml content" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file updated successfully" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When update succeeds with PSCustomObject" {
        It "Should convert to YAML and write file" {
            $envFile = "$TestDrive\test.env"
            New-Item -ItemType File -Path $envFile
            $data = [PSCustomObject]@{ key = "value" }
            Update-DevSetupEnvFile -EnvFilePath $envFile -DevSetupEnvData $data
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Set-Content -Exactly 1 -Scope It -ParameterFilter { $Path -eq $envFile -and $Encoding -eq ([System.Text.Encoding]::UTF8) -and $Value -eq "mocked yaml content" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file updated successfully" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When file path is empty" {
        It "Should throw" {
            { Update-DevSetupEnvFile -EnvFilePath "" -DevSetupEnvData @{ key = "value" } } | Should -Throw
        }
    }

    Context "When data is empty Hashtable" {
        It "Should process empty data" {
            $envFile = "$TestDrive\test.env"
            New-Item -ItemType File -Path $envFile
            Update-DevSetupEnvFile -EnvFilePath $envFile -DevSetupEnvData @{}
            Assert-MockCalled ConvertTo-Yaml -Exactly 1 -Scope It
            Assert-MockCalled Set-Content -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file updated successfully" -and $Verbosity -eq "Debug" }
        }
    }
}
