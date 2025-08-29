---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Export-InstalledChocolateyPackages

## SYNOPSIS
Exports installed Chocolatey packages to a YAML configuration file.

## SYNTAX

```
Export-InstalledChocolateyPackages [-Config] <String> [[-OutFile] <String>] [-DryRun]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans the system for installed Chocolatey packages and exports them to a YAML 
configuration file in DevSetup format.
It uses 'choco list --local-only --limit-output' to retrieve 
comprehensive package information including versions.
The function intelligently filters out 
system packages and can update existing configuration files by merging new packages with existing ones.

## EXAMPLES

### EXAMPLE 1
```
Export-InstalledChocolateyPackages -Config "environment.yaml"
```

Exports installed Chocolatey packages to the existing environment.yaml configuration file.

### EXAMPLE 2
```
Export-InstalledChocolateyPackages -Config "current.yaml" -OutFile "backup.yaml"
```

Reads from current.yaml and saves the updated configuration with installed packages to backup.yaml.

### EXAMPLE 3
```
Export-InstalledChocolateyPackages -Config "dev-env.yaml" -DryRun
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
### Returns $true if the export completes successfully or if no packages are found.
### Returns $false if there are errors during the export process.
## NOTES
- Requires administrator privileges to access all installed packages
- Uses 'choco list --local-only --limit-output' for machine-readable package information
- Automatically filters out system packages:
  * Packages ending with '.install' (installer packages)
  * Packages starting with 'chocolatey' (Chocolatey system packages)
- Merges with existing YAML configuration, preserving other sections and structure
- Supports both simple string format and complex object format for packages
- Updates existing packages when versions have changed
- Converts string entries to hashtable format when version information is added
- Creates the devsetup.dependencies.chocolatey structure if it doesn't exist
- Provides detailed console output with color-coded status messages for operations
- Handles YAML conversion errors gracefully by falling back to JSON format
- Tracks package changes: new additions, version updates, and no-change skips

## RELATED LINKS
