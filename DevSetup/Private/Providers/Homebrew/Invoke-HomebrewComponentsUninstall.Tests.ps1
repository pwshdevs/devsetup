BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-HomebrewComponentsUninstall.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Uninstall-HomebrewPackage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Write-HomebrewCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Invoke-HomebrewComponentsUninstall" {
    Context "When there are no packages in YAML" {
        It "should process 0 packages" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = [PSCustomObject]@{ homebrew = @() } } }
            Mock Write-HomebrewCache { }
            Mock Write-StatusMessage { }
            Mock Uninstall-HomebrewPackage { $false }

            Invoke-HomebrewComponentsUninstall -YamlData $YamlData
            Assert-MockCalled Write-HomebrewCache -Exactly 1 -Scope It  # Initial call
            Assert-MockCalled Uninstall-HomebrewPackage -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It  # Start and completion
        }
    }

    Context "When all packages uninstall successfully" {
        It "should increment package count and write cache for each" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = [PSCustomObject]@{ homebrew = @([PSCustomObject]@{ name = "git" }, [PSCustomObject]@{ name = "node" }) } } }
            Mock Write-HomebrewCache { }
            Mock Uninstall-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsUninstall -YamlData $YamlData
            Assert-MockCalled Write-HomebrewCache -Exactly 3 -Scope It  # Initial + 2 successful
            Assert-MockCalled Uninstall-HomebrewPackage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
        }
    }

    Context "When some packages fail" {
        It "should only increment for successful packages" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = [PSCustomObject]@{ homebrew = @([PSCustomObject]@{ name = "git" }, [PSCustomObject]@{ name = "node" }) } } }
            Mock Write-HomebrewCache { }
            Mock Uninstall-HomebrewPackage { Param($PackageName) if ($PackageName -eq "git") { $true } else { $false } }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsUninstall -YamlData $YamlData
            Assert-MockCalled Write-HomebrewCache -Exactly 2 -Scope It  # Initial + 1 successful
            Assert-MockCalled Uninstall-HomebrewPackage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
        }
    }

    Context "When DryRun is specified" {
        It "should pass WhatIf to Uninstall-HomebrewPackage" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = [PSCustomObject]@{ homebrew = @([PSCustomObject]@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Uninstall-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsUninstall -YamlData $YamlData -DryRun
            Assert-MockCalled Uninstall-HomebrewPackage -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = [PSCustomObject]@{ homebrew = @([PSCustomObject]@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Uninstall-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsUninstall -YamlData $YamlData
            Assert-MockCalled Uninstall-HomebrewPackage -Exactly 1 -Scope It
        }

        It "should work on Linux" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = [PSCustomObject]@{ homebrew = @([PSCustomObject]@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Uninstall-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsUninstall -YamlData $YamlData
            Assert-MockCalled Uninstall-HomebrewPackage -Exactly 1 -Scope It
        }

        It "should work on macOS" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = [PSCustomObject]@{ homebrew = @([PSCustomObject]@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Uninstall-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsUninstall -YamlData $YamlData
            Assert-MockCalled Uninstall-HomebrewPackage -Exactly 1 -Scope It
        }
    }
}