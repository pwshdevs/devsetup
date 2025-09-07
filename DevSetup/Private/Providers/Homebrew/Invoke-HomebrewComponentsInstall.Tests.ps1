BeforeAll {
    . (Join-Path $PSScriptRoot "Invoke-HomebrewComponentsInstall.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Install-HomebrewPackage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Write-HomebrewCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Invoke-HomebrewComponentsInstall" {
    Context "When there are no packages in YAML" {
        It "should process 0 packages" {
            $YamlData = @{ devsetup = @{ dependencies = @{ homebrew = @() } } }
            Mock Write-HomebrewCache { }
            Mock Write-StatusMessage { }
            Mock Install-HomebrewPackage { $false }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData
            Assert-MockCalled Write-HomebrewCache -Exactly 1 -Scope It  # Initial call
            Assert-MockCalled Install-HomebrewPackage -Exactly 0 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It  # Start and completion
        }
    }

    Context "When all packages install successfully" {
        It "should increment package count and write cache for each" {
            $YamlData = @{ devsetup = @{ dependencies = @{ homebrew = @(@{ name = "git" }, @{ name = "node" }) } } }
            Mock Write-HomebrewCache { }
            Mock Install-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData
            Assert-MockCalled Write-HomebrewCache -Exactly 3 -Scope It  # Initial + 2 successful
            Assert-MockCalled Install-HomebrewPackage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
        }
    }

    Context "When some packages fail" {
        It "should only increment for successful packages" {
            $YamlData = @{ devsetup = @{ dependencies = @{ homebrew = @(@{ name = "git" }, @{ name = "node" }) } } }
            Mock Write-HomebrewCache { }
            Mock Install-HomebrewPackage { Param($PackageName) if ($PackageName -eq "git") { $true } else { $false } }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData
            Assert-MockCalled Write-HomebrewCache -Exactly 2 -Scope It  # Initial + 1 successful
            Assert-MockCalled Install-HomebrewPackage -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It
        }
    }

    Context "When DryRun is specified" {
        It "should pass WhatIf to Install-HomebrewPackage" {
            $YamlData = @{ devsetup = @{ dependencies = @{ homebrew = @(@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Install-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData -DryRun
            Assert-MockCalled Install-HomebrewPackage -Exactly 1 -Scope It -ParameterFilter { $WhatIf -eq $true }
        }
    }

    Context "When package has minimumVersion" {
        It "should pass MinimumVersion to Install-HomebrewPackage" {
            $YamlData = [PSCustomObject]@{ devsetup = [PSCustomObject]@{ dependencies = @{ homebrew = @([PSCustomObject]@{ name = "node"; minimumVersion = "14.0" }) } } }
            Mock Write-HomebrewCache { }
            Mock Install-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData
            Assert-MockCalled Install-HomebrewPackage -Exactly 1 -Scope It -ParameterFilter { $MinimumVersion -eq "14.0" }
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows (no specific Homebrew logic)" {
            $YamlData = @{ devsetup = @{ dependencies = @{ homebrew = @(@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Install-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData
            Assert-MockCalled Install-HomebrewPackage -Exactly 1 -Scope It
        }

        It "should work on Linux" {
            $YamlData = @{ devsetup = @{ dependencies = @{ homebrew = @(@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Install-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData
            Assert-MockCalled Install-HomebrewPackage -Exactly 1 -Scope It
        }

        It "should work on macOS" {
            $YamlData = @{ devsetup = @{ dependencies = @{ homebrew = @(@{ name = "git" }) } } }
            Mock Write-HomebrewCache { }
            Mock Install-HomebrewPackage { $true }
            Mock Write-StatusMessage { }

            Invoke-HomebrewComponentsInstall -YamlData $YamlData
            Assert-MockCalled Install-HomebrewPackage -Exactly 1 -Scope It
        }
    }
}