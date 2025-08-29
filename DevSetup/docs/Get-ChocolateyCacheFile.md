---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Get-ChocolateyCacheFile

## SYNOPSIS
Gets the file path for the Chocolatey package cache file.

## SYNTAX

```
Get-ChocolateyCacheFile [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function constructs and returns the full path to the Chocolatey package cache file within the DevSetup
cache directory.
The cache file is used to store information about installed Chocolatey packages and their
versions for performance optimization and offline reference.
The function uses Get-DevSetupCachePath
to ensure the cache directory exists before returning the file path.

## EXAMPLES

### EXAMPLE 1
```
Get-ChocolateyCacheFile
```

Returns the path to the Chocolatey cache file, e.g., "C:\Users\Username\.devsetup\.cache\chocolatey.cache"

### EXAMPLE 2
```
$chocoCacheFile = Get-ChocolateyCacheFile
if (Test-Path $chocoCacheFile) {
    $cachedData = Get-Content $chocoCacheFile
}
```

Gets the cache file path and checks if it exists before reading cached data.

### EXAMPLE 3
```
$cacheFile = Get-ChocolateyCacheFile
Export-Clixml -Path $cacheFile -InputObject $chocolateyPackages
```

Uses the cache file path to save Chocolatey package information.

## PARAMETERS

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

### [System.String]
### Returns the full path to the Chocolatey cache file (chocolatey.cache) within the DevSetup cache directory.
## NOTES
- Uses Get-DevSetupCachePath to ensure the cache directory exists
- Returns a consistent file path (chocolatey.cache) within the DevSetup cache structure
- The cache file is used for storing Chocolatey package metadata and version information
- Does not create the cache file itself - only returns the path where it should be located
- Used by other Chocolatey-related functions for performance optimization and data persistence

## RELATED LINKS
