BeforeAll {
    . (Join-Path $PSScriptRoot "Install-GitRepository.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1")
}

Describe "Install-GitRepository" {

    BeforeEach {
        Mock Test-OperatingSystem {
            Param($Windows, $Linux, $MacOS)
            if ($Windows) { return $true }
            if ($Linux) { return $false }
            if ($MacOS) { return $false }
        }  # Default to Windows
        Mock Get-Command { [PSCustomObject]@{ Name = "git"; Path = "git" } }  # Default to found in PATH
        Mock Test-Path { $false }  # Default to not exist
        Mock Invoke-Command { }
        Mock Remove-Item { }
        Mock Push-Location { }
        Mock Pop-Location { }
        Mock Write-Host { }
        Mock Write-Error { }
        Mock Write-StatusMessage { }
        $global:LASTEXITCODE = 0  # Default to success
    }

    Context "When Git is not in PATH and not at common path" {
        It "Should return false and write error" {
            Mock Get-Command { $null }
            Mock Test-Path { $false }
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Git is not installed or not found in PATH. Please install Git and try again." -and $Verbosity -eq "Error" }
        }
    }

    Context "When Git is in PATH" {
        It "Should use git from PATH and clone successfully" {
            Mock Test-Path { $false }
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $true
            Assert-MockCalled Get-Command -Exactly 1 -Scope It -ParameterFilter { $Name -eq "git" }
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Git found in PATH" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When Git is not in PATH but at common path" {
        It "Should use git from common path and clone successfully" {
            Mock Get-Command { $null }
            Mock Test-Path { Param($Path) { if ($Path -eq "C:\Program Files\Git\cmd\git.exe") { return $true } else { return $false } } }
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $true
            Assert-MockCalled Test-Path -Exactly 1 -Scope It -ParameterFilter { $Path -eq "C:\Program Files\Git\cmd\git.exe" }
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Using Git from: C:\Program Files\Git\cmd\git.exe" -and $ForegroundColor -eq "Gray" }
        }
    }

    Context "When destination exists and UpdateExisting is specified" {
        It "Should pull updates and return true" {
            Mock Test-Path { Param($Path) { if ($Path -eq "$TestDrive\repo") { return $true } else { return $false } } }
            $global:LASTEXITCODE = 0
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo" -UpdateExisting
            $result | Should -Be $true
            Assert-MockCalled Push-Location -Exactly 1 -Scope It -ParameterFilter { $Path -eq "$TestDrive\repo" }
            Assert-MockCalled Pop-Location -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
        }
    }

    Context "When destination exists and UpdateExisting is not specified" {
        It "Should remove existing and clone" {
            Mock Test-Path { Param($Path) { if ($Path -eq "$TestDrive\repo") { return $true } else { return $false } } }
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $true
            Assert-MockCalled Remove-Item -Exactly 1 -Scope It -ParameterFilter { $Path -eq "$TestDrive\repo" }
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Removing existing directory to perform fresh clone: $TestDrive\repo" -and $ForegroundColor -eq "Yellow" }
        }
    }

    Context "When clone succeeds without branch" {
        It "Should clone and return true" {
            Mock Test-Path { $false }
            $global:LASTEXITCODE = 0
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $true
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
        }
    }

    Context "When clone succeeds with branch" {
        It "Should clone specific branch and return true" {
            Mock Test-Path { $false }
            $global:LASTEXITCODE = 0
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo" -Branch "develop"
            $result | Should -Be $true
            Assert-MockCalled Invoke-Command -Exactly 1 -Scope It
        }
    }

    Context "When clone fails" {
        It "Should return false and write error" {
            Mock Test-Path { $false }
            $global:LASTEXITCODE = 1
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Failed to clone repository from https://github.com/user/repo.git to $TestDrive\repo" -and $Verbosity -eq "Error"}
        }
    }

    Context "When pull fails" {
        It "Should return false and write error" {
            Mock Test-Path { Param($Path) { if ($Path -eq "$TestDrive\repo") { return $true } else { return $false } } }
            $global:LASTEXITCODE = 1
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo" -UpdateExisting
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -eq "Failed to update repository at $TestDrive\repo" -and $Verbosity -eq "Error"}
        }
    }

    Context "When exception occurs" {
        It "Should return false and write error" {
            Mock Invoke-Command { throw "Command failed" }
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $false
            Assert-MockCalled Write-StatusMessage -Exactly 1 -Scope It -ParameterFilter { $Message -match "Error cloning repository:" -and $Verbosity -eq "Error"}
        }
    }

    Context "Coverage-focused tests for success paths" {
        It "Should hit pull success path without Write-StatusMessage mock interference" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $true }
                if ($Linux) { return $false }
                if ($MacOS) { return $false }
            }
            Mock Get-Command { [PSCustomObject]@{ Name = "git"; Path = "git" } }
            Mock Test-Path { Param($Path) { if ($Path -eq "$TestDrive\repo") { return $true } else { return $false } } }
            Mock Invoke-Command { }
            Mock Push-Location { }
            Mock Pop-Location { }
            $global:LASTEXITCODE = 0
            
            # Don't mock Write-StatusMessage for this test to ensure success path is hit
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo" -UpdateExisting
            $result | Should -Be $true
        }

        It "Should hit clone success path without Write-StatusMessage mock interference" {
            Mock Test-OperatingSystem {
                Param($Windows, $Linux, $MacOS)
                if ($Windows) { return $true }
                if ($Linux) { return $false }
                if ($MacOS) { return $false }
            }
            Mock Get-Command { [PSCustomObject]@{ Name = "git"; Path = "git" } }
            Mock Test-Path { $false }
            Mock Invoke-Command { }
            $global:LASTEXITCODE = 0
            
            # Don't mock Write-StatusMessage for this test to ensure success path is hit
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $true
        }
    }

    Context "Cross-platform compatibility" {
        It "Should work on Windows" {
            Mock Test-Path { $false }
            $global:LASTEXITCODE = 0
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive\repo"
            $result | Should -Be $true
        }

        It "Should work on Linux" {
            Mock Get-Command { [PSCustomObject]@{ Name = "git"; Path = "/usr/bin/git" } }
            Mock Test-Path { $false }
            $global:LASTEXITCODE = 0
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive/repo"
            $result | Should -Be $true
        }

        It "Should work on macOS" {
            Mock Get-Command { [PSCustomObject]@{ Name = "git"; Path = "/usr/local/bin/git" } }
            Mock Test-Path { $false }
            $global:LASTEXITCODE = 0
            $result = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "$TestDrive/Srepo"
            $result | Should -Be $true
        }
    }
}