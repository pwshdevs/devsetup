---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Read-ScoopCache

## SYNOPSIS
Reads cached Scoop package information from the DevSetup cache file.

## SYNTAX

```
Read-ScoopCache [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function reads and deserializes cached Scoop package data from the DevSetup cache system.
It automatically handles cache file creation if the file doesn't exist by calling Write-ScoopCache,
and provides comprehensive error handling for file operations and JSON parsing.
The function
returns the cached data as a PowerShell object for use by other Scoop-related functions.

## EXAMPLES

### EXAMPLE 1
```
Read-ScoopCache
```

Reads the Scoop cache data and returns it as a PowerShell object.

### EXAMPLE 2
```
$scoopCache = Read-ScoopCache
if ($scoopCache) {
    Write-Host "Found $($scoopCache.Count) cached packages"
} else {
    Write-Host "No cache data available"
}
```

Demonstrates reading cache data and checking for successful retrieval.

### EXAMPLE 3
```
$cachedPackages = Read-ScoopCache
$gitPackage = $cachedPackages | Where-Object { $_.name -eq "git" }
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

### [System.Object]
### Returns the deserialized cache data as a PowerShell object if successful.
### Returns $null if the cache file cannot be read or parsed.
## NOTES
- Uses Get-ScoopCacheFile to determine the cache file location
- Automatically creates cache file if it doesn't exist using Write-ScoopCache
- Throws an exception if cache file creation fails
- Uses ConvertFrom-Json to deserialize the cached data
- Provides comprehensive error handling for both file operations and JSON parsing
- Returns $null on any error to allow calling functions to handle gracefully
- Used by other Scoop functions to avoid repeated system queries for performance

## RELATED LINKS
