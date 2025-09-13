BeforeAll {
    . (Join-Path $PSScriptRoot "Get-DevSetupPath.ps1")
    . (Join-Path $PSScriptRoot "Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "Get-EnvironmentVariable.ps1")
    . (Join-Path $PSScriptRoot "Write-StatusMessage.ps1")
    Mock Test-OperatingSystem {
        Param($Windows, $Linux, $MacOS)
        if ($Windows) { return $true }
        if ($Linux) { return $false }
        if ($MacOS) { return $false }
    }  # Default to Windows
    Mock Get-EnvironmentVariable { Param($Name) 
        if ($Name -eq "USERPROFILE") { 
            return "$TestDrive\Users\Joshua" 
        } elseif ($Name -eq "HOME") { 
            return "$TestDrive\home\joshua" 
        } 
    }
    Mock Write-StatusMessage { }
}

Describe "Get-DevSetupPath" {

    Context "When on Windows" {
        It "Should return Windows path" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $true }
                if ($Linux) { return $false }
                if ($MacOS) { return $false }
            }
            $result = Get-DevSetupPath
            $result | Should -Be (Join-Path "$TestDrive\Users\Joshua" "devsetup")
            Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope It -ParameterFilter { $Name -eq "USERPROFILE" }
        }
    }

    Context "When on Linux" {
        It "Should return Linux path" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $true }
                if ($MacOS) { return $false }
            }
            $result = Get-DevSetupPath
            $result | Should -Be (Join-Path "$TestDrive\home\joshua" "devsetup")
            Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope It -ParameterFilter { $Name -eq "HOME" }
        }
    }

    Context "When on macOS" {
        It "Should return macOS path" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $false }
                if ($MacOS) { return $true }
            }
            $result = Get-DevSetupPath
            $result | Should -Be (Join-Path "$TestDrive\home\joshua" "devsetup")
            Assert-MockCalled Get-EnvironmentVariable -Exactly 1 -Scope It -ParameterFilter { $Name -eq "HOME" }
        }
    }

    Context "When environment variable is not set" {
        It "Should handle missing variable and return null" {
            Mock Get-EnvironmentVariable { $null }
            $result = Get-DevSetupPath
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "When Join-Path fails" {
        It "Should catch exception and return null" {
            Mock Join-Path { throw "Join-Path failed" }
            $result = Get-DevSetupPath
            $result | Should -Be $null
            Assert-MockCalled Write-StatusMessage -Exactly 2 -Scope It -ParameterFilter { $Verbosity -eq "Error" }
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $true }
                if ($Linux) { return $false }
                if ($MacOS) { return $false }
            }
            $result = Get-DevSetupPath
            $result | Should -Be (Join-Path "$TestDrive\Users\Joshua" "devsetup")
        }

        It "Should work on Linux" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $true }
                if ($MacOS) { return $false }
            }
            $result = Get-DevSetupPath
            $result | Should -Be (Join-Path "$TestDrive\home\joshua" "devsetup")
        }

        It "Should work on macOS" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $false }
                if ($MacOS) { return $true }
            }
            $result = Get-DevSetupPath
            $result | Should -Be (Join-Path "$TestDrive\home\joshua" "devsetup")
        }
    }
}