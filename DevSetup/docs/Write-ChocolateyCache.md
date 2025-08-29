---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Write-ChocolateyCache

## SYNOPSIS
Writes current Chocolatey package information to the DevSetup cache file.

## SYNTAX

```
Write-ChocolateyCache [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function exports the current Chocolatey package installation data and writes it to the DevSetup
cache file for performance optimization and offline reference.
It validates Chocolatey installation,
executes 'choco list -r' to generate machine-readable package data, and saves the output to the
cache file.
The function provides comprehensive error handling and validation throughout the process.

## EXAMPLES

### EXAMPLE 1
```
Write-ChocolateyCache
```

Exports current Chocolatey packages and writes them to the cache file.

### EXAMPLE 2
```
if (Write-ChocolateyCache) {
    Write-Host "Chocolatey cache updated successfully"
} else {
    Write-Host "Failed to update Chocolatey cache"
}
```

Demonstrates checking the return value to verify cache update success.

### EXAMPLE 3
```
$cacheUpdated = Write-ChocolateyCache
if ($cacheUpdated) {
    $cachedData = Read-ChocolateyCache
}
```

Shows writing cache data and then reading it back for use.

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

### [System.Boolean]
### Returns $true if the cache file is successfully written.
### Returns $false if Chocolatey is not installed or the write operation fails.
## NOTES
- Requires Chocolatey to be installed on the system
- Uses Test-ChocolateyInstalled to validate Chocolatey availability
- Returns $false immediately if Chocolatey is not available
- Executes 'choco list -r' to generate machine-readable package data with pipe-delimited format
- Uses Get-ChocolateyCacheFile to determine the cache file location
- Overwrites existing cache file using -Force flag
- Provides debug logging for successful cache operations
- Includes comprehensive try-catch error handling for command execution and file operations
- Uses Set-Content for reliable file writing with proper encoding

## RELATED LINKS
