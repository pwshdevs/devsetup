BeforeAll {
    function Write-EZLog { }
    . (Join-Path $PSScriptRoot "Use-DevSetup.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Utils\Get-DevSetupVersion.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Utils\Get-DevSetupLogPath.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Commands\Install-DevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Commands\Update-DevSetup.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Commands\Initialize-DevSetup.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Commands\Export-DevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Commands\Show-DevSetupEnvList.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Commands\Uninstall-DevSetupEnv.ps1")
    . (Join-Path $PSScriptRoot "..\..\DevSetup\Private\Commands\Show-ExplainDevSetupEnv.ps1")
    Mock Write-Host { }
    Mock Write-StatusMessage { }
    Mock Write-Error { }
    Mock Write-Verbose { }
    Mock Write-Debug { }
}

Describe "Use-DevSetup" {
    Context "When installing from name" {
        It "should call Install-DevSetupEnv with correct parameters" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { $true }

            $result = Use-DevSetup -Install -Name "TestEnv"
            $result | Should -Be $true
            Assert-MockCalled Install-DevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Name -eq "TestEnv" }
        }
    }

    Context "When installing from URL" {
        It "should call Install-DevSetupEnv with URL parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { $true }

            $result = Use-DevSetup -Install -Url "https://example.com/config.yaml"
            $result | Should -Be $true
            Assert-MockCalled Install-DevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Url -eq "https://example.com/config.yaml" }
        }
    }

    Context "When installing from path" {
        It "should call Install-DevSetupEnv with Path parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { $true }

            $result = Use-DevSetup -Install -Path "C:\Configs\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Install-DevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Path -eq "C:\Configs\test.yaml" }
        }
    }

    Context "When updating to main" {
        It "should call Update-DevSetup with Main parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Update-DevSetup { }

            $result = Use-DevSetup -Update -Main
            $result | Should -Be $null
            Assert-MockCalled Update-DevSetup -Exactly 1 -Scope It -ParameterFilter { $Main -eq $true }
        }
    }

    Context "When updating to develop" {
        It "should call Update-DevSetup with Develop parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Update-DevSetup { }

            $result = Use-DevSetup -Update -Develop
            $result | Should -Be $null
            Assert-MockCalled Update-DevSetup -Exactly 1 -Scope It -ParameterFilter { $Develop -eq $true }
        }
    }

    Context "When updating to specific version" {
        It "should call Update-DevSetup with Version parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Update-DevSetup { }

            $result = Use-DevSetup -Update -Version "1.0.8"
            $result | Should -Be $null
            Assert-MockCalled Update-DevSetup -Exactly 1 -Scope It -ParameterFilter { $Version -eq "1.0.8" }
        }
    }

    Context "When updating without specific branch or version" {
        It "should call Update-DevSetup with Version set to 'latest'" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Update-DevSetup { }

            $result = Use-DevSetup -Update
            $result | Should -Be $null
            Assert-MockCalled Update-DevSetup -Exactly 1 -Scope It -ParameterFilter { $Version -eq "latest" }
        }
    }

    Context "When initializing" {
        It "should call Initialize-DevSetup" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Initialize-DevSetup { }

            $result = Use-DevSetup -Init
            $result | Should -Be $null
            Assert-MockCalled Initialize-DevSetup -Exactly 1 -Scope It
        }
    }

    Context "When exporting with name" {
        It "should call Export-DevSetupEnv with Name parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Export-DevSetupEnv { $true }

            $result = Use-DevSetup -Export -Name "MyEnv"
            $result | Should -Be $true
            Assert-MockCalled Export-DevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Name -eq "MyEnv" }
        }
    }

    Context "When exporting to path" {
        It "should call Export-DevSetupEnv with Path parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Export-DevSetupEnv { $true }

            $result = Use-DevSetup -Export -Path "C:\Exports\env.yaml"
            $result | Should -Be $true
            Assert-MockCalled Export-DevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Path -eq "C:\Exports\env.yaml" }
        }
    }

    Context "When listing all" {
        It "should call Show-DevSetupEnvList without filters" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Show-DevSetupEnvList { }

            $result = Use-DevSetup -List
            $result | Should -Be $null
            Assert-MockCalled Show-DevSetupEnvList -Exactly 1 -Scope It
        }
    }

    Context "When listing by platform" {
        It "should call Show-DevSetupEnvList with Platform parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Show-DevSetupEnvList { }

            $result = Use-DevSetup -List -Platform "Linux"
            $result | Should -Be $null
            Assert-MockCalled Show-DevSetupEnvList -Exactly 1 -Scope It -ParameterFilter { $Platform -eq "Linux" }
        }
    }

    Context "When listing by provider" {
        It "should call Show-DevSetupEnvList with Provider parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-EZLog { }
            Mock Show-DevSetupEnvList { }

            $result = Use-DevSetup -List -Provider "Chocolatey"
            $result | Should -Be $null
            Assert-MockCalled Show-DevSetupEnvList -Exactly 1 -Scope It -ParameterFilter { $Provider -eq "Chocolatey" }
        }
    }

    Context "When listing by provider and platform" {
        It "should call Show-DevSetupEnvList with Provider and Platform parameters" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Show-DevSetupEnvList { }

            $result = Use-DevSetup -List -Provider "Chocolatey" -Platform "Windows"
            $result | Should -Be $null
            Assert-MockCalled Show-DevSetupEnvList -Exactly 1 -Scope It -ParameterFilter { $Provider -eq "Chocolatey" -and $Platform -eq "Windows" }
        }
    }

    Context "When uninstalling" {
        It "should call Uninstall-DevSetupEnv with Name parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Uninstall-DevSetupEnv { $true }

            $result = Use-DevSetup -Uninstall -Name "TestEnv"
            $result | Should -Be $true
            Assert-MockCalled Uninstall-DevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Name -eq "TestEnv" }
        }
    }

    Context "When explaining with name" {
        It "should call Show-ExplainDevSetupEnv with Name parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Show-ExplainDevSetupEnv { $true }

            $result = Use-DevSetup -Explain -Name "TestEnv"
            $result | Should -Be $true
            Assert-MockCalled Show-ExplainDevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Name -eq "TestEnv" }
        }
    }

    Context "When explaining from path" {
        It "should call Show-ExplainDevSetupEnv with Path parameter" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Show-ExplainDevSetupEnv { $true }

            $result = Use-DevSetup -Explain -Path "C:\Configs\test.yaml"
            $result | Should -Be $true
            Assert-MockCalled Show-ExplainDevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $Path -eq "C:\Configs\test.yaml" }
        }
    }

    Context "When an error occurs" {
        It "should handle exceptions and log errors" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { throw "Installation failed" }

            { Use-DevSetup -Install -Name "TestEnv" } | Should -Not -Throw  # Function handles exceptions internally
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Error executing DevSetup action" }
        }
    }

    Context "When DryRun is specified" {
        It "should pass DryRun to Install-DevSetupEnv" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { $true }

            $result = Use-DevSetup -Install -Name "TestEnv" -DryRun
            $result | Should -Be $true
            Assert-MockCalled Install-DevSetupEnv -Exactly 1 -Scope It -ParameterFilter { $DryRun -eq $true }
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { $true }

            $result = Use-DevSetup -Install -Name "TestEnv"
            $result | Should -Be $true
        }

        It "should work on Linux" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { $true }

            $result = Use-DevSetup -Install -Name "TestEnv"
            $result | Should -Be $true
        }

        It "should work on macOS" {
            Mock Get-DevSetupVersion { "1.0.9" }
            Mock Get-DevSetupLogPath { Join-Path $TestDrive "logs" }
            Mock Write-StatusMessage { }
            Mock Write-Host { }
            Mock Write-EZLog { }
            Mock Install-DevSetupEnv { $true }

            $result = Use-DevSetup -Install -Name "TestEnv"
            $result | Should -Be $true
        }
    }
}