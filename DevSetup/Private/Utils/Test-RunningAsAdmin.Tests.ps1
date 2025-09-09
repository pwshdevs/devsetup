BeforeAll {
    . $PSScriptRoot\Test-RunningAsAdmin.ps1
    . $PSScriptRoot\Test-OperatingSystem.ps1
    Mock Test-OperatingSystem {
        Param($Windows, $Linux, $MacOS)
        if ($Windows) { return $true }
        if ($Linux) { return $false }
        if ($MacOS) { return $false }
    }  # Default to Windows
    Mock Invoke-Command { }
    Mock New-Object { }
}

Describe "Test-RunningAsAdmin" {

    Context "When not running on Windows" {
        It "Should return true (assume sufficient privileges)" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $true }
                if ($MacOS) { return $false }
            }
            $result = Test-RunningAsAdmin
            $result | Should -Be $true
        }
    }

    if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -eq 6 -and $IsWindows)) {
        Context "When running on Windows as administrator" {
            It "Should return true" {
                Mock Test-OperatingSystem {
                    Param($Windows, $Linux, $MacOS)
                    if ($Windows) { return $true }
                    if ($Linux) { return $false }
                    if ($MacOS) { return $false }
                }
                class MockPrincipal {
                    [bool] IsInRole([object]$role) { return $true }
                }
                $script:callCount = 0
                Mock Invoke-Command {
                    switch ($script:callCount) {
                        0 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                        1 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                    }
                }
                Mock New-Object -MockWith {
                    param($type)
                    return [MockPrincipal]::new()
                }
                $result = Test-RunningAsAdmin
                Assert-MockCalled 'Invoke-Command' -Exactly 2 -Scope It
                Assert-MockCalled 'New-Object' -Exactly 1 -Scope It
                Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It
                $result | Should -Be $true
            }
        }

        Context "When running on Windows but not as administrator" {
            It "Should return false" {
                Mock Test-OperatingSystem {
                    Param($Windows, $Linux, $MacOS)
                    if ($Windows) { return $true }
                    if ($Linux) { return $false }
                    if ($MacOS) { return $false }
                }
                class MockPrincipal {
                    [bool] IsInRole([object]$role) { return $false }
                }

                $script:callCount = 0
                Mock Invoke-Command {
                    switch ($script:callCount) {
                        0 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                        1 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                    }
                }
                Mock New-Object -MockWith {
                    param($type)
                    return [MockPrincipal]::new()
                }
                $result = Test-RunningAsAdmin
                Assert-MockCalled 'Invoke-Command' -Exactly 0 -Scope It
                Assert-MockCalled 'New-Object' -Exactly 1 -Scope It
                Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It                
                $result | Should -Be $false
            }
        }

        Context "When running on Windows and WindowsIdentity is null" {
            It "Should return false" {
                Mock Test-OperatingSystem {
                    Param($Windows, $Linux, $MacOS)
                    if ($Windows) { return $true }
                    if ($Linux) { return $false }
                    if ($MacOS) { return $false }
                }
                $script:callCount = 0
                Mock Invoke-Command {
                    switch ($script:callCount) {
                        0 {
                            $script:callCount++
                            return $null
                        }
                        1 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                    }
                }

                $result = Test-RunningAsAdmin
                Assert-MockCalled 'Invoke-Command' -Exactly 1 -Scope It
                Assert-MockCalled 'New-Object' -Exactly 0 -Scope It
                Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It                
                $result | Should -Be $false
            }
        }

        Context "When running on Windows and WindowsBuiltInRole is null" {
            It "Should return false" {
                Mock Test-OperatingSystem {
                    Param($Windows, $Linux, $MacOS)
                    if ($Windows) { return $true }
                    if ($Linux) { return $false }
                    if ($MacOS) { return $false }
                }
                $script:callCount = 0
                Mock Invoke-Command {
                    switch ($script:callCount) {
                        0 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                        1 {
                            $script:callCount++
                            return $null
                        }
                    }
                }
                $result = Test-RunningAsAdmin
                Assert-MockCalled 'Invoke-Command' -Exactly 2 -Scope It
                Assert-MockCalled 'New-Object' -Exactly 0 -Scope It
                Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It                
                $result | Should -Be $false
            }
        }

        Context "When running on Windows and New-Object fails" {
            It "Should return false" {
                Mock Test-OperatingSystem {
                    Param($Windows, $Linux, $MacOS)
                    if ($Windows) { return $true }
                    if ($Linux) { return $false }
                    if ($MacOS) { return $false }
                }
                $script:callCount = 0
                Mock Invoke-Command {
                    switch ($script:callCount) {
                        0 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                        1 {
                            $script:callCount++
                            return [PSCustomObject]@{ }
                        }
                    }
                }
                Mock 'New-Object' { throw "New-Object failed" }
                $result = Test-RunningAsAdmin
                Assert-MockCalled 'Invoke-Command' -Exactly 2 -Scope It
                Assert-MockCalled 'New-Object' -Exactly 1 -Scope It
                Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It                
                $result | Should -Be $false
            }
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
            class MockPrincipal {
                [bool] IsInRole([object]$role) { return $true }
            }
            $script:callCount = 0
            Mock Invoke-Command {
                switch ($script:callCount) {
                    0 {
                        $script:callCount++
                        return [PSCustomObject]@{ }
                    }
                    1 {
                        $script:callCount++
                        return [PSCustomObject]@{ }
                    }
                }
            }
            Mock 'New-Object' -MockWith {
                param($type)
                return [MockPrincipal]::new()
            }
            $result = Test-RunningAsAdmin
            Assert-MockCalled 'Invoke-Command' -Exactly 2 -Scope It
            Assert-MockCalled 'New-Object' -Exactly 1 -Scope It
            Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It            
            $result | Should -Be $true
        }

        It "Should work on Linux" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $true }
                if ($MacOS) { return $false }
            }
            $result = Test-RunningAsAdmin
            Assert-MockCalled 'Invoke-Command' -Exactly 0 -Scope It
            Assert-MockCalled 'New-Object' -Exactly 0 -Scope It
            Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It            
            $result | Should -Be $true
        }

        It "Should work on macOS" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $false }
                if ($Linux) { return $false }
                if ($MacOS) { return $true }
            }
            $result = Test-RunningAsAdmin
            Assert-MockCalled 'Invoke-Command' -Exactly 0 -Scope It
            Assert-MockCalled 'New-Object' -Exactly 0 -Scope It
            Assert-MockCalled 'Test-OperatingSystem' -Exactly 1 -Scope It            
            $result | Should -Be $true
        }
    }
}