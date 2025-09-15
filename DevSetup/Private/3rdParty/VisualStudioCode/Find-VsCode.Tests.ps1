BeforeAll {
    . (Join-Path $PSScriptRoot "Find-VsCode.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Test-OperatingSystem { return $true }  # Default to Windows
    Mock Get-Command { throw "Command not found" }  # Default to not found
    Mock Get-EnvironmentVariable { 
        if ($Name -eq "LocalAppData") { 
            return "$TestDrive\LocalAppData" 
        } elseif ($Name -eq "ProgramFiles") { 
            return "$TestDrive\ProgramFiles" 
        } 
    }
    Mock Test-Path { $false }  # Default to not exist
    Mock Write-StatusMessage { }
}

Describe "Find-VsCode" {

    Context "When not on Windows" {
        It "Should return null and write warning" {
            Mock Test-OperatingSystem { return $false }
            $result = Find-VsCode
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Find-VsCode is only supported on Windows at this time" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When on Windows and Get-Command succeeds" {
        It "Should return the path from Get-Command" {
            Mock Get-Command { [PSCustomObject]@{ Path = "$TestDrive\Code\bin\code.cmd" } }
            $result = Find-VsCode
            $result | Should -Be "$TestDrive\Code\bin\code.cmd"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Found Visual Studio Code at" -and $Verbosity -eq "Debug" }
            Assert-MockCalled Get-EnvironmentVariable -Exactly 0 -Scope It
            Assert-MockCalled Test-Path -Exactly 0 -Scope It
        }
    }

    Context "When on Windows and Get-Command fails with exception" {
        It "Should write debug message and continue to check paths" {
            Mock Get-Command { throw "Command not found" }
            Mock Test-Path { $false }
            $result = Find-VsCode
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Get-Command code failed:" -and $Verbosity -eq "Debug" }
        }
    }

    Context "When on Windows and Get-Command fails, but user path exists" {
        It "Should return the user path" {
            Mock Get-Command { throw "Command not found" }
            Mock Test-Path { 
                if ($Path -eq "$TestDrive\LocalAppData\Programs\Microsoft VS Code\bin\code.cmd") { 
                    return $true 
                } else { 
                    return $false 
                } 
            }
            $result = Find-VsCode
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Found Visual Studio Code at" -and $Verbosity -eq "Debug" }
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq "$TestDrive\LocalAppData\Programs\Microsoft VS Code\bin\code.cmd" }
            $result | Should -Be "$TestDrive\LocalAppData\Programs\Microsoft VS Code\bin\code.cmd"
        }
    }

    Context "When on Windows and Get-Command fails, user path doesn't exist, but system path exists" {
        It "Should return the system path" {
            Mock Get-Command { throw "Command not found" }
            Mock Test-Path { 
                if ($Path -eq "$TestDrive\ProgramFiles\Microsoft VS Code\bin\code.cmd") { 
                    return $true 
                } else { 
                    return $false 
                } 
            }
            $result = Find-VsCode
            $result | Should -Be "$TestDrive\ProgramFiles\Microsoft VS Code\bin\code.cmd"
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Found Visual Studio Code at" -and $Verbosity -eq "Debug" }
            Assert-MockCalled Test-Path -Exactly 2 -Scope It  # Once for user, once for system
        }
    }

    Context "When on Windows and none of the paths are found" {
        It "Should return null" {
            Mock Get-Command { throw "Command not found" }
            Mock Test-Path { $false }
            $result = Find-VsCode
            $result | Should -Be $null
            Assert-MockCalled Test-Path -Exactly 2 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 0 -Scope It -ParameterFilter { $Verbosity -eq "Debug" -and $Message -match "Found Visual Studio Code" }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Get-Command { [PSCustomObject]@{ Path = "$TestDrive\Code\bin\code.cmd" } }
            $result = Find-VsCode
            $result | Should -Be "$TestDrive\Code\bin\code.cmd"
        }

        It "Should work on Linux" {
            Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $false } }
            $result = Find-VsCode
            $result | Should -Be $null
        }

        It "Should work on macOS" {
            Mock Test-OperatingSystem { Param($Windows, $Linux, $MacOS) { return $false } }
            $result = Find-VsCode
            $result | Should -Be $null
        }
    }
}