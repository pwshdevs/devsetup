BeforeAll {
    . (Join-Path $PSScriptRoot "Wait-ForVisualStudioConfigFile.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\Devsetup\Private\Utils\Write-StatusMessage.ps1")
    Mock Write-StatusMessage { }
    Mock Start-Sleep { }
}

Describe "Wait-ForVisualStudioConfigFile" {

    Context "When config file exists and has content immediately" {
        BeforeEach {
            Mock Test-Path { return $true }
            Mock Get-Item { return @{ Length = 10 } }
        }
        It "Should return true without polling" {
            $configFile = "$TestDrive\config.txt"
            $result = Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 10
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[OK]" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Start-Sleep -Exactly 0 -Scope It
        }
    }

    Context "When config file exists but is empty initially, then gets content" {
        BeforeEach {
            $script:testPathCallCount = 0
            $script:getItemCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    default { 
                        return $true
                    }
                }
            }
            Mock Get-Item {
                switch ($script:getItemCallCount) {
                    0 { 
                        $script:getItemCallCount++
                        return @{ Length = 0 }
                    }
                    default { 
                        return @{ Length = 10 }
                    }
                }
            }
        }
        It "Should return true after polling" {
            $configFile = "$TestDrive\config.txt"
            New-Item -ItemType File -Path $configFile
            $result = Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 10 -PollIntervalSeconds 1
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[OK]" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Start-Sleep -Exactly 1 -Scope It
        }
    }

    Context "When config file does not exist initially, then is created with content" {
        BeforeEach {
            $script:testPathCallCount = 0
            $script:getItemCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $false
                    }
                    1 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    default { 
                        return $true
                    }
                }
            }
            Mock Get-Item {
                switch ($script:getItemCallCount) {
                    0 { 
                        $script:getItemCallCount++
                        return @{ Length = 10 }
                    }
                    default { 
                        return @{ Length = 10 }
                    }
                }
            }
        }
        It "Should return true after polling" {
            $configFile = "$TestDrive\config.txt"
            $result = Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 10 -PollIntervalSeconds 1
            $result | Should -Be $true
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[OK]" -and $ForegroundColor -eq "Green" }
            Assert-MockCalled Start-Sleep -Exactly 1 -Scope It
        }
    }

    Context "When config file does not exist and timeout is reached" {
        It "Should return false and write timeout messages" {
            Mock Test-Path { return $false }
            $configFile = "$TestDrive\config.txt"
            $result = Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 4 -PollIntervalSeconds 1
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[FAILED]" -and $ForegroundColor -eq "Red" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "The operation may still be running in the background. Check the installation manually." -and $Verbosity -eq "Warning" }
            Assert-MockCalled Start-Sleep -Exactly 4 -Scope It  # 4 / 1 = 4 polls
        }
    }

    Context "When config file exists but remains empty until timeout" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    default { 
                        return $true
                    }
                }
            }
            Mock Get-Item { return @{ Length = 0 } }
        }
        It "Should return false and write timeout messages" {
            $configFile = "$TestDrive\config.txt"
            New-Item -ItemType File -Path $configFile
            $result = Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 4 -PollIntervalSeconds 1
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[FAILED]" -and $ForegroundColor -eq "Red" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "The operation may still be running in the background. Check the installation manually." -and $Verbosity -eq "Warning" }
            Assert-MockCalled Start-Sleep -Exactly 4 -Scope It
        }
    }

    Context "When Test-Path throws an exception" {
        It "Should return false and write timeout messages" {
            Mock Test-Path { throw "Path access error" }
            $configFile = "$TestDrive\config.txt"
            { Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 4 -PollIntervalSeconds 1 } | Should -Throw "Path access error"
        }
    }

    Context "When Get-Item throws an exception" {
        BeforeEach {
            $script:testPathCallCount = 0
            Mock Test-Path {
                switch ($script:testPathCallCount) {
                    0 { 
                        $script:testPathCallCount++
                        return $true
                    }
                    default { 
                        return $true
                    }
                }
            }
            Mock Get-Item { throw "Item access error" }
        }
        It "Should return false and write timeout messages" {
            $configFile = "$TestDrive\config.txt"
            New-Item -ItemType File -Path $configFile
            { Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 4 -PollIntervalSeconds 1 } | Should -Throw "Item access error"
        }
    }

    Context "When config file path is empty" {
        It "Should throw due to parameter validation" {
            { Wait-ForVisualStudioConfigFile -ConfigFilePath "" } | Should -Throw
        }
    }

    Context "When config file path is null" {
        It "Should throw due to parameter validation" {
            { Wait-ForVisualStudioConfigFile -ConfigFilePath $null } | Should -Throw
        }
    }

    Context "When timeout is zero" {
        It "Should return false immediately if file not ready" {
            Mock Test-Path { return $false }
            $configFile = "$TestDrive\config.txt"
            $result = Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 0
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[FAILED]" -and $ForegroundColor -eq "Red" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "The operation may still be running in the background. Check the installation manually." -and $Verbosity -eq "Warning" }
            Assert-MockCalled Start-Sleep -Exactly 0 -Scope It
        }
    }

    Context "When poll interval is larger than timeout" {
        It "Should return false after one poll" {
            Mock Test-Path { return $false }
            $configFile = "$TestDrive\config.txt"
            $result = Wait-ForVisualStudioConfigFile -ConfigFilePath $configFile -TimeoutSeconds 1 -PollIntervalSeconds 5
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "[FAILED]" -and $ForegroundColor -eq "Red" }
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "The operation may still be running in the background. Check the installation manually." -and $Verbosity -eq "Warning" }
            Assert-MockCalled Start-Sleep -Exactly 1 -Scope It
        }
    }
}
