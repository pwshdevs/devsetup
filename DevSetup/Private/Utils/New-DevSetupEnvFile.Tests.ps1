BeforeAll {
    . (Join-Path $PSScriptRoot "New-DevSetupEnvFile.ps1")
}

Describe "New-DevSetupEnvFile" {
    Context "Basic functionality" {
        It "should return a PSCustomObject" {
            $result = New-DevSetupEnvFile
            $result | Should -BeOfType [PSCustomObject]
        }

        It "should contain the devsetup root key" {
            $result = New-DevSetupEnvFile
            $result.PSObject.Properties.Name | Should -Contain "devsetup"
        }

        It "should have devsetup as PSCustomObject" {
            $result = New-DevSetupEnvFile
            $result.devsetup | Should -BeOfType [PSCustomObject]
        }
    }

    Context "Required top-level sections" {
        It "should contain dependencies section" {
            $result = New-DevSetupEnvFile
            $result.devsetup.PSObject.Properties.Name | Should -Contain "dependencies"
        }

        It "should contain commands section" {
            $result = New-DevSetupEnvFile
            $result.devsetup.PSObject.Properties.Name | Should -Contain "commands"
        }

        It "should contain configuration section" {
            $result = New-DevSetupEnvFile
            $result.devsetup.PSObject.Properties.Name | Should -Contain "configuration"
        }
    }

    Context "Dependencies structure" {
        It "should have dependencies as PSCustomObject" {
            $result = New-DevSetupEnvFile
            $result.devsetup.dependencies | Should -BeOfType [PSCustomObject]
        }

        It "should contain all standard package managers" {
            $result = New-DevSetupEnvFile
            $dependencies = $result.devsetup.dependencies
            $dependencies.PSObject.Properties.Name | Should -Contain "chocolatey"
            $dependencies.PSObject.Properties.Name | Should -Contain "powershell"
            $dependencies.PSObject.Properties.Name | Should -Contain "scoop"
            $dependencies.PSObject.Properties.Name | Should -Contain "homebrew"
        }

        It "should have chocolatey with empty packages array" {
            $result = New-DevSetupEnvFile
            $result.devsetup.dependencies.chocolatey | Should -Not -BeNullOrEmpty
            $result.devsetup.dependencies.chocolatey.packages.Count | Should -Be 0
        }

        It "should have powershell with modules array and scope" {
            $result = New-DevSetupEnvFile
            $powershell = $result.devsetup.dependencies.powershell
            $powershell.modules.Count | Should -Be 0
            $powershell.scope | Should -Be "CurrentUser"
        }

        It "should have scoop with empty packages and buckets arrays" {
            $result = New-DevSetupEnvFile
            $scoop = $result.devsetup.dependencies.scoop
            $scoop.packages.Count | Should -Be 0
            $scoop.buckets.Count | Should -Be 0
        }

        It "should have homebrew with empty packages array" {
            $result = New-DevSetupEnvFile
            $homebrew = $result.devsetup.dependencies.homebrew
            $homebrew.packages.Count | Should -Be 0
        }
    }

    Context "Commands structure" {
        It "should have commands as empty array" {
            $result = New-DevSetupEnvFile
            $result.devsetup.commands.Count | Should -Be 0
        }
    }

    Context "Configuration structure" {
        It "should have configuration as OrderedDictionary" {
            $result = New-DevSetupEnvFile
            $result.devsetup.configuration | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        }

        It "should contain all required configuration fields" {
            $result = New-DevSetupEnvFile
            $config = $result.devsetup.configuration
            $config.Keys | Should -Contain "description"
            $config.Keys | Should -Contain "version"
            $config.Keys | Should -Contain "createdDate"
            $config.Keys | Should -Contain "lastModified"
            $config.Keys | Should -Contain "createdBy"
            $config.Keys | Should -Contain "os"
            $config.Keys | Should -Contain "powershell"
        }

        It "should have default description" {
            $result = New-DevSetupEnvFile
            $result.devsetup.configuration.description | Should -Be "Auto-generated development environment configuration"
        }

        It "should have default version" {
            $result = New-DevSetupEnvFile
            $result.devsetup.configuration.version | Should -Be "1.0.0"
        }

        It "should have createdDate as string with current timestamp" {
            $result = New-DevSetupEnvFile
            $result.devsetup.configuration.createdDate | Should -BeOfType [System.String]
            $result.devsetup.configuration.createdDate | Should -Match '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
        }

        It "should have lastModified as string with current timestamp" {
            $result = New-DevSetupEnvFile
            $result.devsetup.configuration.lastModified | Should -BeOfType [System.String]
            $result.devsetup.configuration.lastModified | Should -Match '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
        }

        It "should have createdBy as null initially" {
            $result = New-DevSetupEnvFile
            $result.devsetup.configuration.createdBy | Should -BeNullOrEmpty
        }

        Context "OS information" {
            It "should have os as PSCustomObject" {
                $result = New-DevSetupEnvFile
                $result.devsetup.configuration.os | Should -BeOfType [PSCustomObject]
            }

            It "should have all OS fields as null initially" {
                $result = New-DevSetupEnvFile
                $os = $result.devsetup.configuration.os
                $os.name | Should -BeNullOrEmpty
                $os.version | Should -BeNullOrEmpty
                $os.architecture | Should -BeNullOrEmpty
            }

            It "should contain required OS fields" {
                $result = New-DevSetupEnvFile
                $os = $result.devsetup.configuration.os
                $os.PSObject.Properties.Name | Should -Contain "name"
                $os.PSObject.Properties.Name | Should -Contain "version"
                $os.PSObject.Properties.Name | Should -Contain "architecture"
            }
        }

        Context "PowerShell information" {
            It "should have powershell as PSCustomObject" {
                $result = New-DevSetupEnvFile
                $result.devsetup.configuration.powershell | Should -BeOfType [PSCustomObject]
            }

            It "should have current PowerShell version" {
                $result = New-DevSetupEnvFile
                $ps = $result.devsetup.configuration.powershell
                $ps.version | Should -Be $PSVersionTable.PSVersion.ToString()
            }

            It "should have current PowerShell edition" {
                $result = New-DevSetupEnvFile
                $ps = $result.devsetup.configuration.powershell
                $ps.edition | Should -Be $PSVersionTable.PSEdition
            }

            It "should contain required PowerShell fields" {
                $result = New-DevSetupEnvFile
                $ps = $result.devsetup.configuration.powershell
                $ps.PSObject.Properties.Name | Should -Contain "version"
                $ps.PSObject.Properties.Name | Should -Contain "edition"
            }
        }
    }

    Context "Validation compatibility" {
        It "should pass Assert-DevSetupEnvValid validation" {
            # This test ensures the canonical structure is always valid
            . (Join-Path $PSScriptRoot "Assert-DevSetupEnvValid.ps1")
            $result = New-DevSetupEnvFile
            { Assert-DevSetupEnvValid $result } | Should -Not -Throw
        }
    }

    Context "Timestamp consistency" {
        It "should have createdDate and lastModified within reasonable time range" {
            $beforeCall = Get-Date
            Start-Sleep -Milliseconds 10  # Small delay to ensure timestamp precision
            $result = New-DevSetupEnvFile
            Start-Sleep -Milliseconds 10  # Small delay to ensure timestamp precision
            $afterCall = Get-Date
            
            $createdDate = [DateTime]::ParseExact($result.devsetup.configuration.createdDate, "yyyy-MM-dd HH:mm:ss", $null)
            $lastModified = [DateTime]::ParseExact($result.devsetup.configuration.lastModified, "yyyy-MM-dd HH:mm:ss", $null)
            
            $createdDate | Should -BeGreaterOrEqual $beforeCall.AddSeconds(-1)
            $createdDate | Should -BeLessOrEqual $afterCall.AddSeconds(1)
            $lastModified | Should -BeGreaterOrEqual $beforeCall.AddSeconds(-1)
            $lastModified | Should -BeLessOrEqual $afterCall.AddSeconds(1)
        }

        It "should have identical createdDate and lastModified for new files" {
            $result = New-DevSetupEnvFile
            $result.devsetup.configuration.createdDate | Should -Be $result.devsetup.configuration.lastModified
        }
    }

    Context "Structure immutability" {
        It "should return same structure on multiple calls" {
            $result1 = New-DevSetupEnvFile
            $result2 = New-DevSetupEnvFile
            
            # Compare structure (not timestamps)
            $result1.devsetup.dependencies.PSObject.Properties.Name | Sort-Object | Should -Be ($result2.devsetup.dependencies.PSObject.Properties.Name | Sort-Object)
            $result1.devsetup.configuration.Keys | Where-Object { $_ -notin @('createdDate', 'lastModified') } | Sort-Object | Should -Be ($result2.devsetup.configuration.Keys | Where-Object { $_ -notin @('createdDate', 'lastModified') } | Sort-Object)
        }
    }

    Context "Data types validation" {
        It "should use correct data types for all fields" {
            $result = New-DevSetupEnvFile
            
            # Root structure
            $result | Should -BeOfType [PSCustomObject]
            $result.devsetup | Should -BeOfType [PSCustomObject]
            
            # Dependencies
            $result.devsetup.dependencies | Should -BeOfType [PSCustomObject]
            $result.devsetup.dependencies.chocolatey | Should -BeOfType [System.Collections.Hashtable]
            $result.devsetup.dependencies.powershell | Should -BeOfType [System.Collections.Hashtable]
            $result.devsetup.dependencies.scoop | Should -BeOfType [System.Collections.Hashtable]
            $result.devsetup.dependencies.homebrew | Should -BeOfType [System.Collections.Hashtable]
            
            # Test arrays by their Count property (empty arrays can be $null in PowerShell)
            $result.devsetup.dependencies.chocolatey.packages.Count | Should -Be 0
            $result.devsetup.dependencies.powershell.modules.Count | Should -Be 0
            $result.devsetup.dependencies.scoop.packages.Count | Should -Be 0
            $result.devsetup.dependencies.scoop.buckets.Count | Should -Be 0
            $result.devsetup.dependencies.homebrew.packages.Count | Should -Be 0
            $result.devsetup.commands.Count | Should -Be 0
            
            # Configuration
            $result.devsetup.configuration | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            $result.devsetup.configuration.os | Should -BeOfType [PSCustomObject]
            $result.devsetup.configuration.powershell | Should -BeOfType [PSCustomObject]
            
            # String fields
            $result.devsetup.configuration.description | Should -BeOfType [System.String]
            $result.devsetup.configuration.version | Should -BeOfType [System.String]
            $result.devsetup.configuration.createdDate | Should -BeOfType [System.String]
            $result.devsetup.configuration.lastModified | Should -BeOfType [System.String]
            $result.devsetup.dependencies.powershell.scope | Should -BeOfType [System.String]
        }
    }
}
