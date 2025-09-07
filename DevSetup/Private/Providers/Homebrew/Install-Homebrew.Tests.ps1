BeforeAll {
    . (Join-Path $PSScriptRoot "Install-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-HasSudoAccess.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Providers\Homebrew\Find-Homebrew.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Invoke-ExternalCommand.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1")
}

Describe "Install-Homebrew" {
    Context "When sudo access is not available" {
        It "should return false" {
            Mock Test-HasSudoAccess { $false }
            Mock Write-StatusMessage { }

            $result = Install-Homebrew
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 3 -Scope It  # One for checking sudo, one for failure
        }
    }

    Context "When Homebrew is already installed" {
        It "should return true without installing" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { "/usr/local/bin/brew" }
            Mock Write-StatusMessage { }
            Mock Invoke-ExternalCommand { return $true }

            $result = Install-Homebrew
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 1 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 0 -Scope It  # No installation needed
        }
    }

    Context "When installation succeeds and shell is bash" {
        It "should install Homebrew, add to .bashrc, and return true" {
            $script:callCount = 0
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew {
                $script:callCount++
                if ($script:callCount -eq 1) { return $null }  # First call returns null
                else { return "/usr/local/bin/brew" }  # Second call returns path
            }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            Mock Get-EnvironmentVariable { 
                Param($Name)
                switch($Name) {
                    "SHELL" { return "/bin/bash" }
                    "HOME" { return "/home/testuser" }
                }
            }
            Mock Add-Content { }

            $result = Install-Homebrew
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It  # Once before install, once after
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
            Assert-MockCalled Add-Content -Exactly 2 -Scope It  # Blank line and shellenv line
        }
    }

    Context "When installation succeeds and shell is zsh" {
        It "should install Homebrew, add to .zshrc, and return true" {
            $script:callCount = 0
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew {
                $script:callCount++
                if ($script:callCount -eq 1) { return $null }
                else { return "/usr/local/bin/brew" }
            }
            Mock Invoke-ExternalCommand { "Installation successful" }
            Mock Write-StatusMessage { }
            Mock Get-EnvironmentVariable { 
                Param($Name)
                switch($Name) {
                    "SHELL" { return "/bin/zsh" }
                    "HOME" { return "/home/testuser" }
                }
            }
            Mock Add-Content { }

            $result = Install-Homebrew
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
            Assert-MockCalled Add-Content -Exactly 2 -Scope It
        }
    }

    Context "When installation succeeds and shell is unknown" {
        It "should install Homebrew, warn about shell, and return true" {
            $script:callCount = 0
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew {
                $script:callCount++
                if ($script:callCount -eq 1) { return $null }
                else { return "/usr/local/bin/brew" }
            }
            Mock Invoke-ExternalCommand { "Installation successful" }
            Mock Write-StatusMessage { }
            Mock Get-EnvironmentVariable { 
                Param($Name)
                switch($Name) {
                    "SHELL" { return "/bin/fish" }
                    "HOME" { return "/home/testuser" }
                }
            }
            Mock Add-Content { }

            $result = Install-Homebrew
            $result | Should -Be $true
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
            Assert-MockCalled Add-Content -Exactly 0 -Scope It  # No shell config added
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Unknown shell" }
        }
    }

    Context "When installation fails" {
        It "should return false" {
            $script:callCount = 0
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew {
                $script:callCount++
                return $null  # Always return null
            }
            Mock Invoke-ExternalCommand { "Installation failed" }
            Mock Write-StatusMessage { }

            $result = Install-Homebrew
            $result | Should -Be $false
            Assert-MockCalled Test-HasSudoAccess -Exactly 1 -Scope It
            Assert-MockCalled Find-Homebrew -Exactly 2 -Scope It
            Assert-MockCalled Invoke-ExternalCommand -Exactly 1 -Scope It
        }
    }

    Context "Cross-platform compatibility" {
        It "should handle Windows (where Homebrew installation is not supported)" {
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew { $null }
            Mock Invoke-ExternalCommand { throw "Not supported on Windows" }
            Mock Write-StatusMessage { }

            $result = Install-Homebrew
            $result | Should -Be $false
        }

        It "should work on Linux" {
            $script:callCount = 0
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew {
                $script:callCount++
                if ($script:callCount -eq 1) { return $null }
                else { return "/home/linuxbrew/.linuxbrew/bin/brew" }
            }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            Mock Get-EnvironmentVariable {
                Param($Name)
                switch($Name) {
                    "SHELL" { return "/bin/bash" }
                    "HOME" { return "/home/testuser" }
                }
            }
            Mock Add-Content { }

            $result = Install-Homebrew
            $result | Should -Be $true
        }

        It "should work on macOS" {
            $script:callCount = 0
            Mock Test-HasSudoAccess { $true }
            Mock Find-Homebrew {
                $script:callCount++
                if ($script:callCount -eq 1) { return $null }
                else { return "/opt/homebrew/bin/brew" }
            }
            Mock Invoke-ExternalCommand { $true }
            Mock Write-StatusMessage { }
            Mock Get-EnvironmentVariable {
                Param($Name)
                switch($Name) {
                    "SHELL" { return "/bin/zsh" }
                    "HOME" { return "/Users/TestUser" }
                }
            }
            Mock Add-Content { }

            $result = Install-Homebrew
            $result | Should -Be $true
        }
    }
}