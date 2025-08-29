---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Export-InstalledPowershellModules

## SYNOPSIS
Exports installed PowerShell modules to a YAML configuration file.

## SYNTAX

```
Export-InstalledPowershellModules [-Config] <String> [[-OutFile] <String>] [-DryRun]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans the system for installed PowerShell modules and exports them to a YAML 
configuration file in DevSetup format.
It uses Get-InstalledModule to retrieve comprehensive 
module information including versions and installation scope.
The function intelligently skips 
core dependency modules defined in the DevSetup manifest and can update existing configuration
files by merging new modules with existing ones.

## EXAMPLES

### EXAMPLE 1
```
Export-InstalledPowershellModules -Config "environment.yaml"
```

Exports installed PowerShell modules to the existing environment.yaml configuration file.

### EXAMPLE 2
```
Export-InstalledPowershellModules -Config "current.yaml" -OutFile "backup.yaml"
```

Reads from current.yaml and saves the updated configuration with installed modules to backup.yaml.

### EXAMPLE 3
```
Export-InstalledPowershellModules -Config "dev-env.yaml" -DryRun
```

Shows what the configuration would look like without actually saving to file.

## PARAMETERS

### -Config
The path to the YAML configuration file to read from and write to.
This parameter is mandatory and specifies both the input and output file unless OutFile is specified.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutFile
The path to save the updated YAML configuration.
Optional parameter that allows saving to a different file than the input Config file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DryRun
Switch parameter that prevents writing to files and displays the resulting configuration to the console.
Useful for previewing changes before committing them to a file.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
### Returns $true if the export completes successfully or if no modules are found.
### Returns $false if there are errors during the export process.
## NOTES
- Requires administrator privileges to access all installed modules
- Uses Get-InstalledModule to retrieve module information from PowerShell Gallery
- Automatically skips core dependency modules listed in the DevSetup manifest
- Handles both CurrentUser and AllUsers scope modules using path analysis
- Merges with existing YAML configuration, preserving other sections
- Supports both simple string format and complex object format for modules
- Updates existing modules when versions have changed
- Converts string entries to hashtable format when additional properties are needed
- Tracks installation scope (CurrentUser/AllUsers) for each module
- Creates the devsetup.dependencies.powershell structure if it doesn't exist
- Provides detailed console output with color-coded status messages
- Includes comprehensive error handling for module scanning and file operations
- Preserves existing module properties while updating changed values

## RELATED LINKS
