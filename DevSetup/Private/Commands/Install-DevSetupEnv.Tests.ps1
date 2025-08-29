BeforeAll {
    . $PSScriptRoot\Install-DevSetupEnv.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Providers\PowerShell\Install-PowershellModules.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Providers\Chocolatey\Install-ChocolateyPackages.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Providers\Scoop\Install-ScoopComponents.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1
    . $PSScriptRoot\..\..\..\DevSetup\Private\Utils\Get-DevSetupEnvPath.ps1
    Mock Get-DevSetupEnvPath { "C:\DevSetupEnvs" }
    Mock Test-Path { $true }
    Mock Read-ConfigurationFile { }
    Mock Install-PowershellModules { }
    Mock Install-ChocolateyPackages { }
    Mock Install-ScoopComponents { }
    Mock Write-Host { }
    Mock Write-Error { }
    Mock Write-Warning { }
    Mock Invoke-Command { }
    Mock Invoke-Expression { }
}

Describe "Install-DevSetupEnv" {

    Context "When environment file does not exist" {
        It "Should write error and return" {
            Mock Test-Path { $false }
            $result = Install-DevSetupEnv -Name "missing-env"
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Environment file not found" }
        }
    }

    Context "When YAML parsing fails" {
        It "Should write error and return" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { $null }
            $result = Install-DevSetupEnv -Name "bad-yaml"
            $result | Should -Be $null
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to parse YAML" }
        }
    }

    Context "When all dependencies install and no commands are present" {
        It "Should install dependencies and write status" {
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ } } }
            $result = Install-DevSetupEnv -Name "basic-env"
            $result | Should -Be $null
            Assert-MockCalled Install-PowershellModules -Exactly 1 -Scope It
            Assert-MockCalled Install-ChocolateyPackages -Exactly 1 -Scope It
            Assert-MockCalled Install-ScoopComponents -Exactly 1 -Scope It
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "No commands found" }
        }
    }

    Context "When commands are present and executed" {
        It "Should execute all commands" {
            $commands = @(
                @{ command = "echo Hello"; packageName = "git" },
                @{ command = "echo World"; packageName = "nodejs" }
            )
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ commands = $commands } } }
            $result = Install-DevSetupEnv -Name "cmd-env"
            $result | Should -Be $null
            Assert-MockCalled Invoke-Expression -Exactly 2 -Scope It
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Executing command for: git" }
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Executing command for: nodejs" }
        }
    }

    Context "When a command entry is missing the command property" {
        It "Should skip and warn" {
            $commands = @(
                @{ packageName = "git" },
                @{ command = "echo World"; packageName = "nodejs" }
            )
            Mock Test-Path { $true }
            Mock Read-ConfigurationFile { @{ devsetup = @{ commands = $commands } } }
            $result = Install-DevSetupEnv -Name "missing-cmd"
            $result | Should -Be $null
            Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -match "missing command property" }
            Assert-MockCalled Invoke-Expression -Exactly 1 -Scope It
        }
    }
}