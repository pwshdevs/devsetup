BeforeAll {
    . (Join-Path $PSScriptRoot "Install-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "Test-ChocolateyPackageInstalled.ps1")
    . (Join-Path $PSScriptRoot "Uninstall-ChocolateyPackage.ps1")
    . (Join-Path $PSScriptRoot "Write-ChocolateyCache.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Utils\Test-RunningAsAdmin.ps1")
    . (Join-Path $PSScriptRoot "..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1")
    Mock Test-RunningAsAdmin { $true }
    Mock Test-ChocolateyPackageInstalled { }
    Mock Uninstall-ChocolateyPackage { $true }
    Mock Get-Command { "choco" }
    Mock Invoke-Command { }
    Mock Write-ChocolateyCache { $true }
    Mock Write-Debug { }
    Mock Write-Warning { }
    Mock Write-Error { }
}

Describe "Install-ChocolateyPackage" {

    Context "When not running as administrator" {
        It "Should throw and return false" {
            Mock Test-RunningAsAdmin { $false }
            $result = Install-ChocolateyPackage -PackageName "azshell"
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "administrator privileges" }
        }
    }

    Context "When package is already installed and version matches" {
        It "Should return true immediately" {
            Mock Test-ChocolateyPackageInstalled { 
                return ([InstalledState]::Pass)
            }
            $result = Install-ChocolateyPackage -PackageName "azshell"
            $result | Should -Be $true
        }
    }

    Context "When package is installed but version does not match" {
        It "Should uninstall and reinstall the package" {
            Mock Test-ChocolateyPackageInstalled { 
                return ([InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::GlobalVersionMet)
            }
            $script:uninstallCalled = $false
            Mock Uninstall-ChocolateyPackage -MockWith {
                param($PackageName)
                $script:uninstallCalled = $true
                $true
            }
            $script:LASTEXITCODE = 0
            Mock Invoke-Command {
                $script:LASTEXITCODE = 0
             }
            $result = Install-ChocolateyPackage -PackageName "azshell"
            $result | Should -Be $true
            $script:uninstallCalled | Should -Be $true
        }
    }

    Context "When installing with version and params" {
        It "Should build the correct choco command" {
            $script:LASTEXITCODE = 0
            $script:paramsPassed = $null
            Mock Test-ChocolateyPackageInstalled { return ([InstalledState]::NotInstalled) }
            Mock Invoke-Command -MockWith {
                param($ScriptBlock)
                $script:paramsPassed = $ScriptBlock.ToString()
            }
            $result = Install-ChocolateyPackage -PackageName "azshell" -Version "0.2.2" -Param "/silent"
            $result | Should -Be $true
            # You can add more checks for $paramsPassed if needed
        }
    }

    Context "When installation fails (non-zero exit code)" {
        It "Should write error and return false" {
            $script:LASTEXITCODE = 1
            Mock Test-ChocolateyPackageInstalled { return ([InstalledState]::NotInstalled) }
            $result = Install-ChocolateyPackage -PackageName "azshell"
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Failed to install" }
        }
    }

    Context "When Write-ChocolateyCache fails after install" {
        It "Should write warning and return false" {
            $script:LASTEXITCODE = 0
            Mock Test-ChocolateyPackageInstalled { return ([InstalledState]::NotInstalled) }
            Mock Write-ChocolateyCache { $false }
            $result = Install-ChocolateyPackage -PackageName "azshell"
            $result | Should -Be $false
            Assert-MockCalled Write-Warning -Scope It -ParameterFilter { $Message -match "Failed to write Chocolatey cache" }
        }
    }

    Context "When an exception occurs during install" {
        It "Should write error and return false" {
            Mock Test-ChocolateyPackageInstalled { throw "Unexpected error" }
            $result = Install-ChocolateyPackage -PackageName "azshell"
            $result | Should -Be $false
            Assert-MockCalled Write-Error -Scope It -ParameterFilter { $Message -match "Error checking/installing package" }
        }
    }
}