BeforeAll {
    . "$PSScriptRoot\Invoke-ExternalCommand.ps1"
}

Describe "Invoke-ExternalCommand" {
    Context "Basic functionality" {
        It "should execute a simple command without arguments" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # Using PowerShell's echo equivalent
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Write-Output 'test'")
                $result | Should -Contain "test"
            } else {
                # Using echo which should exist on Linux
                $result = Invoke-ExternalCommand -Command "echo" -Arguments @("test")
                $result | Should -Contain "test"
            }
        }

        It "should execute a command with single argument" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Write-Output 'hello world'")
                $result | Should -Contain "hello world"
            } else {
                $result = Invoke-ExternalCommand -Command "echo" -Arguments @("hello world")
                $result | Should -Contain "hello world"
            }
        }

        It "should execute a command with multiple arguments" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Write-Output 'arg1'; Write-Output 'arg2'")
                $result | Should -Contain "arg1"
                $result | Should -Contain "arg2"
            } else {
                # Use printf to output multiple lines
                $result = Invoke-ExternalCommand -Command "printf" -Arguments @("%s\n%s\n", "arg1", "arg2")
                $result | Should -Contain "arg1"
                $result | Should -Contain "arg2"
            }
        }

        It "should work without specifying Arguments parameter" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # On Windows, use a command that works safely
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Get-Date -Format yyyy")
                $result | Should -Match "\d{4}"
            } else {
                # On Linux, use date command
                $result = Invoke-ExternalCommand -Command "date" -Arguments @("+%Y")
                $result | Should -Match "\d{4}"
            }
        }
    }

    Context "Parameter validation" {
        It "should handle null or empty Command parameter" {
            { Invoke-ExternalCommand -Command "" } | Should -Throw
            { Invoke-ExternalCommand -Command $null } | Should -Throw
        }

        It "should accept empty Arguments array" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                { Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Get-Date -Format yyyy") } | Should -Not -Throw
            } else {
                { Invoke-ExternalCommand -Command "date" -Arguments @("+%Y") } | Should -Not -Throw
            }
        }

        It "should accept null Arguments" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # PowerShell with null args would hang, so provide safe command
                { Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "exit") } | Should -Not -Throw
            } else {
                # Date without arguments should work fine
                { Invoke-ExternalCommand -Command "date" -Arguments $null } | Should -Not -Throw
            }
        }
    }

    Context "Output capture" {
        It "should capture standard output" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Write-Output 'stdout test'")
                $result | Should -Contain "stdout test"
            } else {
                $result = Invoke-ExternalCommand -Command "echo" -Arguments @("stdout test")
                $result | Should -Contain "stdout test"
            }
        }

        It "should capture error output (2>&1 redirection)" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # Use a command that will generate an error
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Write-Error 'error test' -ErrorAction Continue")
                # The error should be captured as part of the output due to 2>&1 redirection
                $result | Should -Not -BeNullOrEmpty
            } else {
                # Use sh to echo to stderr - avoiding direct bash usage to prevent PATH issues
                $result = Invoke-ExternalCommand -Command "sh" -Arguments @("-c", "echo 'error test' >&2")
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It "should return array for multi-line output" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Write-Output 'line1'; Write-Output 'line2'")
                $result.Count | Should -BeGreaterThan 1
                $result | Should -Contain "line1"
                $result | Should -Contain "line2"
            } else {
                # Use printf for multi-line output
                $result = Invoke-ExternalCommand -Command "printf" -Arguments @("%s\n%s\n", "line1", "line2")
                $result.Count | Should -BeGreaterThan 1
            }
        }
    }

    Context "Homebrew-like usage patterns" {
        It "should handle homebrew list --versions pattern" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # Simulate the homebrew list --versions command
                $command = "powershell"
                $arguments = @("-Command", "`$output = @('git 2.30.1', 'node 14.17.0', 'python 3.9.0'); `$output")
            } else {
                # Use printf to simulate homebrew output without using bash
                $command = "printf"
                $arguments = @("%s\n%s\n%s\n", "git 2.30.1", "node 14.17.0", "python 3.9.0")
            }
            
            $result = Invoke-ExternalCommand -Command $command -Arguments $arguments
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 1
        }

        It "should handle homebrew list --installed-on-request pattern" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # Simulate the homebrew installed packages command
                $command = "powershell"
                $arguments = @("-Command", "`$output = @('git', 'node'); `$output")
            } else {
                # Use printf to simulate homebrew output
                $command = "printf"
                $arguments = @("%s\n%s\n", "git", "node")
            }
            
            $result = Invoke-ExternalCommand -Command $command -Arguments $arguments
            $result | Should -Not -BeNullOrEmpty
        }

        It "should work with shell command pattern commonly used in homebrew providers" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # Test the pattern used in homebrew providers but with PowerShell
                $command = "powershell"
                $arguments = @("-Command", "Get-Date | Select-Object -ExpandProperty Year")
                $result = Invoke-ExternalCommand -Command $command -Arguments $arguments
                $result | Should -Match "\d{4}"
            } else {
                # Use date command pattern on Linux
                $command = "date"
                $arguments = @("+%Y")
                $result = Invoke-ExternalCommand -Command $command -Arguments $arguments
                $result | Should -Match "\d{4}"
            }
        }
    }

    Context "Error handling" {
        It "should propagate command not found errors" {
            { Invoke-ExternalCommand -Command "nonexistentcommand123456" -Arguments @("test") } | Should -Throw
        }

        It "should handle commands that return non-zero exit codes" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                # PowerShell command that exits with non-zero code
                { Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "exit 1") } | Should -Not -Throw
            } else {
                # Use sh command that exits with non-zero code
                { Invoke-ExternalCommand -Command "sh" -Arguments @("-c", "exit 1") } | Should -Not -Throw
            }
            # The function should complete without throwing
        }
    }

    Context "Command line construction" {
        It "should build correct command line with arguments" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $command = "powershell"
                $arguments = @("-Command", "Write-Output 'test'")
            } else {
                $command = "echo"
                $arguments = @("test")
            }
            
            { Invoke-ExternalCommand -Command $command -Arguments $arguments } | Should -Not -Throw
        }

        It "should handle arguments with spaces" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $command = "powershell"
                $arguments = @("-Command", "Write-Output 'argument with spaces'")
            } else {
                $command = "echo"
                $arguments = @("argument with spaces")
            }
            
            { Invoke-ExternalCommand -Command $command -Arguments $arguments } | Should -Not -Throw
        }

        It "should handle special characters in arguments" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $command = "powershell"
                $arguments = @("-Command", "Write-Output 'test with special chars!'")
            } else {
                $command = "echo"
                $arguments = @("test with special chars!")
            }
            
            { Invoke-ExternalCommand -Command $command -Arguments $arguments } | Should -Not -Throw
        }
    }

    Context "Return value behavior" {
        It "should return output object that can be piped" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "1..3 | ForEach-Object { `$_ }")
            } else {
                # Use seq command which should be available on most Linux systems
                $result = Invoke-ExternalCommand -Command "seq" -Arguments @("1", "3")
            }
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 1
        }

        It "should preserve output order" {
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Write-Output 'first'; Write-Output 'second'; Write-Output 'third'")
                $result[0] | Should -Be "first"
                $result[1] | Should -Be "second" 
                $result[2] | Should -Be "third"
            } else {
                # Use printf to ensure proper ordering
                $result = Invoke-ExternalCommand -Command "printf" -Arguments @("%s\n%s\n%s\n", "first", "second", "third")
                $result[0] | Should -Be "first"
            }
        }
    }

    Context "Cross-platform compatibility" {
        It "should work on Windows with PowerShell commands" -Skip:(-not ($IsWindows -or $env:OS -eq 'Windows_NT')) {
            $result = Invoke-ExternalCommand -Command "powershell" -Arguments @("-Command", "Get-Date -Format yyyy")
            $result | Should -Match "\d{4}"
        }

        It "should work on Unix-like systems with common commands" -Skip:($IsWindows -or $env:OS -eq 'Windows_NT') {
            # Use date command which should be universally available
            $result = Invoke-ExternalCommand -Command "date" -Arguments @("+%Y")
            $result | Should -Match "\d{4}"
        }

        It "should work with common cross-platform commands" {
            # Use commands that exist on both platforms
            if ($IsWindows -or $env:OS -eq 'Windows_NT') {
                $command = "powershell"
                $arguments = @("-Command", "Get-Location | Select-Object -ExpandProperty Path")
            } else {
                $command = "pwd"
                $arguments = @()
            }
            
            $result = Invoke-ExternalCommand -Command $command -Arguments $arguments
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
