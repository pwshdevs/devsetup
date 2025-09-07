BeforeAll {
    . $PSScriptRoot\Find-Homebrew.ps1
}

Describe "Find-Homebrew" {
    Context "When brew is found in PATH" {
        It "should return the path from Get-Command" {
            Mock Get-Command { [PSCustomObject]@{ Path = "/usr/local/bin/brew" } }
            Mock Test-Path { $false }  # Not needed since Get-Command succeeds

            $result = Find-Homebrew
            $result | Should -Be "/usr/local/bin/brew"
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 0 -Scope It  # Test-Path not called if Get-Command succeeds
        }
    }

    Context "When brew is not in PATH but found in test paths" {
        It "should return the first matching test path" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                switch ($Path) {
                    "/usr/local/bin/brew" { $true }
                    default { $false }
                }
            }

            $result = Find-Homebrew
            $result | Should -Be "/usr/local/bin/brew"
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq "/usr/local/bin/brew" }
        }

        It "should return the second matching test path if first fails" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                switch ($Path) {
                    "/usr/local/bin/brew" { $false }
                    "/opt/homebrew/bin/brew" { $true }
                    default { $false }
                }
            }

            $result = Find-Homebrew
            $result | Should -Be "/opt/homebrew/bin/brew"
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 2 -Scope It  # Checks first two paths
        }

        It "should return the third matching test path if first two fail" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                switch ($Path) {
                    "/usr/local/bin/brew" { $false }
                    "/opt/homebrew/bin/brew" { $false }
                    "/home/linuxbrew/.linuxbrew/bin/brew" { $true }
                    default { $false }
                }
            }

            $result = Find-Homebrew
            $result | Should -Be "/home/linuxbrew/.linuxbrew/bin/brew"
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 3 -Scope It  # Checks all three paths
        }
    }

    Context "When brew is not found anywhere" {
        It "should return null" {
            Mock Get-Command { $null }
            Mock Test-Path { $false }

            $result = Find-Homebrew
            $result | Should -Be $null
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 3 -Scope It  # Checks all three paths
        }
    }

    Context "Cross-platform compatibility" {
        It "should handle Windows (where brew is unlikely to be found)" {
            Mock Get-Command { $null }
            Mock Test-Path { $false }

            $result = Find-Homebrew
            $result | Should -Be $null
        }

        It "should handle Linux paths" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                $Path -eq "/home/linuxbrew/.linuxbrew/bin/brew"
            }

            $result = Find-Homebrew
            $result | Should -Be "/home/linuxbrew/.linuxbrew/bin/brew"
        }

        It "should handle macOS paths" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                $Path -eq "/opt/homebrew/bin/brew"
            }

            $result = Find-Homebrew
            $result | Should -Be "/opt/homebrew/bin/brew"
        }
    }
}