BeforeAll {
    . $PSScriptRoot\Assert-DevSetupEnvValid.ps1
    
    # Helper function to create valid base configuration
    function Get-ValidBaseConfig {
        return @{
            devsetup = @{
                configuration = @{
                    createdBy = 'test'
                    description = 'test'
                    lastModified = '2023-01-01'
                    createdDate = '2023-01-01'
                    version = '1.0'
                    os = @{
                        architecture = 'x64'
                        name = 'Windows'
                        version = '10.0'
                    }
                    powershell = @{
                        version = '7.0'
                        edition = 'Core'
                    }
                }
                dependencies = @{
                    chocolatey = @{
                        packages = @(
                            @{
                                name = 'git'
                                version = '2.0.0'
                            }
                        )
                    }
                }
                commands = @()
            }
        }
    }
}

Describe "Assert-DevSetupEnvValid" {

    Context "Input validation - data types" {
        It "Should accept valid hashtable input" {
            $validData = Get-ValidBaseConfig
            
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
            $result = Assert-DevSetupEnvValid $validData
            $result | Should -Be $true
        }

        It "Should accept valid PSCustomObject input" {
            $validData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    configuration = [PSCustomObject]@{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = [PSCustomObject]@{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10.0'
                        }
                        powershell = [PSCustomObject]@{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = [PSCustomObject]@{
                        chocolatey = [PSCustomObject]@{
                            packages = @(
                                [PSCustomObject]@{
                                    name = 'git'
                                    version = '2.0.0'
                                }
                            )
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
            $result = Assert-DevSetupEnvValid $validData
            $result | Should -Be $true
        }

        It "Should reject non-dictionary input types" {
            { Assert-DevSetupEnvValid "invalid" } | Should -Throw "Environment data must be a hashtable or PSCustomObject."
            { Assert-DevSetupEnvValid 123 } | Should -Throw "Environment data must be a hashtable or PSCustomObject."
            { Assert-DevSetupEnvValid @() } | Should -Throw "Environment data must be a hashtable or PSCustomObject."
        }
    }

    Context "Required structure validation" {
        It "Should reject data without devsetup key" {
            $invalidData = @{ invalid = "data" }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Environment data must contain 'devsetup' key."
        }

        It "Should reject devsetup that is not dictionary-like" {
            $invalidData = @{
                devsetup = "invalid"
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "'devsetup' must be a hashtable or PSCustomObject."
        }

        It "Should reject devsetup without configuration" {
            $invalidData = @{
                devsetup = @{
                    dependencies = @{
                        chocolatey = @{
                            packages = @()
                        }
                    }
                    commands = @()
                }
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Environment data 'devsetup' section must contain 'configuration' key."
        }

        It "Should reject devsetup without dependencies" {
            $invalidData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10.0'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    commands = @()
                }
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Environment data 'devsetup' section must contain 'dependencies' key."
        }

        It "Should reject devsetup without commands" {
            $invalidData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10.0'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        chocolatey = @{
                            packages = @()
                        }
                    }
                }
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Environment data 'devsetup' section must contain 'commands' key."
        }
    }

    Context "Configuration section validation" {
        It "Should reject configuration that is not dictionary-like" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration = "invalid"
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "'configuration' must be a hashtable or PSCustomObject."
        }

        It "Should reject configuration missing 'createdBy' field" {
            $invalidData = Get-ValidBaseConfig
            $configWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.Keys) {
                if ($key -ne 'createdBy') {
                    $configWithoutField[$key] = $invalidData.devsetup.configuration[$key]
                }
            }
            $invalidData.devsetup.configuration = $configWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration must contain 'createdBy' key.*"
        }

        It "Should reject configuration missing 'description' field" {
            $invalidData = Get-ValidBaseConfig
            $configWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.Keys) {
                if ($key -ne 'description') {
                    $configWithoutField[$key] = $invalidData.devsetup.configuration[$key]
                }
            }
            $invalidData.devsetup.configuration = $configWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration must contain 'description' key.*"
        }

        It "Should reject configuration missing 'lastModified' field" {
            $invalidData = Get-ValidBaseConfig
            $configWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.Keys) {
                if ($key -ne 'lastModified') {
                    $configWithoutField[$key] = $invalidData.devsetup.configuration[$key]
                }
            }
            $invalidData.devsetup.configuration = $configWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration must contain 'lastModified' key.*"
        }

        It "Should reject configuration missing 'createdDate' field" {
            $invalidData = Get-ValidBaseConfig
            $configWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.Keys) {
                if ($key -ne 'createdDate') {
                    $configWithoutField[$key] = $invalidData.devsetup.configuration[$key]
                }
            }
            $invalidData.devsetup.configuration = $configWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration must contain 'createdDate' key.*"
        }

        It "Should reject configuration missing 'version' field" {
            $invalidData = Get-ValidBaseConfig
            $configWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.Keys) {
                if ($key -ne 'version') {
                    $configWithoutField[$key] = $invalidData.devsetup.configuration[$key]
                }
            }
            $invalidData.devsetup.configuration = $configWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration must contain 'version' key.*"
        }

        It "Should reject configuration where 'createdBy' is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration['createdBy'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'createdBy' must be a string or null.*"
        }

        It "Should reject configuration where 'description' is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration['description'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'description' must be a string or null.*"
        }

        It "Should reject configuration where 'lastModified' is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration['lastModified'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'lastModified' must be a string or null.*"
        }

        It "Should reject configuration where 'createdDate' is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration['createdDate'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'createdDate' must be a string or null.*"
        }

        It "Should reject configuration where 'version' is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration['version'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'version' must be a string or null.*"
        }

        It "Should reject configuration without os section" {
            $invalidData = Get-ValidBaseConfig
            # Create new hashtable without the os field
            $configWithoutOs = @{}
            foreach ($key in $invalidData.devsetup.configuration.Keys) {
                if ($key -ne 'os') {
                    $configWithoutOs[$key] = $invalidData.devsetup.configuration[$key]
                }
            }
            $invalidData.devsetup.configuration = $configWithoutOs
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Configuration must contain 'os' key."
        }

        It "Should reject os section that is not dictionary-like" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration.os = "invalid"
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Configuration 'os' must be a hashtable or PSCustomObject."
        }

        It "Should reject os section missing 'architecture' field" {
            $invalidData = Get-ValidBaseConfig
            $osWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.os.Keys) {
                if ($key -ne 'architecture') {
                    $osWithoutField[$key] = $invalidData.devsetup.configuration.os[$key]
                }
            }
            $invalidData.devsetup.configuration.os = $osWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'os' must contain 'architecture' key.*"
        }

        It "Should reject os section missing 'name' field" {
            $invalidData = Get-ValidBaseConfig
            $osWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.os.Keys) {
                if ($key -ne 'name') {
                    $osWithoutField[$key] = $invalidData.devsetup.configuration.os[$key]
                }
            }
            $invalidData.devsetup.configuration.os = $osWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'os' must contain 'name' key.*"
        }

        It "Should reject os section missing 'version' field" {
            $invalidData = Get-ValidBaseConfig
            $osWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.os.Keys) {
                if ($key -ne 'version') {
                    $osWithoutField[$key] = $invalidData.devsetup.configuration.os[$key]
                }
            }
            $invalidData.devsetup.configuration.os = $osWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'os' must contain 'version' key.*"
        }

        It "Should reject os 'architecture' that is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration.os['architecture'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'os.architecture' must be a string or null.*"
        }

        It "Should reject os 'name' that is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration.os['name'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'os.name' must be a string or null.*"
        }

        It "Should reject os 'version' that is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration.os['version'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'os.version' must be a string or null.*"
        }

        It "Should reject configuration without powershell section" {
            $invalidData = Get-ValidBaseConfig
            # Create new hashtable without the powershell field
            $configWithoutPs = @{}
            foreach ($key in $invalidData.devsetup.configuration.Keys) {
                if ($key -ne 'powershell') {
                    $configWithoutPs[$key] = $invalidData.devsetup.configuration[$key]
                }
            }
            $invalidData.devsetup.configuration = $configWithoutPs
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Configuration must contain 'powershell' key."
        }

        It "Should reject powershell section that is not dictionary-like" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration.powershell = "invalid"
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Configuration 'powershell' must be a hashtable or PSCustomObject."
        }

        It "Should reject powershell section missing 'version' field" {
            $invalidData = Get-ValidBaseConfig
            $psWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.powershell.Keys) {
                if ($key -ne 'version') {
                    $psWithoutField[$key] = $invalidData.devsetup.configuration.powershell[$key]
                }
            }
            $invalidData.devsetup.configuration.powershell = $psWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'powershell' must contain 'version' key.*"
        }

        It "Should reject powershell section missing 'edition' field" {
            $invalidData = Get-ValidBaseConfig
            $psWithoutField = @{}
            foreach ($key in $invalidData.devsetup.configuration.powershell.Keys) {
                if ($key -ne 'edition') {
                    $psWithoutField[$key] = $invalidData.devsetup.configuration.powershell[$key]
                }
            }
            $invalidData.devsetup.configuration.powershell = $psWithoutField
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'powershell' must contain 'edition' key.*"
        }

        It "Should reject powershell 'version' that is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration.powershell['version'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'powershell.version' must be a string.*"
        }

        It "Should reject powershell 'edition' that is not a string" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.configuration.powershell['edition'] = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*Configuration 'powershell.edition' must be a string.*"
        }
    }

    Context "Dependencies section validation" {
        It "Should reject dependencies that is not dictionary-like" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies = "invalid"
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "'dependencies' must be a hashtable or PSCustomObject."
        }

        It "Should reject manager data that is not dictionary-like" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.chocolatey = "invalid"
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Each package manager entry must be a hashtable or PSCustomObject."
        }

        It "Should reject PowerShell manager without scope" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.powershell = @{
                modules = @(
                    @{
                        name = 'Pester'
                        version = '5.0.0'
                        minimumVersion = '4.0.0'
                        scope = 'CurrentUser'
                    }
                )
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "PowerShell manager must contain 'scope' key."
        }

        It "Should reject PowerShell manager with non-string scope" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.powershell = @{
                scope = 123
                modules = @(
                    @{
                        name = 'Pester'
                        version = '5.0.0'
                        minimumVersion = '4.0.0'
                        scope = 'CurrentUser'
                    }
                )
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "PowerShell manager 'scope' must be a string."
        }

        It "Should reject manager with no package arrays" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.chocolatey = @{}
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Manager 'chocolatey' must contain at least one of: 'packages', 'modules', or 'buckets'."
        }
    }

    Context "Package validation" {
        It "Should reject package without name" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.chocolatey.packages = @(
                @{
                    version = '2.0.0'
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Each packages entry for manager 'chocolatey' must contain 'name' key."
        }

        It "Should reject package with empty name" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.chocolatey.packages[0].name = ''
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "'name' for packages entry must be a non-empty string."
        }

        It "Should reject package with non-string name" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.chocolatey.packages[0].name = 123
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "'name' for packages entry must be a non-empty string."
        }

        It "Should reject chocolatey package without version" {
            $invalidData = Get-ValidBaseConfig
            # Create package without version field
            $invalidData.devsetup.dependencies.chocolatey.packages = @(
                @{
                    name = 'git'
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "chocolatey package must contain 'version' key."
        }

        It "Should accept chocolatey package with empty version (simulating YAML null)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.chocolatey.packages[0].version = ''
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should accept package with optional minimumVersion" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.chocolatey.packages[0].minimumVersion = '1.0.0'
            $validData.devsetup.dependencies.chocolatey.packages[0].version = ''  # Make version empty when minimumVersion is set
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should reject package with both version and minimumVersion having values" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.chocolatey.packages[0].minimumVersion = '1.0.0'
            # version already has '2.0.0' from Get-ValidBaseConfig
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Cannot specify both 'version' and 'minimumVersion' with values for packages entry. Use only one."
        }
    }

    Context "PowerShell module validation" {
        It "Should accept valid PowerShell modules" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.powershell = @{
                scope = 'CurrentUser'
                modules = @(
                    @{
                        name = 'Pester'
                        version = '5.0.0'
                        minimumVersion = ''  # Empty when version is specified
                        scope = 'CurrentUser'
                    }
                )
            }
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should accept PowerShell modules with minimumVersion instead of version" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.powershell = @{
                scope = 'CurrentUser'
                modules = @(
                    @{
                        name = 'Pester'
                        version = ''  # Empty when minimumVersion is specified
                        minimumVersion = '4.0.0'
                        scope = 'CurrentUser'
                    }
                )
            }
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should reject PowerShell module without version" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.powershell = @{
                scope = 'CurrentUser'
                modules = @(
                    @{
                        name = 'Pester'
                        minimumVersion = '4.0.0'
                        scope = 'CurrentUser'
                    }
                )
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "PowerShell module must contain 'version' key."
        }

        It "Should reject PowerShell module without minimumVersion" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.powershell = @{
                scope = 'CurrentUser'
                modules = @(
                    @{
                        name = 'Pester'
                        version = '5.0.0'
                        scope = 'CurrentUser'
                    }
                )
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "PowerShell module must contain 'minimumVersion' key."
        }

        It "Should reject PowerShell module without scope" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.powershell = @{
                scope = 'CurrentUser'
                modules = @(
                    @{
                        name = 'Pester'
                        version = '5.0.0'
                        minimumVersion = '4.0.0'
                    }
                )
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "PowerShell module must contain 'scope' key."
        }
    }

    Context "Scoop validation" {
        It "Should accept valid Scoop configuration" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.scoop = @{
                buckets = @(
                    @{
                        name = 'extras'
                        source = 'https://github.com/ScoopInstaller/Extras'
                    }
                )
                packages = @(
                    @{
                        name = 'vscode'
                        version = '1.0.0'
                        bucket = 'extras'
                    }
                )
            }
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should reject Scoop package without bucket" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.scoop = @{
                packages = @(
                    @{
                        name = 'vscode'
                        version = '1.0.0'
                    }
                )
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Scoop package must contain 'bucket' key."
        }

        It "Should reject bucket without source" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.dependencies.scoop = @{
                buckets = @(
                    @{
                        name = 'extras'
                    }
                )
            }
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "scoop bucket must contain 'source' key."
        }
    }

    Context "Commands validation" {
        It "Should accept valid commands" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.commands = @(
                @{
                    command = 'npm install'
                    packageName = 'nodejs-setup'
                    params = @{
                        globalFlag = '-g'
                        package = 'typescript'
                    }
                }
            )
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should accept empty commands array" {
            $validData = Get-ValidBaseConfig
            # commands is already empty from Get-ValidBaseConfig
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should reject command without command field" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.commands = @(
                @{
                    packageName = 'test'
                    params = @{}
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Each command entry must contain 'command' key."
        }

        It "Should reject command with empty command field" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.commands = @(
                @{
                    command = ''
                    packageName = 'test'
                    params = @{}
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "'command' must be a non-empty string."
        }

        It "Should reject command without packageName field" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.commands = @(
                @{
                    command = 'test'
                    params = @{}
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Each command entry must contain 'packageName' key."
        }

        It "Should reject command with empty packageName field" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.commands = @(
                @{
                    command = 'test'
                    packageName = ''
                    params = @{}
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "'packageName' must be a non-empty string."
        }

        It "Should reject command without params field" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.commands = @(
                @{
                    command = 'test'
                    packageName = 'test'
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Each command entry must contain 'params' key."
        }

        It "Should accept command with null parameters" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.commands = @(
                @{
                    command = 'test'
                    packageName = 'test'
                    params = @{
                        param1 = 'value1'
                        param2 = $null
                        param3 = 'value2'
                    }
                }
            )
            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
        }

        It "Should reject command with non-string parameters" {
            $invalidData = Get-ValidBaseConfig
            $invalidData.devsetup.commands = @(
                @{
                    command = 'test'
                    packageName = 'test'
                    params = @{
                        param1 = 'valid-param'
                        param2 = 123
                        param3 = 'another-valid-param'
                    }
                }
            )
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "Each parameter value in 'params' hashtable must be a string or null."
        }
    }

    Context "Helper function edge cases" {
        It "Should handle Test-KeyExists with unsupported object types" {
            # Create an object that's neither hashtable nor PSCustomObject
            $unsupportedObj = "string_object"
            
            # Create minimal valid environment data with this problematic object as repositories
            $invalidData = @{
                repositories = $unsupportedObj
                packages = @{
                    chocolatey = @()
                    winget = @()
                }
                commands = @()
            }

            { Assert-DevSetupEnvValid $invalidData } | Should -Throw
        }

        It "Should handle Get-Value with unsupported object types" {
            # Create a custom object that doesn't match expected types
            $customObj = [System.Collections.ArrayList]::new()
            
            # Create environment data that will trigger Get-Value fallback
            $invalidData = @{
                repositories = @()
                packages = $customObj
                commands = @()
            }

            { Assert-DevSetupEnvValid $invalidData } | Should -Throw
        }
    }

    Context "YAML parsing edge cases" {
        It "Should handle null values from YAML parsing" {
            $yamlData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    configuration = [PSCustomObject]@{
                        createdBy = 'test'
                        description = $null  # Simulate YAML null
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = [PSCustomObject]@{
                            architecture = 'x64'
                            name = 'Windows'
                            version = $null  # Simulate YAML null
                        }
                        powershell = [PSCustomObject]@{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = [PSCustomObject]@{
                        chocolatey = [PSCustomObject]@{
                            packages = @(
                                [PSCustomObject]@{
                                    name = 'git'
                                    version = $null  # Simulate YAML null
                                }
                            )
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle List objects from YAML parsing" {
            $yamlData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    configuration = [PSCustomObject]@{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = [PSCustomObject]@{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10.0'
                        }
                        powershell = [PSCustomObject]@{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = [PSCustomObject]@{
                        chocolatey = [PSCustomObject]@{
                            packages = [System.Collections.Generic.List[System.Object]]@(
                                [PSCustomObject]@{
                                    name = 'git'
                                    version = '2.0.0'
                                }
                            )
                        }
                    }
                    commands = [System.Collections.Generic.List[System.Object]]@()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }
    }

    Context "Commands validation edge cases" {
        It "Should reject commands if not array or List (line 148)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.commands = "invalid_string_instead_of_array"

            { Assert-DevSetupEnvValid $validData } | Should -Throw "'commands' must be an array."
        }

        It "Should reject command without 'command' key (line 152)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.commands = @(
                @{
                    packageName = 'test-package'
                    params = @{}
                }
            )

            { Assert-DevSetupEnvValid $validData } | Should -Throw "Each command entry must contain 'command' key."
        }

        It "Should reject command params if not hashtable or PSCustomObject (line 200)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.commands = @(
                @{
                    command = 'test-command'
                    packageName = 'test-package'
                    params = "invalid_string_instead_of_hashtable"
                }
            )

            { Assert-DevSetupEnvValid $validData } | Should -Throw "'params' must be a hashtable or PSCustomObject."
        }

        It "Should reject non-string parameter in params hashtable (line 208)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.commands = @(
                @{
                    command = 'test-command'
                    packageName = 'test-package'
                    params = @{
                        validParam = 'valid-value'
                        invalidParam = 123
                        anotherValidParam = 'another-valid-value'
                    }
                }
            )

            { Assert-DevSetupEnvValid $validData } | Should -Throw "Each parameter value in 'params' hashtable must be a string or null."
        }
    }

    Context "Dependencies validation edge cases" {
        It "Should reject dependencies if not dictionary-like (line 216)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies = "invalid_string_instead_of_object"

            { Assert-DevSetupEnvValid $validData } | Should -Throw "'dependencies' must be a hashtable or PSCustomObject."
        }

        It "Should reject package manager entry if not dictionary-like (line 230)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.chocolatey = "invalid_string_instead_of_object"

            { Assert-DevSetupEnvValid $validData } | Should -Throw "Each package manager entry must be a hashtable or PSCustomObject."
        }

        It "Should reject bucket without source key (line 356)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.scoop = @{
                buckets = @(
                    @{
                        name = 'test-bucket'
                        # missing source key
                    }
                )
                packages = @()
            }

            { Assert-DevSetupEnvValid $validData } | Should -Throw "scoop bucket must contain 'source' key."
        }

        It "Should reject bucket source if not string (line 361)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.scoop = @{
                buckets = @(
                    @{
                        name = 'test-bucket'
                        source = 123  # not a string
                    }
                )
                packages = @()
            }

            { Assert-DevSetupEnvValid $validData } | Should -Throw "scoop bucket 'source' must be a string."
        }

        It "Should reject both version and minimumVersion with values (line 431)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.chocolatey = @{
                packages = @(
                    @{
                        name = 'test-package'
                        version = '1.0.0'
                        minimumVersion = '0.9.0'  # Both specified - should fail
                    }
                )
            }

            { Assert-DevSetupEnvValid $validData } | Should -Throw "Cannot specify both 'version' and 'minimumVersion' with values for packages entry. Use only one."
        }

        It "Should reject package manager with no arrays (line 437)" {
            $validData = Get-ValidBaseConfig
            $validData.devsetup.dependencies.emptymanager = @{
                # No packages, modules, or buckets arrays
            }

            { Assert-DevSetupEnvValid $validData } | Should -Throw "Manager 'emptymanager' must contain at least one of: 'packages', 'modules', or 'buckets'."
        }
    }

    Context "Complex valid scenarios" {
        It "Should accept comprehensive valid configuration" {
            $validData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10.0'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        powershell = @{
                            scope = 'CurrentUser'
                            modules = @(
                                @{
                                    name = 'Pester'
                                    version = '5.0.0'
                                    minimumVersion = ''  # Empty when version is specified
                                    scope = 'CurrentUser'
                                }
                            )
                        }
                        chocolatey = @{
                            packages = @(
                                @{
                                    name = 'git'
                                    version = '2.0.0'
                                },
                                @{
                                    name = 'nodejs'
                                    minimumVersion = '14.0.0'
                                    version = ''  # Empty when using minimumVersion
                                }
                            )
                        }
                        scoop = @{
                            buckets = @(
                                @{
                                    name = 'extras'
                                    source = 'https://github.com/ScoopInstaller/Extras'
                                }
                            )
                            packages = @(
                                @{
                                    name = 'vscode'
                                    version = '1.0.0'
                                    bucket = 'extras'
                                }
                            )
                        }
                    }
                    commands = @(
                        @{
                            command = 'npm install'
                            packageName = 'nodejs-setup'
                            params = @{
                                globalFlag = '-g'
                                package = 'typescript'
                            }
                        }
                    )
                }
            }

            { Assert-DevSetupEnvValid $validData } | Should -Not -Throw
            $result = Assert-DevSetupEnvValid $validData
            $result | Should -Be $true
        }
    }

    Context "Edge cases for 100% coverage" {
        It "Should handle invalid object types in helper functions" {
            # Test the fallback paths in helper functions that return $false and $null
            $invalidData = [PSCustomObject]@{
                devsetup = "not a valid object type"  # string instead of object
            }
            
            { Assert-DevSetupEnvValid $invalidData } | Should -Throw "*'devsetup' must be a hashtable or PSCustomObject.*"
        }

        It "Should handle commands as PSCustomObject with numeric properties" {
            $yamlData = [PSCustomObject]@{
                devsetup = [PSCustomObject]@{
                    configuration = [PSCustomObject]@{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = [PSCustomObject]@{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = [PSCustomObject]@{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = [PSCustomObject]@{
                        chocolatey = [PSCustomObject]@{
                            packages = @()
                        }
                    }
                    commands = [PSCustomObject]@{
                        '0' = [PSCustomObject]@{
                            command = 'echo test'
                            packageName = 'test'
                            params = @{
                                param1 = 'value1'
                            }
                        }
                    }
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle params as PSCustomObject with numeric properties" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        chocolatey = @{
                            packages = @()
                        }
                    }
                    commands = @(
                        @{
                            command = 'echo test'
                            packageName = 'test'
                            params = [PSCustomObject]@{
                                '0' = 'param1'
                                '1' = 'param2'
                            }
                        }
                    )
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle params as hashtable with numeric keys" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        chocolatey = @{
                            packages = @()
                        }
                    }
                    commands = @(
                        @{
                            command = 'echo test'
                            packageName = 'test'
                            params = @{
                                '0' = 'param1'
                                '1' = 'param2'
                            }
                        }
                    )
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should accept params as hashtable with non-numeric keys (single item)" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        chocolatey = @{
                            packages = @()
                        }
                    }
                    commands = @(
                        @{
                            command = 'echo test'
                            packageName = 'test'
                            params = @{
                                param = 'value'
                            }
                        }
                    )
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle PowerShell modules as PSCustomObject with numeric properties" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        powershell = @{
                            scope = 'CurrentUser'
                            modules = [PSCustomObject]@{
                                '0' = @{
                                    name = 'Pester'
                                    version = '5.7.1'
                                    minimumVersion = ''
                                    scope = 'CurrentUser'
                                }
                            }
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle PowerShell modules as hashtable with numeric keys" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        powershell = @{
                            scope = 'CurrentUser'
                            modules = @{
                                '0' = @{
                                    name = 'Pester'
                                    version = '5.7.1'
                                    minimumVersion = ''
                                    scope = 'CurrentUser'
                                }
                            }
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle PowerShell modules as single hashtable (non-numeric keys)" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        powershell = @{
                            scope = 'CurrentUser'
                            modules = @{
                                name = 'Pester'
                                version = '5.7.1'
                                minimumVersion = ''
                                scope = 'CurrentUser'
                            }
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle package arrays as PSCustomObject with numeric properties" {
            $managers = @('chocolatey', 'scoop', 'winget')
            foreach ($manager in $managers) {
                $dependencies = @{}
                $dependencies[$manager] = @{
                    packages = [PSCustomObject]@{
                        '0' = @{
                            name = 'git'
                            version = '2.40.0'
                        }
                    }
                }

                if ($manager -eq 'scoop') {
                    $dependencies[$manager].packages.'0'.bucket = 'main'
                }

                $yamlData = @{
                    devsetup = @{
                        configuration = @{
                            createdBy = 'test'
                            description = 'test'
                            lastModified = '2023-01-01'
                            createdDate = '2023-01-01'
                            version = '1.0'
                            os = @{
                                architecture = 'x64'
                                name = 'Windows'
                                version = '10'
                            }
                            powershell = @{
                                version = '7.0'
                                edition = 'Core'
                            }
                        }
                        dependencies = $dependencies
                        commands = @()
                    }
                }

                { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
            }
        }

        It "Should handle package arrays as hashtable with numeric keys" {
            $managers = @('chocolatey', 'scoop', 'winget')
            foreach ($manager in $managers) {
                $dependencies = @{}
                $dependencies[$manager] = @{
                    packages = @{
                        '0' = @{
                            name = 'git'
                            version = '2.40.0'
                        }
                    }
                }

                if ($manager -eq 'scoop') {
                    $dependencies[$manager].packages.'0'.bucket = 'main'
                }

                $yamlData = @{
                    devsetup = @{
                        configuration = @{
                            createdBy = 'test'
                            description = 'test'
                            lastModified = '2023-01-01'
                            createdDate = '2023-01-01'
                            version = '1.0'
                            os = @{
                                architecture = 'x64'
                                name = 'Windows'
                                version = '10'
                            }
                            powershell = @{
                                version = '7.0'
                                edition = 'Core'
                            }
                        }
                        dependencies = $dependencies
                        commands = @()
                    }
                }

                { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
            }
        }

        It "Should handle package arrays as single hashtable (non-numeric keys)" {
            $managers = @('chocolatey', 'scoop', 'winget')
            foreach ($manager in $managers) {
                $dependencies = @{}
                $dependencies[$manager] = @{
                    packages = @{
                        name = 'git'
                        version = '2.40.0'
                    }
                }

                if ($manager -eq 'scoop') {
                    $dependencies[$manager].packages.bucket = 'main'
                }

                $yamlData = @{
                    devsetup = @{
                        configuration = @{
                            createdBy = 'test'
                            description = 'test'
                            lastModified = '2023-01-01'
                            createdDate = '2023-01-01'
                            version = '1.0'
                            os = @{
                                architecture = 'x64'
                                name = 'Windows'
                                version = '10'
                            }
                            powershell = @{
                                version = '7.0'
                                edition = 'Core'
                            }
                        }
                        dependencies = $dependencies
                        commands = @()
                    }
                }

                { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
            }
        }

        It "Should handle Scoop buckets as PSCustomObject with numeric properties" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        scoop = @{
                            buckets = [PSCustomObject]@{
                                '0' = @{
                                    name = 'extras'
                                    source = 'https://github.com/ScoopInstaller/Extras.git'
                                }
                            }
                            packages = @()
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle Scoop buckets as hashtable with numeric keys" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        scoop = @{
                            buckets = @{
                                '0' = @{
                                    name = 'extras'
                                    source = 'https://github.com/ScoopInstaller/Extras.git'
                                }
                            }
                            packages = @()
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should handle Scoop buckets as single hashtable (non-numeric keys)" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        scoop = @{
                            buckets = @{
                                name = 'extras'
                                source = 'https://github.com/ScoopInstaller/Extras.git'
                            }
                            packages = @()
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Not -Throw
        }

        It "Should reject Scoop packages with invalid bucket field types" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        scoop = @{
                            packages = @(
                                @{
                                    name = 'git'
                                    bucket = 123  # Invalid - should be string
                                    version = '2.0.0'
                                }
                            )
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Throw "*Scoop package 'bucket' must be a string*"
        }

        It "Should reject invalid field types in generic package arrays" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        winget = @{
                            packages = @(
                                @{
                                    name = 123  # Invalid - should be string
                                    version = '1.0.0'
                                }
                            )
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Throw "*'name' for packages entry must be a non-empty string*"
        }

        It "Should reject invalid version field types in generic package arrays" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        winget = @{
                            packages = @(
                                @{
                                    name = 'git'
                                    version = 123  # Invalid - should be string
                                }
                            )
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Throw "*package 'version' must be a string*"
        }

        It "Should reject invalid minimumVersion field types in generic package arrays" {
            $yamlData = @{
                devsetup = @{
                    configuration = @{
                        createdBy = 'test'
                        description = 'test'
                        lastModified = '2023-01-01'
                        createdDate = '2023-01-01'
                        version = '1.0'
                        os = @{
                            architecture = 'x64'
                            name = 'Windows'
                            version = '10'
                        }
                        powershell = @{
                            version = '7.0'
                            edition = 'Core'
                        }
                    }
                    dependencies = @{
                        winget = @{
                            packages = @(
                                @{
                                    name = 'git'
                                    minimumVersion = 123  # Invalid - should be string
                                    version = ''
                                }
                            )
                        }
                    }
                    commands = @()
                }
            }

            { Assert-DevSetupEnvValid $yamlData } | Should -Throw "*package 'minimumVersion' must be a string*"
        }
    }

    Context "Test-KeyExists Coverage Gaps" {
        It "should handle unsupported object types" {
            # Line 14 - return false for unsupported object types
            $unsupportedObject = @(1, 2, 3)  # array is not hashtable or PSCustomObject
            $result = Test-KeyExists $unsupportedObject 'somekey'
            $result | Should -Be $false
        }
    }

    Context "Get-Value Coverage Gaps" {
        It "should return null for unsupported object types" {
            # Line 34 - return null for unsupported object types
            $unsupportedObject = @(1, 2, 3)  # array is not hashtable or PSCustomObject
            $result = Get-Value $unsupportedObject 'somekey'
            $result | Should -BeNullOrEmpty
        }
    }

    Context "ConvertTo-NormalizedArray Coverage Gaps" {
        It "should handle null input properly" {
            # Line 53 - handle null input case
            $result = ConvertTo-NormalizedArray $null
            # The function returns ,@() which is an empty array
            # PowerShell may unwrap it, so we check the behavior not the type
            $resultArray = @($result)  # Force into array context
            $resultArray.Count | Should -Be 0
            # The function should not return null - it should return an empty array
            # This tests that line 53: return ,@() is executed
        }

        It "should handle PSCustomObject with mixed properties" {
            # Line 73 - PSCustomObject with non-numeric properties
            $mixedObject = [PSCustomObject]@{
                '0' = 'first'
                'name' = 'test'
                '1' = 'second'
            }
            $result = ConvertTo-NormalizedArray $mixedObject
            # Should wrap single object in array since not all properties are numeric
            # The function returns ,@($InputObject) for mixed properties
            @($result).Count | Should -Be 1
            $result[0] | Should -Be $mixedObject
        }
    }

    Context "Assert-CommandsValid Coverage Gaps" {
        It "should throw error for empty command string" {
            # Line 191 - validate non-empty command strings
            $invalidCommands = @(
                [PSCustomObject]@{
                    command = ""  # empty string should fail
                    packageName = "test-package"
                    params = @()
                }
            )
            
            { Assert-CommandsValid $invalidCommands } | Should -Throw "*must be a non-empty string*"
        }
    }

    Context "Assert-PackageArrayValid Coverage Gaps" {
        It "should validate that ConvertTo-NormalizedArray produces arrays for package validation" {
            # Line 295 - test that normalized items are arrays
            # The key is that ConvertTo-NormalizedArray should produce an array
            # Create a test that exercises the normalization path
            $singlePackage = [PSCustomObject]@{
                name = "git" 
                version = "2.40.0"
            }
            
            # This should work because ConvertTo-NormalizedArray will wrap it in an array
            { Assert-PackageArrayValid -ManagerName "chocolatey" -ArrayType "packages" -Items $singlePackage } | Should -Not -Throw
            
            # This tests the actual error condition - when normalization fails to produce an array
            # Use a string that won't normalize to an array to trigger line 295
            Mock ConvertTo-NormalizedArray { return "not-an-array" }
            { Assert-PackageArrayValid -ManagerName "chocolatey" -ArrayType "packages" -Items $singlePackage } | Should -Throw "*must be an array*"
        }
    }

    Context "Assert-PackageItemValid Coverage Gaps" {
        It "should throw error for non-dictionary package item" {
            # Line 315 - validate dictionary-like item requirement
            $nonDictItem = "just-a-string"
            
            { Assert-PackageItemValid -ManagerName "chocolatey" -ArrayType "packages" -Item $nonDictItem } | Should -Throw "*must be a hashtable or PSCustomObject*"
        }
    }

    Context "Assert-PowerShellModuleValid Coverage Gaps" {
        It "should throw error when required field has non-string value" {
            # Line 359 - validate string type for required fields
            $invalidModule = [PSCustomObject]@{
                name = "TestModule"
                version = 123  # non-string version should fail
                minimumVersion = "1.0"
                scope = "CurrentUser"
            }
            
            { Assert-PowerShellModuleValid $invalidModule } | Should -Throw "*must be a string*"
        }
    }

    Context "Assert-GenericPackageValid Coverage Gaps" {
        It "should throw error when minimumVersion is not a string" {
            # Line 399 - validate minimumVersion string type
            $invalidPackage = [PSCustomObject]@{
                name = "TestPackage"
                version = "1.0"
                minimumVersion = 123  # non-string minimumVersion should fail
            }
            
            { Assert-GenericPackageValid $invalidPackage "chocolatey" } | Should -Throw "*minimumVersion' must be a string*"
        }
    }

    Context "Assert-VersionFieldsValid Coverage Gaps" {
        It "should throw error when version field is not a string" {
            # Line 436 - validate version field string type
            $itemWithInvalidVersion = [PSCustomObject]@{
                name = "TestItem"
                version = 123  # non-string version
                minimumVersion = ""
            }
            
            { Assert-VersionFieldsValid $itemWithInvalidVersion "package" } | Should -Throw "*version*must be a string*"
        }

        It "should throw error when minimumVersion field is not a string" {
            # Line 439 - validate minimumVersion field string type  
            $itemWithInvalidMinVersion = [PSCustomObject]@{
                name = "TestItem"
                version = ""
                minimumVersion = 123  # non-string minimumVersion
            }
            
            { Assert-VersionFieldsValid $itemWithInvalidMinVersion "package" } | Should -Throw "*minimumVersion*must be a string*"
        }
    }

    Context "Assert-DependenciesValid Coverage Gaps" {
        It "should handle PSCustomObject dependencies properly" {
            # Line 469 - PSCustomObject path in dependencies validation
            $dependencies = [PSCustomObject]@{
                chocolatey = [PSCustomObject]@{
                    packages = @(
                        [PSCustomObject]@{
                            name = "git"
                            version = "2.40.0"
                        }
                    )
                }
            }
            
            { Assert-DependenciesValid $dependencies } | Should -Not -Throw
        }
    }

    Context "Edge Cases and Integration Tests" {
        It "should handle complex nested structures with various data types" {
            # Test multiple coverage gaps in a single complex scenario
            $complexEnv = @{
                devsetup = @{
                    configuration = @{
                        createdBy = "TestUser"
                        description = "Test environment"
                        lastModified = "2025-01-01"
                        createdDate = "2025-01-01"
                        version = "1.0"
                        os = @{
                            architecture = "x64"
                            name = "Windows"
                            version = "10"
                        }
                        powershell = @{
                            version = "7.3.0"
                            edition = "Core"
                        }
                    }
                    dependencies = [PSCustomObject]@{  # Mix of hashtables and PSCustomObjects
                        chocolatey = @{
                            packages = @(
                                @{
                                    name = "git"
                                    version = $null  # null version should be handled
                                    minimumVersion = $null  # null minimumVersion should be handled
                                }
                            )
                        }
                        powershell = [PSCustomObject]@{
                            scope = "CurrentUser"
                            modules = @(
                                [PSCustomObject]@{
                                    name = "Pester"
                                    version = ""
                                    minimumVersion = "5.0"
                                    scope = "CurrentUser"
                                }
                            )
                        }
                    }
                    commands = @(
                        @{
                            command = "git --version"
                            packageName = "git"
                            params = @{
                                flag1 = $null
                                flag2 = ""
                            }  # Mix of null and empty params in hashtable
                        }
                    )
                }
            }
            
            { Assert-DevSetupEnvValid $complexEnv } | Should -Not -Throw
        }

        It "should properly validate all error conditions in sequence" {
            # Test that covers multiple validation paths
            
            # First test: invalid root structure
            { Assert-DevSetupEnvValid "not-an-object" } | Should -Throw "*must be a hashtable or PSCustomObject*"
            
            # Second test: invalid dependencies structure  
            $invalidDeps = @{
                devsetup = @{
                    configuration = @{
                        createdBy = "Test"
                        description = "Test"
                        lastModified = "2025-01-01"
                        createdDate = "2025-01-01"
                        version = "1.0"
                        os = @{ architecture = "x64"; name = "Windows"; version = "10" }
                        powershell = @{ version = "7.0"; edition = "Core" }
                    }
                    dependencies = "invalid-dependencies"  # string instead of object
                    commands = @()
                }
            }
            
            { Assert-DevSetupEnvValid $invalidDeps } | Should -Throw "*dependencies*must be a hashtable or PSCustomObject*"
        }
    } 

    Context "Assert-CommandsValid - Non-Dictionary Command Entry" {
        It "Should throw when array contains non-dictionary command entry" {
            # This targets line 191: throw "Each command entry must be a hashtable or PSCustomObject."
            # Pass an array containing a non-dictionary item
            $invalidCommands = @("invalid-string-entry")  # Array with string, not dictionary
            
            { Assert-CommandsValid -Commands $invalidCommands -Context "TestCommands" } | 
                Should -Throw "*Each command entry must be a hashtable or PSCustomObject*"
        }
        
        It "Should throw when array contains number entry (not dictionary-like)" {
            # Another test for line 191 with different invalid type
            $invalidCommands = @(123)  # Array with number, not dictionary-like
            
            { Assert-CommandsValid -Commands $invalidCommands -Context "TestCommands" } | 
                Should -Throw "*Each command entry must be a hashtable or PSCustomObject*"
        }
    }

    Context "Assert-DependenciesValid - Edge Case Analysis" {
        It "Should work with standard hashtable dependencies" {
            # Test with standard hashtable (should work normally and hit the hashtable branch)
            $validDependencies = @{
                chocolatey = @{ 
                    packages = @(
                        @{ name = "git"; version = "latest" }
                    )
                }
            }
            
            { Assert-DependenciesValid -Dependencies $validDependencies -Context "TestDeps" } | 
                Should -Not -Throw
        }

        It "Should work with PSCustomObject dependencies" {
            # Test with PSCustomObject (should hit the PSCustomObject branch)
            $validDependencies = [PSCustomObject]@{
                chocolatey = [PSCustomObject]@{ 
                    packages = @(
                        [PSCustomObject]@{ name = "git"; version = "latest" }
                    )
                }
            }
            
            { Assert-DependenciesValid -Dependencies $validDependencies -Context "TestDeps" } | 
                Should -Not -Throw
        }

        It "Should handle empty hashtable dependencies" {
            # Test with empty hashtable - should reach the hashtable branch and have no managers
            $emptyDependencies = @{}
            
            { Assert-DependenciesValid -Dependencies $emptyDependencies -Context "TestDeps" } | 
                Should -Not -Throw
        }
        
        It "Should document the theoretical edge case for line 469" {
            # Line 469 (@() assignment) represents a theoretical edge case where:
            # 1. Test-DictionaryLike returns true (object appears dictionary-like)
            # 2. Object fails both -is [hashtable] and -is [PSCustomObject] checks
            # 
            # This could theoretically happen with:
            # - Custom objects with spoofed type names
            # - COM objects that masquerade as dictionary-like
            # - Exotic .NET types that inherit dictionary behavior but aren't standard types
            #
            # In practice, this edge case is extremely rare and may be unreachable
            # with current PowerShell type system behavior.
            
            # For now, we document this as a known edge case
            $true | Should -Be $true  # Placeholder test to document the edge case
        }
    }

    Context "Assert-PackageManagerValid - PowerShell Manager Coverage" {
        It "Should throw when PowerShell manager has no packages, modules, or buckets" {
            # This targets line 302: PowerShell manager with valid scope but no arrays
            # Should throw "Manager 'powershell' must contain at least one of: 'packages', 'modules', or 'buckets'."
            
            $powershellManagerWithNoArrays = @{
                scope = "CurrentUser"  # Valid scope
                # Missing packages, modules, and buckets arrays
            }
            
            { Assert-PackageManagerValid -ManagerName "powershell" -ManagerData $powershellManagerWithNoArrays } | 
                Should -Throw "*Manager 'powershell' must contain at least one of: 'packages', 'modules', or 'buckets'*"
        }
        
        It "Should throw when Scoop manager has no packages, modules, or buckets" {
            # This targets line 320: Scoop manager with no arrays
            # Should throw "Manager 'scoop' must contain at least one of: 'packages', 'modules', or 'buckets'."
            
            $scoopManagerWithNoArrays = @{
                # Missing packages, modules, and buckets arrays
            }
            
            { Assert-PackageManagerValid -ManagerName "scoop" -ManagerData $scoopManagerWithNoArrays } | 
                Should -Throw "*Manager 'scoop' must contain at least one of: 'packages', 'modules', or 'buckets'*"
        }
        
        It "Should throw when Homebrew manager has no packages, modules, or buckets" {
            # This targets line 338: Homebrew manager with no arrays
            # Should throw "Manager 'homebrew' must contain at least one of: 'packages', 'modules', or 'buckets'."
            
            $homebrewManagerWithNoArrays = @{
                # Missing packages, modules, and buckets arrays
            }
            
            { Assert-PackageManagerValid -ManagerName "homebrew" -ManagerData $homebrewManagerWithNoArrays } | 
                Should -Throw "*Manager 'homebrew' must contain at least one of: 'packages', 'modules', or 'buckets'*"
        }
    }    
}
