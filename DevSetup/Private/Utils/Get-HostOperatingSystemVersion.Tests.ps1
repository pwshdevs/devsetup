BeforeAll {
    Function Get-CimInstance { }
    . (Join-Path $PSScriptRoot "Get-HostOperatingSystemVersion.ps1")
    . (Join-Path $PSScriptRoot "Get-HostOperatingSystem.ps1")
    Mock Invoke-Command {
        Param($Script)
        if ($Script -match "OSVersion.Platform") { return "Win32NT" }  # Default to Windows
        if ($Script -match "OSVersion.VersionString") { return "Microsoft Windows NT 10.0.19041.0" }
    }
    Mock Get-HostOperatingSystem { "Windows" }  # Default to Windows
    Mock Get-CimInstance { [PSCustomObject]@{ Caption = "Microsoft Windows 10 Pro" } }
    Mock Test-Path { $true }
    Mock Get-Content { 'PRETTY_NAME="Ubuntu 20.04.3 LTS"' }
}

Describe "Get-HostOperatingSystemVersion" {

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
        It "Should return OSVersion.VersionString" {
            $script:callCount = 0
            Mock Invoke-Command {
                if ($script:callCount -eq 0) {
                    $script:callCount++
                    return "Win32NT"
                } else {
                    return "Microsoft Windows NT 10.0.19041.0"
                }
            }
            Mock Get-HostOperatingSystem { "Windows" }
            Mock Get-CimInstance { throw "Get-CimInstance failed" }
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
                    2 {
                        return "Unix 11.6"
                    }
                }
            }
            Mock Get-HostOperatingSystem { "macOS" }
            $result = Get-HostOperatingSystemVersion
            $result | Should -Be "Unix 11.6"
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

    Context "When platform is unknown" {
        It "Should return OSVersion.VersionString" {
            $script:callCount = 0
            Mock Invoke-Command {
                switch($script:callCount) {
                    0 {
                        $script:callCount++
                        return "UnknownPlatform"
                    }
                    1 {
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