---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Get-DevSetupCachePath

## SYNOPSIS
Gets the DevSetup cache directory path and ensures it exists.

## SYNTAX

```
Get-DevSetupCachePath [<CommonParameters>]
```

## DESCRIPTION
This function retrieves the cache directory path for the DevSetup module.
The cache directory
is located at ".cache" within the main DevSetup directory and is used to store temporary files,
downloaded configurations, and other cached data.
The function automatically creates the cache
directory if it doesn't exist, ensuring it's always available for use.

## EXAMPLES

### EXAMPLE 1
```
Get-DevSetupCachePath
```

Returns the path to the DevSetup cache directory, e.g., "C:\Users\Username\.devsetup\.cache"

### EXAMPLE 2
```
$cachePath = Get-DevSetupCachePath
$tempFile = Join-Path $cachePath "temp-config.yaml"
```

Gets the cache path and creates a path for a temporary file within it.

### EXAMPLE 3
```
$cacheDir = Get-DevSetupCachePath
Get-ChildItem $cacheDir
```

Gets the cache directory and lists its contents.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [System.String]
### Returns the full path to the DevSetup cache directory.
## NOTES
- Uses Get-DevSetupPath to determine the base DevSetup directory
- Creates the cache directory (.cache) if it doesn't exist
- Returns the full path as a string for use in other functions
- The cache directory is hidden (starts with a dot) on Unix-like systems
- Suppresses output from New-Item using Out-Null for clean execution
- Ensures the cache directory is always available for DevSetup operations

## RELATED LINKS
