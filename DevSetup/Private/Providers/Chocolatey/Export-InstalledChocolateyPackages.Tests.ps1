BeforeAll {
    function ConvertTo-Yaml { }
    . $PSScriptRoot\Export-InstalledChocolateyPackages.ps1
    . $PSScriptRoot\Get-ChocolateyPackageDependencies.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Read-DevSetupEnvFile.ps1
    Mock Test-RunningAsAdmin { $true }
    Mock Get-ChocolateyPackageDependencies { @('chocolatey-core.extension') }
    Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
    Mock ConvertTo-Yaml { param($obj) "yaml-output" }
    Mock ConvertTo-Json { param($obj) "json-output" }
    Mock Out-File { $true }
    Mock Write-Host { }
    Mock Write-Warning { }
    Mock Write-Error { }
    Mock Write-Debug { }
    Mock Write-Verbose { }
}

Describe "Export-InstalledChocolateyPackages" {

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-RunningAsAdmin { $false }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Error -Scope It
        }
    }

    Context "When no Chocolatey packages are found" {
        It "Should warn and return true" {
            Mock Test-RunningAsAdmin { $true }
            Mock Invoke-Expression { @() }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "No Chocolatey packages found" }
        }
    }

    Context "When Chocolatey packages are found and DryRun is used" {
        It "Should display the YAML output and not write to file" {
            Mock Invoke-Expression { @("git|2.40.0", "nodejs|18.16.0") }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Times 0 -Scope It
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Dry Run" }
        }
    }

    Context "When Chocolatey packages are found and OutFile is specified" {
        It "Should write the YAML output to the specified file" {
            Mock Invoke-Expression { @("git|2.40.0", "nodejs|18.16.0") }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml" -OutFile "out.yaml"
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Yaml -Scope It
            Assert-MockCalled Out-File -Scope It -ParameterFilter { $FilePath -eq "out.yaml" }
        }
    }

    Context "When YAML conversion fails" {
        It "Should fallback to JSON output" {
            Mock Invoke-Expression { @("git|2.40.0") }
            Mock ConvertTo-Yaml { throw "YAML error" }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml" -DryRun
            $result | Should -BeTrue
            Assert-MockCalled ConvertTo-Json -Scope It
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Could not convert to YAML format" }
        }
    }

    Context "When Out-File fails" {
        It "Should write error and return false" {
            Mock Invoke-Expression { @("git|2.40.0") }
            Mock Out-File { throw "File error" }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml"
            $result | Should -BeFalse
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to save configuration" }
        }
    }

    Context "When package version changes" {
        It "Should update the package version in the config" {
            Mock Invoke-Expression { @("git|2.41.0") }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @(@{ name = "git"; version = "2.40.0" }) } } } } }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Updating package: git" }
        }
    }

    Context "When package is new" {
        It "Should add the package to the config" {
            Mock Invoke-Expression { @("newpkg|1.0.0") }
            Mock Read-DevSetupEnvFile { @{ devsetup = @{ dependencies = @{ chocolatey = @{ packages = @() } } } } }
            $result = Export-InstalledChocolateyPackages -Config "test.yaml"
            $result | Should -BeTrue
            Assert-MockCalled Write-Host -Scope It -ParameterFilter { $Object -match "Adding package: newpkg" }
        }
    }
}