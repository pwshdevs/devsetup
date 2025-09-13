BeforeAll {
    . $PSScriptRoot\Get-PowershellModuleScopeMap.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
}

Describe "Get-PowershellModuleScopeMap" {

    Context "When running on Windows" {
        BeforeEach {
            Mock Test-OperatingSystem { 
                param([switch]$Windows)
                return $true 
            }
        }

        It "Should use USERPROFILE as search path and correctly map CurrentUser scope" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "TestUser") }
                    "PSModulePath" { 
                        $userPath = Join-Path $TestDrive "Users" "TestUser" "Documents" "WindowsPowerShell" "Modules"
                        $systemPath = Join-Path $TestDrive "Program Files" "WindowsPowerShell" "Modules"
                        return "$userPath$([System.IO.Path]::PathSeparator)$systemPath"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "Users" "TestUser" "Documents" "WindowsPowerShell" "Modules"
            $expectedSystemPath = Join-Path $TestDrive "Program Files" "WindowsPowerShell" "Modules"
            
            $result | Should -HaveCount 2
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedSystemPath
            $result[1].Scope | Should -Be "AllUsers"
        }

        It "Should handle PowerShell 7 module paths on Windows" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "TestUser") }
                    "PSModulePath" { 
                        $userPath = Join-Path $TestDrive "Users" "TestUser" "Documents" "PowerShell" "Modules"
                        $ps7Path = Join-Path $TestDrive "Program Files" "PowerShell" "Modules"
                        $ps5Path = Join-Path $TestDrive "Program Files" "WindowsPowerShell" "Modules"
                        return "$userPath$([System.IO.Path]::PathSeparator)$ps7Path$([System.IO.Path]::PathSeparator)$ps5Path"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "Users" "TestUser" "Documents" "PowerShell" "Modules"
            $expectedPs7Path = Join-Path $TestDrive "Program Files" "PowerShell" "Modules"
            $expectedPs5Path = Join-Path $TestDrive "Program Files" "WindowsPowerShell" "Modules"
            
            $result | Should -HaveCount 3
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedPs7Path
            $result[1].Scope | Should -Be "AllUsers"
            $result[2].Path | Should -Be $expectedPs5Path
            $result[2].Scope | Should -Be "AllUsers"
        }

        It "Should handle mixed user profile paths correctly" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "TestUser") }
                    "PSModulePath" { 
                        $oneDrivePath = Join-Path $TestDrive "Users" "TestUser" "OneDrive" "Documents" "PowerShell" "Modules"
                        $regularPath = Join-Path $TestDrive "Users" "TestUser" "Documents" "WindowsPowerShell" "Modules"
                        $systemPath = Join-Path $TestDrive "Program Files" "WindowsPowerShell" "Modules"
                        return "$oneDrivePath$([System.IO.Path]::PathSeparator)$regularPath$([System.IO.Path]::PathSeparator)$systemPath"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedOneDrivePath = Join-Path $TestDrive "Users" "TestUser" "OneDrive" "Documents" "PowerShell" "Modules"
            $expectedRegularPath = Join-Path $TestDrive "Users" "TestUser" "Documents" "WindowsPowerShell" "Modules"
            $expectedSystemPath = Join-Path $TestDrive "Program Files" "WindowsPowerShell" "Modules"
            
            $result | Should -HaveCount 3
            $result[0].Path | Should -Be $expectedOneDrivePath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedRegularPath
            $result[1].Scope | Should -Be "CurrentUser"
            $result[2].Path | Should -Be $expectedSystemPath
            $result[2].Scope | Should -Be "AllUsers"
        }

        It "Should handle empty PSModulePath" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "TestUser") }
                    "PSModulePath" { return "" }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            # When PSModulePath is empty, filtering removes empty entries
            $result | Should -HaveCount 0
        }
    }

    Context "When running on Linux" {
        BeforeEach {
            Mock Test-OperatingSystem { 
                param([switch]$Windows)
                return $false 
            }
        }

        It "Should use HOME as search path and correctly map CurrentUser scope" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "HOME" { return (Join-Path $TestDrive "home" "testuser") }
                    "PSModulePath" { 
                        $userPath = Join-Path $TestDrive "home" "testuser" ".local" "share" "powershell" "Modules"
                        $systemPath1 = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
                        $systemPath2 = Join-Path $TestDrive "opt" "microsoft" "powershell" "7" "Modules"
                        return "$userPath$([System.IO.Path]::PathSeparator)$systemPath1$([System.IO.Path]::PathSeparator)$systemPath2"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "home" "testuser" ".local" "share" "powershell" "Modules"
            $expectedSystemPath1 = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
            $expectedSystemPath2 = Join-Path $TestDrive "opt" "microsoft" "powershell" "7" "Modules"
            
            $result | Should -HaveCount 3
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedSystemPath1
            $result[1].Scope | Should -Be "AllUsers"
            $result[2].Path | Should -Be $expectedSystemPath2
            $result[2].Scope | Should -Be "AllUsers"
        }

        It "Should handle custom user paths on Linux" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "HOME" { return (Join-Path $TestDrive "home" "testuser") }
                    "PSModulePath" { 
                        $customPath = Join-Path $TestDrive "home" "testuser" "custom" "powershell" "modules"
                        $userPath = Join-Path $TestDrive "home" "testuser" ".local" "share" "powershell" "Modules"
                        $systemPath = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
                        return "$customPath$([System.IO.Path]::PathSeparator)$userPath$([System.IO.Path]::PathSeparator)$systemPath"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedCustomPath = Join-Path $TestDrive "home" "testuser" "custom" "powershell" "modules"
            $expectedUserPath = Join-Path $TestDrive "home" "testuser" ".local" "share" "powershell" "Modules"
            $expectedSystemPath = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
            
            $result | Should -HaveCount 3
            $result[0].Path | Should -Be $expectedCustomPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedUserPath
            $result[1].Scope | Should -Be "CurrentUser"
            $result[2].Path | Should -Be $expectedSystemPath
            $result[2].Scope | Should -Be "AllUsers"
        }

        It "Should handle root user paths correctly" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "HOME" { return (Join-Path $TestDrive "root") }
                    "PSModulePath" { 
                        $rootPath = Join-Path $TestDrive "root" ".local" "share" "powershell" "Modules"
                        $systemPath = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
                        return "$rootPath$([System.IO.Path]::PathSeparator)$systemPath"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedRootPath = Join-Path $TestDrive "root" ".local" "share" "powershell" "Modules"
            $expectedSystemPath = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
            
            $result | Should -HaveCount 2
            $result[0].Path | Should -Be $expectedRootPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedSystemPath
            $result[1].Scope | Should -Be "AllUsers"
        }
    }

    Context "When running on macOS" {
        BeforeEach {
            Mock Test-OperatingSystem { 
                param([switch]$Windows)
                return $false 
            }
        }

        It "Should use HOME as search path and correctly map CurrentUser scope" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "HOME" { return (Join-Path $TestDrive "Users" "testuser") }
                    "PSModulePath" { 
                        $userPath = Join-Path $TestDrive "Users" "testuser" ".local" "share" "powershell" "Modules"
                        $systemPath1 = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
                        $systemPath2 = Join-Path $TestDrive "opt" "microsoft" "powershell" "7" "Modules"
                        return "$userPath$([System.IO.Path]::PathSeparator)$systemPath1$([System.IO.Path]::PathSeparator)$systemPath2"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "Users" "testuser" ".local" "share" "powershell" "Modules"
            $expectedSystemPath1 = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
            $expectedSystemPath2 = Join-Path $TestDrive "opt" "microsoft" "powershell" "7" "Modules"
            
            $result | Should -HaveCount 3
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedSystemPath1
            $result[1].Scope | Should -Be "AllUsers"
            $result[2].Path | Should -Be $expectedSystemPath2
            $result[2].Scope | Should -Be "AllUsers"
        }

        It "Should handle Homebrew installed PowerShell paths" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "HOME" { return (Join-Path $TestDrive "Users" "testuser") }
                    "PSModulePath" { 
                        $userPath = Join-Path $TestDrive "Users" "testuser" ".local" "share" "powershell" "Modules"
                        $homebrewPath = Join-Path $TestDrive "opt" "homebrew" "share" "powershell" "Modules"
                        $systemPath = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
                        return "$userPath$([System.IO.Path]::PathSeparator)$homebrewPath$([System.IO.Path]::PathSeparator)$systemPath"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "Users" "testuser" ".local" "share" "powershell" "Modules"
            $expectedHomebrewPath = Join-Path $TestDrive "opt" "homebrew" "share" "powershell" "Modules"
            $expectedSystemPath = Join-Path $TestDrive "usr" "local" "share" "powershell" "Modules"
            
            $result | Should -HaveCount 3
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedHomebrewPath
            $result[1].Scope | Should -Be "AllUsers"
            $result[2].Path | Should -Be $expectedSystemPath
            $result[2].Scope | Should -Be "AllUsers"
        }
    }

    Context "Edge cases and special characters" {
        BeforeEach {
            Mock Test-OperatingSystem { 
                param([switch]$Windows)
                return $true 
            }
        }

        It "Should handle paths with special characters" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "Test User (Admin)") }
                    "PSModulePath" { 
                        $userPath = Join-Path $TestDrive "Users" "Test User (Admin)" "Documents" "PowerShell" "Modules"
                        $systemPath = Join-Path $TestDrive "Program Files" "PowerShell" "Modules"
                        return "$userPath$([System.IO.Path]::PathSeparator)$systemPath"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "Users" "Test User (Admin)" "Documents" "PowerShell" "Modules"
            $expectedSystemPath = Join-Path $TestDrive "Program Files" "PowerShell" "Modules"
            
            $result | Should -HaveCount 2
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedSystemPath
            $result[1].Scope | Should -Be "AllUsers"
        }

        It "Should handle paths with regex special characters" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "Test.User[1]") }
                    "PSModulePath" { 
                        $userPath = Join-Path $TestDrive "Users" "Test.User[1]" "Documents" "PowerShell" "Modules"
                        $systemPath = Join-Path $TestDrive "Program Files" "PowerShell" "Modules"
                        return "$userPath$([System.IO.Path]::PathSeparator)$systemPath"
                    }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "Users" "Test.User[1]" "Documents" "PowerShell" "Modules"
            $expectedSystemPath = Join-Path $TestDrive "Program Files" "PowerShell" "Modules"
            
            $result | Should -HaveCount 2
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
            $result[1].Path | Should -Be $expectedSystemPath
            $result[1].Scope | Should -Be "AllUsers"
        }

        It "Should handle single path entry" {
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "TestUser") }
                    "PSModulePath" { return (Join-Path $TestDrive "Users" "TestUser" "Documents" "PowerShell" "Modules") }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedUserPath = Join-Path $TestDrive "Users" "TestUser" "Documents" "PowerShell" "Modules"
            
            $result | Should -HaveCount 1
            $result[0].Path | Should -Be $expectedUserPath
            $result[0].Scope | Should -Be "CurrentUser"
        }
    }

    Context "Error scenarios" {
        It "Should handle null PSModulePath gracefully" {
            Mock Test-OperatingSystem { 
                param([switch]$Windows)
                return $true 
            }
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return (Join-Path $TestDrive "Users" "TestUser") }
                    "PSModulePath" { return $null }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            # When PSModulePath is null, filtering removes null/empty entries
            $result | Should -HaveCount 0
        }

        It "Should handle null USERPROFILE/HOME gracefully" {
            Mock Test-OperatingSystem { 
                param([switch]$Windows)
                return $true 
            }
            Mock Get-EnvironmentVariable { 
                param($Name)
                switch ($Name) {
                    "USERPROFILE" { return $null }
                    "PSModulePath" { return (Join-Path $TestDrive "Program Files" "PowerShell" "Modules") }
                }
            }
            
            $result = Get-PowershellModuleScopeMap
            
            $expectedSystemPath = Join-Path $TestDrive "Program Files" "PowerShell" "Modules"
            
            $result | Should -HaveCount 1
            $result[0].Path | Should -Be $expectedSystemPath
            $result[0].Scope | Should -Be "AllUsers"
        }
    }
}