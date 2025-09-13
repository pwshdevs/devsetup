BeforeAll {
    . $PSScriptRoot\Test-PowershellModuleInstalled.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Enums\InstalledState.ps1    
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Test-OperatingSystem.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Get-EnvironmentVariable.ps1
    . $PSScriptRoot\..\..\..\..\DevSetup\Private\Utils\Write-StatusMessage.ps1
    . $PSScriptRoot\Get-PowershellModuleScopeMap.ps1
    
    Mock Write-StatusMessage { }
    
    if($PSVersionTable.PSVersion.Major -eq 5) {
        $script:LocalModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
        $script:AllUsersModulePath = "$env:ProgramFiles\WindowsPowerShell\Modules"
        Mock Get-EnvironmentVariable { 
            Param(
                $Name
            )
            switch ($Name) {
                "USERPROFILE" { Write-Output $env:USERPROFILE }
                "PSModulePath" { Write-Output "$env:USERPROFILE\Documents\WindowsPowerShell\Modules;$env:ProgramFiles\WindowsPowerShell\Modules" }
            }
        }
        Mock Test-OperatingSystem { $true }
    } else {
        if($IsWindows) {
            $script:LocalModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules"
            $script:AllUsersModulePath = "$env:ProgramFiles\PowerShell\Modules"
            Mock Get-EnvironmentVariable { 
                Param(
                    $Name
                )
                switch ($Name) {
                    "USERPROFILE" { Write-Output $env:USERPROFILE }
                    "HOME" { Write-Output $env:HOME }
                    "PSModulePath" { Write-Output "$env:USERPROFILE\Documents\PowerShell\Modules;$env:ProgramFiles\PowerShell\Modules" }
                }                                
            }
            Mock Test-OperatingSystem { $true }
        }
        if($IsLinux) {
            $script:LocalModulePath = "$env:HOME/.local/share/powershell/Modules"
            $script:AllUsersModulePath = "/usr/local/share/powershell/Modules"
            Mock Get-EnvironmentVariable {
                Param(
                    $Name
                )
                switch ($Name) {
                    "USERPROFILE" { Write-Output $env:USERPROFILE }
                    "HOME" { Write-Output $env:HOME }
                    "PSModulePath" { Write-Output "$env:HOME/.local/share/powershell/Modules:/usr/local/share/powershell/Modules:/opt/microsoft/powershell/7/Modules" }
                }                
            }
            Mock Test-OperatingSystem { $false }
        }
        if($IsMacOS) {
            $script:LocalModulePath = "$env:HOME/.local/share/powershell/Modules"
            $script:AllUsersModulePath = "/usr/local/share/powershell/Modules"
            Mock Get-EnvironmentVariable { 
                Param(
                    $Name
                )
                switch ($Name) {
                    "USERPROFILE" { Write-Output $env:USERPROFILE }
                    "HOME" { Write-Output $env:HOME }
                    "PSModulePath" { Write-Output "$env:HOME/.local/share/powershell/Modules:/usr/local/share/powershell/Modules:/opt/microsoft/powershell/7/Modules" }
                }                
            }
            Mock Test-OperatingSystem { $false }
        }
    }

    # Mock Get-PowershellModuleScopeMap to return appropriate paths
    Mock Get-PowershellModuleScopeMap { @(
        @{ Path = $script:LocalModulePath; Scope = "CurrentUser" },
        @{ Path = $script:AllUsersModulePath; Scope = "AllUsers" }
    ) }
}

Describe "Test-PowershellModuleInstalled" {

    Context "When module is not installed" {
        It "Should return NotInstalled" {
            Mock Get-Module { return $null }
            $result = Test-PowershellModuleInstalled -ModuleName "notfound"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }

    Context "When module is installed (any version, any scope)" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "posh-git"
                    Version = "1.0.0"
                    Path = "$($script:LocalModulePath)$([System.IO.Path]::DirectorySeparatorChar)posh-git\posh-git.psd1"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "posh-git"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed with matching version" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "PSReadLine"
                    Version = "2.2.6"
                    Path = "$($script:LocalModulePath)$([System.IO.Path]::DirectorySeparatorChar)PSReadLine\PSReadLine.psd1"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "PSReadLine" -Version "2.2.6"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed but version does not match" {
        It "Should return Installed + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "PSReadLine"
                    Version = "2.2.5"
                    Path = "$($script:LocalModulePath)$([System.IO.Path]::DirectorySeparatorChar)PSReadLine\PSReadLine.psd1"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "PSReadLine" -Version "2.2.6"
            $expected = [InstalledState]::Installed + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed in AllUsers scope" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "PowerShellGet"
                    Version = "2.2.5"
                    Path = "$($script:AllUsersModulePath)$([System.IO.Path]::DirectorySeparatorChar)PowerShellGet\PowerShellGet.psd1"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "PowerShellGet" -Scope "AllUsers"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed in CurrentUser scope" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet + GlobalVersionMet" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "Az"
                    Version = "9.0.1"
                    Path = "$($script:LocalModulePath)$([System.IO.Path]::DirectorySeparatorChar)Az\Az.psd1"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "Az" -Scope "CurrentUser"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet + [InstalledState]::GlobalVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When Get-Module throws an exception" {
        It "Should return NotInstalled" {
            Mock Get-Module { throw "Unexpected error" }
            $result = Test-PowershellModuleInstalled -ModuleName "Az"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
        }
    }

    Context "When Get-PowershellModuleScopeMap throws an exception" {
        It "Should return NotInstalled and log error" {
            Mock Get-PowershellModuleScopeMap { throw "Scope map error" }
            $result = Test-PowershellModuleInstalled -ModuleName "Az"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "Failed to get PowerShell module scope map" -and $Verbosity -eq "Error" }
        }
    }

    Context "When Get-PowershellModuleScopeMap returns empty" {
        It "Should return NotInstalled and log warning" {
            Mock Get-PowershellModuleScopeMap { @() }
            $result = Test-PowershellModuleInstalled -ModuleName "Az"
            $result | Should -BeExactly ([InstalledState]::NotInstalled)
            Assert-MockCalled Write-StatusMessage -Scope It -ParameterFilter { $Message -match "No PowerShell module install paths found" -and $Verbosity -eq "Warning" }
        }
    }

    Context "When module is installed in wrong scope" {
        It "Should return Installed + MinimumVersionMet + RequiredVersionMet (without GlobalVersionMet)" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "TestModule"
                    Version = "1.0.0"
                    Path = "$($script:LocalModulePath)$([System.IO.Path]::DirectorySeparatorChar)TestModule\TestModule.psd1"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "TestModule" -Scope "AllUsers"
            $expected = [InstalledState]::Installed + [InstalledState]::MinimumVersionMet + [InstalledState]::RequiredVersionMet
            $result | Should -BeExactly $expected
        }
    }

    Context "When module is installed with version and scope both matching" {
        It "Should return full Pass state" {
            Mock Get-Module {
                [PSCustomObject]@{
                    Name = "FullTest"
                    Version = "3.1.4"
                    Path = "$($script:AllUsersModulePath)$([System.IO.Path]::DirectorySeparatorChar)FullTest\FullTest.psd1"
                }
            }
            $result = Test-PowershellModuleInstalled -ModuleName "FullTest" -Version "3.1.4" -Scope "AllUsers"
            $expected = [InstalledState]::Pass
            $result | Should -BeExactly $expected
        }
    }
}