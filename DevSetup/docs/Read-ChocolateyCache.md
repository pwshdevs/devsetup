---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Read-ChocolateyCache

## SYNOPSIS
Reads cached Chocolatey package information from the DevSetup cache file.

## SYNTAX

```
Read-ChocolateyCache [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function reads cached Chocolatey package data from the DevSetup cache system.
It automatically handles cache file creation if the file doesn't exist by calling Write-ChocolateyCache,
and provides comprehensive error handling for file operations.
The function returns the cached data
as an array of strings for use by other Chocolatey-related functions.

## EXAMPLES

### EXAMPLE 1
```
Read-ChocolateyCache
```

Reads the Chocolatey cache data and returns it as an array of strings.

### EXAMPLE 2
```
$chocoCache = Read-ChocolateyCache
if ($chocoCache) {
    Write-Host "Found $($chocoCache.Count) cached entries"
} else {
    Write-Host "No cache data available"
}
```

Demonstrates reading cache data and checking for successful retrieval.

### EXAMPLE 3
```
$cachedPackages = Read-ChocolateyCache
$gitPackage = $cachedPackages | Where-Object { $_ -like "*git*" }
```

Shows reading cache data and filtering for specific package information.

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

### [System.Array]
### Returns the cached data as an array of strings if successful.
### Returns $null if the cache file cannot be read or parsed.
## NOTES
- Uses Get-ChocolateyCacheFile to determine the cache file location
- Automatically creates cache file if it doesn't exist using Write-ChocolateyCache
- Throws an exception if cache file creation fails
- Uses Get-Content to read the cached data as an array of strings
- Provides comprehensive error handling for file operations
- Returns $null on any error to allow calling functions to handle gracefully
- Used by other Chocolatey functions to avoid repeated system queries for performance
- Provides debug logging when cache file is not found

## RELATED LINKS
