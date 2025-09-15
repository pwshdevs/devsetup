BeforeAll {
    . $PSScriptRoot\Get-ChocolateyPackageDependencyMap.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
}

Describe "Get-ChocolateyPackageDependencyMap" {

    Context "When Get-EnvironmentVariable succeeds and lib directory exists with dependencies" {
        It "Should return all non-chocolatey dependencies from nuspec files" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            $nuspecPath1 = Join-Path $libPath "package1" "package1.nuspec"
            $nuspecPath2 = Join-Path $libPath "package2" "package2.nuspec"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { 
                @(
                    [PSCustomObject]@{ FullName = $nuspecPath1 },
                    [PSCustomObject]@{ FullName = $nuspecPath2 }
                )
            } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            
            $nuspecs = @(
                '<package><metadata><dependencies>
                    <dependency id="git" />
                    <dependency id="nodejs" />
                    <dependency id="chocolatey-core.extension" />
                </dependencies></metadata></package>',
                '<package><metadata><dependencies>
                    <dependency id="python" />
                    <dependency id="chocolatey-windowsupdate.extension" />
                </dependencies></metadata></package>'
            )
            $script:callCount = 0
            Mock Get-Content { $nuspecs[$script:callCount++] }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain "git"
            $result | Should -Contain "nodejs"
            $result | Should -Contain "python"
            $result | Should -Not -Contain "chocolatey-core.extension"
            $result | Should -Not -Contain "chocolatey-windowsupdate.extension"
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "Retrieving Chocolatey package dependencies..." -and $Verbosity -eq "Debug" 
            }
        }
    }

    Context "When Get-EnvironmentVariable throws an exception" {
        It "Should handle exception and return null" {
            Mock Get-EnvironmentVariable { throw "Environment variable access error" } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error retrieving ChocolateyInstall environment variable:" -and $Verbosity -eq "Error" 
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "at"
            }
        }
    }

    Context "When Join-Path throws an exception" {
        It "Should handle Join-Path exception and return null" {
            $chocolateyInstallPath = "InvalidPath:"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Join-Path { throw "Invalid path error" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error constructing Chocolatey lib path:" -and $Verbosity -eq "Error" 
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "at"
            }
        }
    }

    Context "When Test-Path throws an exception" {
        It "Should handle Test-Path exception and return null" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { throw "Path access error" } -ParameterFilter { $Path -eq $libPath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error testing Chocolatey lib path:" -and $Verbosity -eq "Error" 
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "at"
            }
        }
    }

    Context "When Chocolatey lib path does not exist" {
        It "Should return null and log debug message" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $libPath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -eq "Chocolatey installation path not found: $libPath" -and $Verbosity -eq "Debug" 
            }
        }
    }

    Context "When no nuspec files are found" {
        It "Should return null" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { @() } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
        }
    }

    Context "When nuspec files have no dependencies section" {
        It "Should return null" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            $nuspecPath = Join-Path $libPath "package1" "package1.nuspec"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { 
                @([PSCustomObject]@{ FullName = $nuspecPath })
            } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            Mock Get-Content { '<package><metadata></metadata></package>' }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
        }
    }

    Context "When nuspec files have empty dependencies section" {
        It "Should return null" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            $nuspecPath = Join-Path $libPath "package1" "package1.nuspec"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { 
                @([PSCustomObject]@{ FullName = $nuspecPath })
            } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            Mock Get-Content { '<package><metadata><dependencies></dependencies></metadata></package>' }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
        }
    }

    Context "When nuspec files contain only chocolatey dependencies" {
        It "Should return null after filtering" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            $nuspecPath = Join-Path $libPath "package1" "package1.nuspec"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { 
                @([PSCustomObject]@{ FullName = $nuspecPath })
            } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            Mock Get-Content { 
                '<package><metadata><dependencies>
                    <dependency id="chocolatey-core.extension" />
                    <dependency id="chocolatey-windowsupdate.extension" />
                    <dependency id="chocolatey" />
                </dependencies></metadata></package>' 
            }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
        }
    }

    Context "When processing nuspec files throws an exception" {
        It "Should handle processing exception and return null" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { throw "File access error" } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Message -match "Error processing nuspec files:" -and $Verbosity -eq "Error" 
            }
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { 
                $Verbosity -eq "Error" -and $Message -match "at"
            }
        }
    }

    Context "When multiple packages have overlapping dependencies" {
        It "Should return all dependencies including duplicates" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            $nuspecPath1 = Join-Path $libPath "package1" "package1.nuspec"
            $nuspecPath2 = Join-Path $libPath "package2" "package2.nuspec"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { 
                @(
                    [PSCustomObject]@{ FullName = $nuspecPath1 },
                    [PSCustomObject]@{ FullName = $nuspecPath2 }
                )
            } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            
            $nuspecs = @(
                '<package><metadata><dependencies>
                    <dependency id="git" />
                    <dependency id="nodejs" />
                </dependencies></metadata></package>',
                '<package><metadata><dependencies>
                    <dependency id="nodejs" />
                    <dependency id="python" />
                </dependencies></metadata></package>'
            )
            $script:callCount = 0
            Mock Get-Content { $nuspecs[$script:callCount++] }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain "git"
            $result | Should -Contain "nodejs"
            $result | Should -Contain "python"
            # Should have duplicates
            ($result | Where-Object { $_ -eq "nodejs" }).Count | Should -Be 2
        }
    }

    Context "Return value validation" {
        It "Should return null when no dependencies found" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $false } -ParameterFilter { $Path -eq $libPath }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -BeNullOrEmpty
        }

        It "Should return dependencies when found" {
            $chocolateyInstallPath = Join-Path $TestDrive "chocolatey"
            $libPath = Join-Path $chocolateyInstallPath "lib"
            $nuspecPath = Join-Path $libPath "package1" "package1.nuspec"
            
            Mock Get-EnvironmentVariable { return $chocolateyInstallPath } -ParameterFilter { $Name -eq "ChocolateyInstall" }
            Mock Test-Path { $true } -ParameterFilter { $Path -eq $libPath }
            Mock Get-ChildItem { 
                @([PSCustomObject]@{ FullName = $nuspecPath })
            } -ParameterFilter { $Path -eq $libPath -and $Recurse -eq $true -and $Filter -eq "*.nuspec" }
            Mock Get-Content { 
                '<package><metadata><dependencies>
                    <dependency id="git" />
                    <dependency id="nodejs" />
                </dependencies></metadata></package>' 
            }
            Mock Write-StatusMessage { }
            
            $result = Get-ChocolateyPackageDependencyMap
            
            $result | Should -Not -BeNullOrEmpty
            @($result) | Should -Contain "git"
            @($result) | Should -Contain "nodejs"
        }
    }
}