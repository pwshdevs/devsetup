BeforeAll {
    # Source the function under test
    . $PSScriptRoot\Update-DevSetup.ps1
    . $PSScriptRoot\..\Updater\Start-DevSetupSelfUpdate.ps1
    Mock Start-DevSetupSelfUpdate { }
}

Describe "Update-DevSetup" {

    Context "When Main parameter is specified" {
        It "Should call Start-DevSetupSelfUpdate with Main parameter" {
            Update-DevSetup -Main
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It -ParameterFilter { $Main -eq $true }
        }
    }

    Context "When Develop parameter is specified" {
        It "Should call Start-DevSetupSelfUpdate with Develop parameter" {
            Update-DevSetup -Develop
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It -ParameterFilter { $Develop -eq $true }
        }
    }

    Context "When Version parameter is specified" {
        It "Should call Start-DevSetupSelfUpdate with Version parameter" {
            Update-DevSetup -Version "1.0.0"
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It -ParameterFilter { $Version -eq "1.0.0" }
        }
    }

    Context "When no parameters are specified (default)" {
        It "Should call Start-DevSetupSelfUpdate without parameters (letting it use its own defaults)" {
            Update-DevSetup
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It -ParameterFilter { $PSBoundParameters.Count -eq 0 }
        }
    }

    Context "Parameter set validation" {
        It "Should allow Main parameter alone" {
            { Update-DevSetup -Main } | Should -Not -Throw
        }

        It "Should allow Develop parameter alone" {
            { Update-DevSetup -Develop } | Should -Not -Throw
        }

        It "Should allow Version parameter alone" {
            { Update-DevSetup -Version "2.0.0" } | Should -Not -Throw
        }

        It "Should not allow Main and Develop together" {
            { Update-DevSetup -Main -Develop } | Should -Throw
        }

        It "Should not allow Main and Version together" {
            { Update-DevSetup -Main -Version "1.0.0" } | Should -Throw
        }

        It "Should not allow Develop and Version together" {
            { Update-DevSetup -Develop -Version "1.0.0" } | Should -Throw
        }
    }

    Context "PSBoundParameters forwarding" {
        It "Should forward all parameters using splatting" {
            Mock Start-DevSetupSelfUpdate { } -ParameterFilter { $PSBoundParameters.Count -gt 0 }
            Update-DevSetup -Version "test"
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Update-DevSetup -Main
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It
        }

        It "Should work on Linux" {
            Update-DevSetup -Develop
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It
        }

        It "Should work on macOS" {
            Update-DevSetup -Version "1.0.0"
            Assert-MockCalled Start-DevSetupSelfUpdate -Exactly 1 -Scope It
        }
    }
}