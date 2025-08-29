---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Show-DevSetupEnvList

## SYNOPSIS
Lists available development environment configurations with platform filtering.

## SYNTAX

```
Show-DevSetupEnvList [[-Platform] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function displays all available development environment configurations in a formatted table.
It supports platform-specific filtering to show only environments compatible with the current
system or a specified platform.
The function reads environment metadata from environments.json
and automatically creates this index file if it doesn't exist using Optimize-DevSetupEnvs.
Environments can be filtered by Windows, Linux, macOS, or shown for all platforms.

## EXAMPLES

### EXAMPLE 1
```
Show-DevSetupEnvList
```

Lists development environments compatible with the current platform.

### EXAMPLE 2
```
Show-DevSetupEnvList -Platform "all"
```

Displays all available development environments regardless of platform.

### EXAMPLE 3
```
Show-DevSetupEnvList -Platform "linux"
```

Shows only environments specifically designed for Linux systems.

### EXAMPLE 4
```
Show-DevSetupEnvList -Platform "windows"
```

Lists environments compatible with Windows systems.

## PARAMETERS

### -Platform
The platform to filter environments by.
Valid values: "current", "all", "windows", "linux", "macos"
Default value is "current" which shows environments for the detected platform.
Use "all" to display environments regardless of platform compatibility.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Current
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
### Returns $true when the function completes successfully, regardless of whether environments are found.
## NOTES
- Automatically detects the current platform using \[System.Environment\]::OSVersion.Platform
- Maps platform detection: Win32NT → windows, Unix → linux/macos via uname command
- Uses 'uname -s' command on Unix systems to distinguish between Linux (default) and macOS (Darwin)
- Reads environment metadata from environments.json in the DevSetup directory
- Automatically creates environments.json index if missing using Optimize-DevSetupEnvs
- Recreates the index file if environments.json is corrupted or unreadable JSON
- Supports cross-platform environments that work on multiple operating systems
- Includes environments with empty/unspecified platform as compatible with all platforms
- Platform filtering includes exact matches, "cross-platform" tagged environments, and unspecified platforms
- Displays results in a formatted table showing Name, Version, Platform, and File columns
- Shows "Not specified" for missing platform information and "Unknown" for missing version
- Provides helpful guidance when no environments are found for the specified platform
- Platform filtering and matching is case-insensitive for user convenience
- Displays environment count summary after the table
- Uses color-coded console output for better user experience

## RELATED LINKS
