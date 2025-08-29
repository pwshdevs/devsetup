---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-ScoopComponents

## SYNOPSIS
Uninstalls multiple Scoop components (buckets and packages) from the system based on YAML configuration.

## SYNTAX

```
Uninstall-ScoopComponents [-YamlData] <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function removes multiple Scoop components specified in a DevSetup YAML configuration.
It validates Scoop installation, parses the configuration for bucket and package definitions,
and systematically uninstalls components in the correct order (buckets first, then packages).
The function supports both simple string format and complex object format for component
specifications, handles global installations, and provides comprehensive progress reporting
during the uninstallation process.

## EXAMPLES

### EXAMPLE 1
```
$config = Read-ConfigurationFile -Path "environment.yaml"
Uninstall-ScoopComponents -YamlData $config
```

Uninstalls all Scoop buckets and packages defined in the environment.yaml configuration.

### EXAMPLE 2
```
$yamlData = @{
    devsetup = @{
        dependencies = @{
            scoop = @{
                buckets = @("extras", "versions")
                packages = @("git", "nodejs", "python")
            }
        }
    }
}
Uninstall-ScoopComponents -YamlData $yamlData
```

Demonstrates uninstalling components using a programmatically created configuration.

### EXAMPLE 3
```
if (Uninstall-ScoopComponents -YamlData $config) {
    Write-Host "All Scoop components processed successfully"
} else {
    Write-Host "Scoop component uninstallation encountered errors"
}
```

Shows checking the return value to verify uninstallation completion.

## PARAMETERS

### -YamlData
The parsed YAML configuration data containing Scoop component definitions.
This parameter is mandatory and must be a PSCustomObject with the structure:
devsetup.dependencies.scoop containing buckets and/or packages arrays.

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
### Returns $true if all components are successfully processed (even if some individual uninstalls fail).
### Returns $false if the operation encounters critical errors, Scoop is not installed, or cannot proceed.
## NOTES
- Requires Scoop to be installed on the system
- Uses Test-ScoopInstalled to validate Scoop availability before proceeding
- Updates Scoop cache using Write-ScoopCache before uninstallation begins
- Processes components in specific order: buckets first, then packages
- Skips uninstallation gracefully if Scoop configuration sections are not found
- Supports two component specification formats for both buckets and packages:
  * Simple string: "componentname"
  * Complex object: @{ name = "componentname"; version = "1.0.0"; bucket = "extras"; global = $true }
- Bucket objects support: name and source properties
- Package objects support: name, version, bucket, and global properties
- Validates component names and skips entries with missing names
- Uses Uninstall-ScoopBucket and Uninstall-ScoopPackage for individual component removal
- Provides detailed progress reporting with component counts and property information
- Uses color-coded console output: Cyan for progress, Gray for component status, Green/Red for results
- Continues processing remaining components even if individual uninstalls fail
- Returns $true for overall success even with individual component failures
- Includes comprehensive try-catch error handling with descriptive error messages
- Displays formatted component information including version, bucket, and global flags

## RELATED LINKS
