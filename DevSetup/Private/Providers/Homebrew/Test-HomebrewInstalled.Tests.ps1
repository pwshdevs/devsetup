BeforeAll {
    . (Join-Path $PSScriptRoot "Test-HomebrewInstalled.ps1")
}

Describe "Test-HomebrewInstalled" {
    Context "When brew is found in PATH" {
        It "should return true" {
            Mock Get-Command { [PSCustomObject]@{ Path = "/usr/local/bin/brew" } }
            Mock Test-Path { $false }  # Not needed since Get-Command succeeds

            $result = Test-HomebrewInstalled
            $result | Should -Be $true
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 0 -Scope It  # Test-Path not called if Get-Command succeeds
        }
    }

    Context "When brew is not in PATH but found in test paths" {
        It "should return true if found in first test path" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                switch ($Path) {
                    "/usr/local/bin/brew" { $true }
                    default { $false }
                }
            }

            $result = Test-HomebrewInstalled
            $result | Should -Be $true
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq "/usr/local/bin/brew" }
        }

        It "should return true if found in second test path" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                switch ($Path) {
                    "/usr/local/bin/brew" { $false }
                    "/opt/homebrew/bin/brew" { $true }
                    default { $false }
                }
            }

            $result = Test-HomebrewInstalled
            $result | Should -Be $true
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 2 -Scope It  # Checks first two paths
        }

        It "should return true if found in third test path" {
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

            $result = Test-HomebrewInstalled
            $result | Should -Be $true
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 3 -Scope It  # Checks all three paths
        }
    }

    Context "When brew is not found anywhere" {
        It "should return false" {
            Mock Get-Command { $null }
            Mock Test-Path { $false }

            $result = Test-HomebrewInstalled
            $result | Should -Be $false
            Assert-MockCalled Get-Command -Exactly 1 -Scope It
            Assert-MockCalled Test-Path -Exactly 3 -Scope It  # Checks all three paths
        }
    }

    Context "Cross-platform compatibility" {
        It "should return false on Windows (where Homebrew is unlikely)" {
            Mock Get-Command { $null }
            Mock Test-Path { $false }

            $result = Test-HomebrewInstalled
            $result | Should -Be $false
        }

        It "should work on Linux" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                $Path -eq "/home/linuxbrew/.linuxbrew/bin/brew"
            }

            $result = Test-HomebrewInstalled
            $result | Should -Be $true
        }

        It "should work on macOS" {
            Mock Get-Command { $null }
            Mock Test-Path { 
                Param($Path)
                $Path -eq "/opt/homebrew/bin/brew"
            }

            $result = Test-HomebrewInstalled
            $result | Should -Be $true
        }
    }
}