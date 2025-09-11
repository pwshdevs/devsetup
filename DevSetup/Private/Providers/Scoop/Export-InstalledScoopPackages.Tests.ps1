BeforeAll {
    . $PSScriptRoot\Export-InstalledScoopPackages.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Read-DevSetupEnvFile.ps1    
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Update-DevSetupEnvFile.ps1    
    Mock Test-ScoopInstalled { $true }
    Mock Find-Scoop { "scoop" }
    Mock Invoke-Expression { '{"buckets":[{"Name":"extras","Source":"https://github.com/ScoopInstaller/Extras"}],"apps":[{"Name":"git","Version":"2.40.0","Source":"extras","Info":"Global install"}]}' }
    Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ scoop = @{ packages = @(); buckets = @() } } } } }
    Mock Update-DevSetupEnvFile { }
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Write-Debug { }
    Mock Write-Verbose { }
}

Describe "Export-InstalledScoopPackages" {

    Context "When Scoop is not installed" {
        It "Should warn and return false" {
            Mock Test-ScoopInstalled { $false }
            $result = Export-InstalledScoopPackages -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Scoop is not installed" }
        }
    }

    Context "When Scoop command is not found" {
        It "Should warn and return false" {
            Mock Find-Scoop { $null }
            $result = Export-InstalledScoopPackages -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Failed to find Scoop command" }
        }
    }

    Context "When no Scoop packages are found" {
        It "Should warn and return true" {
            Mock Invoke-Expression { $null }
            $result = Export-InstalledScoopPackages -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "No Scoop packages found" }
        }
    }

    Context "When Scoop export JSON is invalid" {
        It "Should warn and show raw output" {
            Mock Invoke-Expression { "not-json" }
            Mock ConvertFrom-Json { throw "JSON error" }
            $result = Export-InstalledScoopPackages -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Failed to parse scoop export JSON" }
        }
    }

    Context "When buckets and packages are found" {
        It "Should add buckets and packages to YAML data" {
            $result = Export-InstalledScoopPackages -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Adding bucket: extras" }
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Adding package: git" }
        }
    }

    Context "When OutFile is specified" {
        It "Should write YAML output to the specified file" {
            $result = Export-InstalledScoopPackages -Config "test.yaml" -OutFile "out.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $EnvFilePath -eq "out.yaml" }
        }
    }

    Context "When Update-DevSetupEnvFile fails" {
        It "Should error and return false" {
            Mock Update-DevSetupEnvFile { throw "YAML error" }
            $result = Export-InstalledScoopPackages -Config "test.yaml" -DryRun
            $result | Should -BeFalse
            Assert-MockCalled Update-DevSetupEnvFile -Exactly 1 -Scope It -ParameterFilter { $EnvFilePath -eq "test.yaml" }
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to save configuration to" }
        }
    }
}