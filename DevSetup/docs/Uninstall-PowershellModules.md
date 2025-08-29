---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-PowershellModules

## SYNOPSIS
Uninstalls multiple PowerShell modules from the system based on YAML configuration.

## SYNTAX

```
Uninstall-PowershellModules [-YamlData] <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function removes multiple PowerShell modules specified in a DevSetup YAML configuration.
It validates administrator privileges when required, parses the configuration for PowerShell
module definitions, and systematically uninstalls each module.
The function supports both
simple string format and complex object format for module specifications, handles scope
settings, and provides comprehensive progress reporting during the uninstallation process.

## EXAMPLES

### EXAMPLE 1
```
$config = Read-ConfigurationFile -Path "environment.yaml"
Uninstall-PowershellModules -YamlData $config
```

Uninstalls all PowerShell modules defined in the environment.yaml configuration.

### EXAMPLE 2
```
$yamlData = @{
    devsetup = @{
        dependencies = @{
            powershell = @{
                scope = "CurrentUser"
                modules = @("PSReadLine", "Pester", "PowerShellGet")
            }
        }
    }
}
Uninstall-PowershellModules -YamlData $yamlData
```

Demonstrates uninstalling modules using a programmatically created configuration.

### EXAMPLE 3
```
if (Uninstall-PowershellModules -YamlData $config) {
    Write-Host "All PowerShell modules processed successfully"
} else {
    Write-Host "PowerShell module uninstallation encountered errors"
}
```

Shows checking the return value to verify uninstallation completion.

## PARAMETERS

### -YamlData
The parsed YAML configuration data containing PowerShell module definitions.
This parameter is mandatory and must be a PSCustomObject with the structure:
devsetup.dependencies.powershell.modules containing an array of module specifications.

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
### Returns $true if all modules are successfully processed (even if some individual uninstalls fail).
### Returns $false if the operation encounters critical errors or cannot proceed.
## NOTES
- Requires administrator privileges when uninstalling from AllUsers scope
- Uses Test-RunningAsAdmin to validate privileges when scope is AllUsers
- Throws an exception if AllUsers scope is specified without administrator privileges
- Skips uninstallation gracefully if no PowerShell modules are found in configuration
- Supports two module specification formats:
  * Simple string: "ModuleName"
  * Complex object: @{ name = "ModuleName"; minimumVersion = "1.0.0"; scope = "CurrentUser" }
- Global scope setting defaults to CurrentUser if not specified in configuration
- Module-specific scope settings override the global scope setting
- Validates module names and skips entries with missing names
- Uses Uninstall-PowerShellModule for individual module removal
- Provides detailed progress reporting with module counts and version information
- Uses color-coded console output: Cyan for progress, Gray for module status, Green/Red for results
- Continues processing remaining modules even if individual uninstalls fail
- Returns $true for overall success even with individual module failures
- Includes comprehensive try-catch error handling with descriptive error messages

## RELATED LINKS
