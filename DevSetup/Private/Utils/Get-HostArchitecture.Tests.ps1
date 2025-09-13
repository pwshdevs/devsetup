BeforeAll {
    . (Join-Path $PSScriptRoot "Get-HostArchitecture.ps1")
    Mock Invoke-Command { $true }  # Default to x64
}

Describe "Get-HostArchitecture" {

    Context "When system is 64-bit" {
        It "Should return x64" {
            Mock Invoke-Command { $true }
            $result = Get-HostArchitecture
            $result | Should -Be "x64"
        }
    }

    Context "When system is 32-bit" {
        It "Should return x86" {
            Mock Invoke-Command { $false }
            $result = Get-HostArchitecture
            $result | Should -Be "x86"
        }
    }

    Context "When Invoke-Command fails" {
        It "Should return x86 as default" {
            Mock Invoke-Command { throw "Invoke-Command failed" }
            $result = Get-HostArchitecture
            $result | Should -Be "x86"
        }
    }

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        Context "Cross-platform compatibility" {
            if ($IsWindows) {
                It "Should work on Windows" {
                    Mock Invoke-Command { $true }
                    $result = Get-HostArchitecture
                    $result | Should -Be "x64"
                }
            } elseif ($IsLinux) {
                It "Should work on Linux" {
                    Mock Invoke-Command { $true }
                    $result = Get-HostArchitecture
                    $result | Should -Be "x64"
                }
            } elseif ($IsMacOS) {
                It "Should work on macOS" {
                    Mock Invoke-Command { $true }
                    $result = Get-HostArchitecture
                    $result | Should -Be "x64"
                }
            }
        }
    }
}