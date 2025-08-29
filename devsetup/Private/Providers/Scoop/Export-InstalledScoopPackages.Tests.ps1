BeforeAll {
    function ConvertTo-Yaml { }
    . $PSScriptRoot\Export-InstalledScoopPackages.ps1
    . $PSScriptRoot\Test-ScoopInstalled.ps1
    . $PSScriptRoot\Find-Scoop.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Read-ConfigurationFile.ps1    
    Mock Test-ScoopInstalled { $true }
    Mock Find-Scoop { "scoop" }
    Mock Invoke-Expression { '{"buckets":[{"Name":"extras","Source":"https://github.com/ScoopInstaller/Extras"}],"apps":[{"Name":"git","Version":"2.40.0","Source":"extras","Info":"Global install"}]}' }
    Mock Read-ConfigurationFile { @{ devsetup = @{ dependencies = @{ scoop = @{ packages = @(); buckets = @() } } } } }
    Mock ConvertTo-Yaml { param($obj) "yaml-output" }
    Mock ConvertTo-Json { param($obj) "json-output" }
    Mock Out-File { $true }
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

    Context "When DryRun is used" {
        It "Should display YAML output and not write to file" {
            $result = Export-InstalledScoopPackages -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Times 0 -Scope It
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Dry Run" }
        }
    }

    Context "When OutFile is specified" {
        It "Should write YAML output to the specified file" {
            $result = Export-InstalledScoopPackages -Config "test.yaml" -OutFile "out.yaml"
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Scope It -ParameterFilter { $FilePath -eq "out.yaml" }
        }
    }

    Context "When YAML conversion fails" {
        It "Should fallback to JSON output" {
            Mock ConvertTo-Yaml { throw "YAML error" }
            $result = Export-InstalledScoopPackages -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Json -Scope It
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Could not convert to YAML format" }
        }
    }

    Context "When Out-File fails" {
        It "Should write error and return false" {
            Mock Out-File { throw "File error" }
            $result = Export-InstalledScoopPackages -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to save configuration" }
        }
    }
}