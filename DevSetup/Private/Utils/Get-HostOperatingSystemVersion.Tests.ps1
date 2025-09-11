BeforeAll {
    Function Get-CimInstance { }
    . (Join-Path $PSScriptRoot "Get-HostOperatingSystemVersion.ps1")
    . (Join-Path $PSScriptRoot "Get-HostOperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "Write-StatusMessage.ps1")
    Mock Get-HostOperatingSystem { "Windows" }  # Default to Windows
    Mock Get-CimInstance { [PSCustomObject]@{ Caption = "Microsoft Windows 10 Pro" } }
    Mock Test-Path { $true }
    Mock Get-Content { 'PRETTY_NAME="Ubuntu 20.04.3 LTS"' }
    Mock Write-StatusMessage { }
}

Describe "Get-HostOperatingSystemVersion" {
    Context "When Invoke-Command throws exception" {
        It "Should return Unknown and log error" {
            Mock Invoke-Command { throw "Test exception" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unknown"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get OS version string" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Invoke-Command returns empty string" {
        It "Should run default of windows logic and return Windows 10 Pro" {
            Mock Invoke-Command { return "" }
            Mock Get-HostOperatingSystem { "Windows" }  # Default to Windows
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = "Microsoft Windows 10 Pro" } }            
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Windows 10 Pro"
        }
    }

    Context "When Get-HostOperatingSystem fails" {
        It "Should return Unknown and log error" {
            Mock Invoke-Command { return "Unknown" }
            Mock Get-HostOperatingSystem { throw "Test exception" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unknown"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get friendly OS platform" -and $Verbosity -eq "Error" }
        }
    }

    Context "When on Windows and Get-CimInstance succeeds" {
        It "Should return friendly Windows version" {
            Mock Invoke-Command {
                 return "Win32NT"
            }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = "Microsoft Windows 10 Pro" } }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Windows 10 Pro"
        }
    }

    Context "When on Windows and Get-CimInstance fails" {
        It "Should return Microsoft Windows NT 10.0.19041.0" {
            Mock Invoke-Command {
                return "Microsoft Windows NT 10.0.19041.0"
            }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-CimInstance { throw "Get-CimInstance failed" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Microsoft Windows NT 10.0.19041.0"
        }
    }

    Context "When on Windows and Get-CimInstance returns null" {
        It "Should return Microsoft Windows NT 10.0.19041.0" {
            Mock Invoke-Command {
                return "Microsoft Windows NT 10.0.19041.0"
            }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-CimInstance { $null }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Microsoft Windows NT 10.0.19041.0"
        }
    }    

    Context "When on macOS and sw_vers succeeds" {
        It "Should return friendly macOS version" {
            $script:callCount = 0
            Mock Invoke-Command {
                if($script:callCount -eq 0) {
                    $script:callCount++
                    return "Unix"
                } else {
                    return "11.6"
                }
            }
            Mock Get-HostOperatingSystem { "macOS" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "macOS 11.6"
        }
    }

    Context "When on macOS and sw_vers fails" {
        It "Should return OSVersion.VersionString" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unix"
                    }
                    1 {
                        $script:callCount++
                        throw "sw_vers failed"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "macOS" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unix"
        }
    }

    Context "When on macOS and sw_vers returns empty" {
        It "Should return Unix" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unix"
                    }
                    1 {
                        $script:callCount++
                        return ""
                    }
                }
            }
            Mock Get-HostOperatingSystem { "macOS" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unix"
        }
    }    

    Context "When on Linux and /etc/os-release exists" {
        It "Should return friendly Linux version" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unix"
                    }
                    1 {
                        $script:callCount++
                        return "5.4.0"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Test-Path { $true }
            Mock Get-Content { 'PRETTY_NAME="Ubuntu 20.04.3 LTS"' }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Ubuntu 20.04.3 LTS"
        }
    }

    Context "When on Linux and /etc/os-release does not exist" {
        It "Should return Unix 5.4.0" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unix 5.4.0"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Test-Path { $false }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unix 5.4.0"
        }
    }

    Context "When on Linux and test-path throws exception" {
        It "Should return Unix 5.4.0" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unix 5.4.0"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Test-Path { throw "Test-Path failed" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unix 5.4.0"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Failed to get Linux OS information" -and $Verbosity -eq "Error" }
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }    

    Context "When platform is unknown" {
        It "Should return Unknown OS" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unknown OS"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "Unknown" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unknown OS"
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Win32NT"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-CimInstance { [PSCustomObject]@{ Caption = "Microsoft Windows 10 Pro" } }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Windows 10 Pro"
        }

        It "Should work on Linux" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unix"
                    }
                    1 {
                        $script:callCount++
                        return "5.4.0"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "Linux" }
            Mock Test-Path { $true }
            Mock Get-Content { 'PRETTY_NAME="Ubuntu 20.04.3 LTS"' }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Ubuntu 20.04.3 LTS"
        }

        It "Should work on macOS" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "Unix"
                    }
                    1 {
                        $script:callCount++
                        return "11.6"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "macOS" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "macOS 11.6"
        }
    }
}