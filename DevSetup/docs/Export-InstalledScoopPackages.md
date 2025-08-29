---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Export-InstalledScoopPackages

## SYNOPSIS
Exports installed Scoop packages and buckets to a YAML configuration file.

## SYNTAX

```
Export-InstalledScoopPackages [-Config] <String> [[-OutFile] <String>] [-DryRun]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans the system for installed Scoop packages and buckets, then exports them to a YAML 
configuration file in DevSetup format.
It uses 'scoop export' to retrieve comprehensive package information
including versions, buckets, and global installation status.
The function can update existing configuration
files by merging new packages with existing ones, or create new configurations from scratch.

## EXAMPLES

### EXAMPLE 1
```
Export-InstalledScoopPackages -Config "environment.yaml"
```

Exports installed Scoop packages to the existing environment.yaml configuration file.

### EXAMPLE 2
```
Export-InstalledScoopPackages -Config "current.yaml" -OutFile "backup.yaml"
```

Reads from current.yaml and saves the updated configuration with installed packages to backup.yaml.

### EXAMPLE 3
```
Export-InstalledScoopPackages -Config "dev-env.yaml" -DryRun
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
### Returns $true if the export completes successfully or if Scoop is not installed (skipped).
### Returns $false if there are errors during the export process.
## NOTES
- Requires Scoop to be installed on the system (gracefully skips if not found)
- Uses 'scoop export' command to retrieve package and bucket information in JSON format
- Handles both local and global package installations using Info field detection
- Automatically skips the 'main' bucket as it's installed by default with Scoop
- Merges with existing YAML configuration, preserving other sections and structure
- Supports both simple string format and complex object format for packages and buckets
- Updates existing packages/buckets when versions or sources have changed
- Tracks global installation status and bucket information for each package
- Provides detailed console output with color-coded status messages for all operations
- Creates the devsetup.dependencies.scoop structure if it doesn't exist
- Processes buckets before packages to ensure proper dependency order
- Converts string entries to hashtable format when additional properties are needed
- Preserves existing package properties while updating changed values
- Includes comprehensive error handling for JSON parsing and file operations
- Returns $true even when no packages are found (successful empty result)

## RELATED LINKS
