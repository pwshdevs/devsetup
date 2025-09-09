BeforeAll {
    . (Join-Path $PSScriptRoot "Get-HostOperatingSystem.ps1")
}

Describe "Get-HostOperatingSystem" {

    Context "When on Windows" {
        It "Should return Windows" {
            Mock Invoke-Command {
                return "Win32NT"
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "Windows"
        }
    }

    Context "When on Linux" {
        It "Should return Linux" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "Unix"
                }
                return "Linux"
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "Linux"
        }
    }

    Context "When on macOS" {
        It "Should return macOS" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "Unix"
                }
                return "Darwin"
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "macOS"
        }
    }

    Context "When platform is unknown" {
        It "Should return the platform string" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "UnknownPlatform"
                }
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "UnknownPlatform"
        }
    }

    Context "When uname fails" {
        It "Should return Linux as default for Unix" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "Unix"
                }
                throw "uname failed"
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "Linux"
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "Win32NT"
                }
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "Windows"
        }

        It "Should work on Linux" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "Unix"
                }
                return "Linux"
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "Linux"
        }

        It "Should work on macOS" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "Unix"
                }
                return "Darwin"
            }
            $result = Get-HostOperatingSystem
            $result | Should -Be "macOS"
        }
    }
}