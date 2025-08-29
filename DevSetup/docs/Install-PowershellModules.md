---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-PowershellModules

## SYNOPSIS
Installs PowerShell modules from YAML configuration data.

## SYNTAX

```
Install-PowershellModules [-YamlData] <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function processes YAML configuration data to install PowerShell modules using Install-PowerShellModule.
It supports both simple string formats and complex object formats for modules, allowing for detailed 
configuration including versions, installation scope, and module-specific parameters.
The function validates
administrator privileges when AllUsers scope is specified and provides comprehensive error handling and 
progress reporting throughout the installation process.

## EXAMPLES

### EXAMPLE 1
```
$yamlData = Get-Content "config.yaml" | ConvertFrom-Yaml
Install-PowershellModules -YamlData $yamlData
```

Installs PowerShell modules from a YAML configuration file.

### EXAMPLE 2
```
$yamlData = @{
    devsetup = @{
        dependencies = @{
            powershell = @{
                scope = "CurrentUser"
                modules = @(
                    "posh-git",
                    @{
                        name = "PSReadLine"
                        minimumVersion = "2.2.6"
                    },
                    @{
                        name = "PowerShellGet"
                        scope = "AllUsers"
                        force = $true
                        allowClobber = $false
                    }
                )
            }
        }
    }
}
Install-PowershellModules -YamlData $yamlData
```

Demonstrates the PSCustomObject structure and installs the configured modules.

## PARAMETERS

### -YamlData
The YAML configuration data containing PowerShell module definitions.
This parameter is mandatory and must be a PSCustomObject with the structure:
devsetup.dependencies.powershell.modules and optionally devsetup.dependencies.powershell.scope

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
### Returns $true if installation completes successfully (even if individual modules fail).
### Returns $false if configuration is invalid or critical errors occur.
## NOTES
- Requires the YAML configuration to have devsetup.dependencies.powershell.modules structure
- Returns $false immediately if PowerShell modules configuration is missing or invalid
- Supports global scope setting with module-specific overrides
- Default scope is 'CurrentUser' if not specified
- Validates administrator privileges when AllUsers scope is requested
- Supports both string and object formats for module definitions
- Module object format supports: name (required), minimumVersion (optional), scope (optional), force (optional), allowClobber (optional)
- Skips empty or invalid entries in the configuration without stopping execution
- Uses Install-PowerShellModule function for actual installation
- Provides detailed progress reporting with color-coded status messages
- Individual installation failures do not stop the overall process
- Tracks and reports installation counts for all processed modules
- Uses parameter splatting for reliable module installation

## RELATED LINKS
