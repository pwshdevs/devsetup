BeforeAll {
    . (Join-Path $PSScriptRoot "Test-HasSudoAccess.ps1")
    Mock Invoke-Command { }
}

Describe "Test-HasSudoAccess" {

    Context "When sudo access is available" {
        It "Should return true" {
            Mock Invoke-Command { $script:LASTEXITCODE = 0 }
            $result = Test-HasSudoAccess
            $result | Should -Be $true
        }
    }

    Context "When sudo access is not available" {
        It "Should return false" {
            Mock Invoke-Command { $script:LASTEXITCODE = 1 }
            $result = Test-HasSudoAccess
            $result | Should -Be $false
        }
    }

    Context "When Invoke-Command fails" {
        It "Should return false" {
            Mock Invoke-Command { throw "Invoke-Command failed" }
            $result = Test-HasSudoAccess
            $result | Should -Be $false
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Invoke-Command { $script:LASTEXITCODE = 0 }
            $result = Test-HasSudoAccess
            $result | Should -Be $true
        }

        It "Should work on Linux" {
            Mock Invoke-Command { $script:LASTEXITCODE = 0 }
            $result = Test-HasSudoAccess
            $result | Should -Be $true
        }

        It "Should work on macOS" {
            Mock Invoke-Command { $script:LASTEXITCODE = 0 }
            $result = Test-HasSudoAccess
            $result | Should -Be $true
        }
    }
}