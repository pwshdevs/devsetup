---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-ChocolateyPackages

## SYNOPSIS
Installs Chocolatey packages from YAML configuration data.

## SYNTAX

```
Install-ChocolateyPackages [-YamlData] <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function processes YAML configuration data to install Chocolatey packages using Install-ChocolateyPackage.
It supports both simple string formats and complex object formats for packages, allowing for detailed 
configuration including versions and custom installation parameters.
The function validates administrator 
privileges before proceeding and provides comprehensive error handling and progress reporting throughout 
the installation process.

## EXAMPLES

### EXAMPLE 1
```
$yamlData = Get-Content "config.yaml" | ConvertFrom-Yaml
Install-ChocolateyPackages -YamlData $yamlData
```

Installs Chocolatey packages from a YAML configuration file.

### EXAMPLE 2
```
$yamlData = @{
    devsetup = @{
        dependencies = @{
            chocolatey = @{
                packages = @(
                    "git",
                    @{
                        name = "nodejs"
                        version = "18.17.0"
                    },
                    @{
                        name = "googlechrome"
                        params = "/nogoogle"
                    },
                    @{
                        name = "vscode"
                        version = "1.75.0"
                        params = "/silent"
                    }
                )
            }
        }
    }
}
Install-ChocolateyPackages -YamlData $yamlData
```

Demonstrates the PSCustomObject structure and installs the configured packages.

## PARAMETERS

### -YamlData
The YAML configuration data containing Chocolatey package definitions.
This parameter is mandatory and must be a PSCustomObject with the structure:
devsetup.dependencies.chocolatey.packages

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [System.Boolean]
### Returns $true if installation completes successfully (even if individual packages fail).
### Returns $false if configuration is invalid or critical errors occur.
## NOTES
- Requires administrator privileges to install Chocolatey packages
- Uses Test-RunningAsAdmin to validate privileges before proceeding
- Throws an exception if not running as administrator
- Returns early with warning if Chocolatey packages configuration is missing
- Supports both string and object formats for package definitions:
  * String format: Simple package name for latest version
  * Object format: Supports name (required), version (optional), params (optional)
- Skips empty or invalid entries in the configuration without stopping execution
- Uses Install-ChocolateyPackage function for actual installation
- Provides detailed progress reporting with color-coded status messages
- Individual installation failures do not stop the overall process
- Tracks and reports installation counts for all processed packages
- Uses parameter splatting for reliable package installation
- Displays installation status (\[OK\]/\[FAILED\]) for each package

## RELATED LINKS
