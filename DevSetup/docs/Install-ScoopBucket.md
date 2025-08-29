---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-ScoopBucket

## SYNOPSIS
Adds a Scoop bucket to the system.

## SYNTAX

```
Install-ScoopBucket [-Name] <String> [[-Source] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function adds a specified Scoop bucket by executing the 'scoop bucket add' command.
It includes validation to ensure Scoop is installed and available before attempting the bucket addition.
The function supports adding both official buckets (by name only) and custom buckets (with source URL).
It checks if the bucket is already installed before attempting to add it and provides error handling 
with a boolean result indicating success or failure.

## EXAMPLES

### EXAMPLE 1
```
Install-ScoopBucket -Name "extras"
```

Adds the official 'extras' bucket to Scoop.

### EXAMPLE 2
```
Install-ScoopBucket -Name "nonportable"
```

Adds the official 'nonportable' bucket to Scoop.

### EXAMPLE 3
```
Install-ScoopBucket -Name "custom-bucket" -Source "https://github.com/user/scoop-bucket"
```

Adds a custom bucket from a GitHub repository.

### EXAMPLE 4
```
$result = Install-ScoopBucket -Name "games"
if ($result) {
    Write-Host "Games bucket added successfully"
} else {
    Write-Host "Failed to add games bucket"
}
```

Demonstrates capturing the return value to check bucket addition success.

## PARAMETERS

### -Name
The name of the Scoop bucket to add.
This parameter is mandatory and must be a valid string representing a bucket name.

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

### -Source
The source URL or Git repository for the bucket.
Optional parameter used for adding custom buckets.
If not specified, Scoop will attempt to add an official bucket by name.

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
### Returns $true if the bucket was successfully added or is already installed, $false if the operation failed.
## NOTES
- Requires Scoop to be installed on the system
- Uses Test-ScoopComponentInstalled to check if bucket is already installed before attempting to add it
- Returns $true if bucket is already installed (considered successful since goal is achieved)
- Returns $false immediately if Scoop is not installed or cannot be found
- Uses $LASTEXITCODE to verify command execution success
- Provides warning messages for common failure scenarios
- Uses try-catch error handling for robust failure management
- Official buckets can be added by name only (extras, nonportable, games, etc.)
- Custom buckets require both name and source URL parameters
- Suppresses command output using Out-Null to avoid console clutter

## RELATED LINKS
