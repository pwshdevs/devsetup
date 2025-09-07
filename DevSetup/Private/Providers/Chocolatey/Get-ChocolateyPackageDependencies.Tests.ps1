BeforeAll {
    . $PSScriptRoot\Get-ChocolateyPackageDependencies.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
    Mock Write-Debug { }
    if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
        Mock Get-EnvironmentVariable { return "C:\choco" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
        Mock Get-EnvironmentVariable { return "/opt/choco" }
    } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
        Mock Get-EnvironmentVariable { return "/opt/choco" }
    }
}

Describe "Get-ChocolateyPackageDependencies" {

    Context "When Chocolatey install path does not exist" {
        It "Should return $null in PS5, empty array in PS6+" {
            Mock Test-Path { return $false }
            $result = Get-ChocolateyPackageDependencies
            $result | Should -Be $null
        }
    }

    Context "When no nuspec files are found" {
        It "Should return $null in PS5, empty array in PS6+" {
            Mock Test-Path { return $true }
            Mock Get-ChildItem { @() }
            $result = Get-ChocolateyPackageDependencies
            $result | Should -Be $null
        }
    }

    Context "When nuspec files have no dependencies" {
        It "Should return $null in PS5, empty array in PS6+" {
            Mock Test-Path { return $true }
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "C:\choco\lib\foo\foo.nuspec" }
                    )
                }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/foo/foo.nuspec" }
                    )
                }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/foo/foo.nuspec" }
                    )
                }
            }
            Mock Get-Content { 
                '<package><metadata><dependencies></dependencies></metadata></package>' 
            }
            $result = Get-ChocolateyPackageDependencies
            $result | Should -Be $null
        }
    }

    Context "When nuspec files have dependencies including chocolatey system packages" {
        It "Should return only non-chocolatey dependencies" {
            Mock Test-Path { return $true }
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "C:\choco\lib\foo\foo.nuspec" }
                    )
                }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/foo/foo.nuspec" }
                    )
                }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/foo/foo.nuspec" }
                    )
                }
            }            
            Mock Get-Content { 
                '<package><metadata><dependencies>
                    <dependency id="chocolatey-core.extension" />
                    <dependency id="git" />
                    <dependency id="nodejs" />
                </dependencies></metadata></package>' 
            }
            $result = Get-ChocolateyPackageDependencies
            $result | Should -Not -Be $null
            $result | Should -Contain "git"
            $result | Should -Contain "nodejs"
            $result | Should -Not -Contain "chocolatey-core.extension"
        }
    }

    Context "When multiple nuspec files have overlapping dependencies" {
        It "Should return all dependencies including duplicates" {
            Mock Test-Path { return $true }
            if ($PSVersionTable.PSVersion.Major -eq 5 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "C:\choco\lib\foo\foo.nuspec" },
                        [PSCustomObject]@{ FullName = "C:\choco\lib\bar\bar.nuspec" }
                    )
                }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/foo/foo.nuspec" },
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/bar/bar.nuspec" }
                    )
                }
            } elseif ($PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS) {
                Mock Get-ChildItem { 
                    @(
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/foo/foo.nuspec" },
                        [PSCustomObject]@{ FullName = "/opt/choco/lib/bar/bar.nuspec" }
                    )
                }
            }
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
            Mock Get-Content -MockWith {
                $nuspecs[$script:callCount++]
            }
            $result = Get-ChocolateyPackageDependencies
            $result | Should -Not -Be $null          
            $result | Should -Contain "git"
            $result | Should -Contain "nodejs"
            $result | Should -Contain "python"
            ($result | Where-Object { $_ -eq "nodejs" }).Count | Should -Be 2
        }
    }
}