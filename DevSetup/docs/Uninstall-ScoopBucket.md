---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-ScoopBucket

## SYNOPSIS
Uninstalls a Scoop bucket from the system.

## SYNTAX

```
Uninstall-ScoopBucket [-Name] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function removes a Scoop bucket using the 'scoop bucket rm' command.
It validates
Scoop installation, locates the Scoop command, and checks if the bucket is currently
installed before attempting removal.
The function provides comprehensive error handling
and updates the Scoop cache after successful removal operations.

## EXAMPLES

### EXAMPLE 1
```
Uninstall-ScoopBucket -Name "extras"
```

Uninstalls the "extras" bucket from Scoop.

### EXAMPLE 2
```
$result = Uninstall-ScoopBucket -Name "java"
if ($result) {
    Write-Host "Java bucket removed successfully"
} else {
    Write-Host "Failed to remove Java bucket"
}
```

Demonstrates capturing the return value to check uninstallation success.

### EXAMPLE 3
```
@("extras", "versions", "java") | ForEach-Object {
    Uninstall-ScoopBucket -Name $_
}
```

Shows bulk uninstallation of multiple Scoop buckets.

## PARAMETERS

### -Name
The name of the Scoop bucket to uninstall.
This parameter is mandatory and must be a valid, non-empty string representing an installed Scoop bucket name.

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
### Returns $true if the bucket is successfully uninstalled or already uninstalled.
### Returns $false if the uninstallation fails or Scoop is not available.
## NOTES
- Requires Scoop to be installed on the system
- Uses Test-ScoopInstalled to validate Scoop availability
- Uses Find-Scoop to locate the Scoop command executable
- Returns $false immediately if Scoop is not available or cannot be found
- Uses Test-ScoopComponentInstalled to check if bucket is currently installed
- Returns $true if bucket is already uninstalled (idempotent behavior)
- Executes 'scoop bucket rm' command with output suppression
- Uses $LASTEXITCODE to verify command execution success
- Updates Scoop cache using Write-ScoopCache after successful removal
- Provides debug logging for successful and skipped operations
- Includes comprehensive try-catch error handling with descriptive error messages
- Suppresses all command output using *\> $null to avoid console clutter

## RELATED LINKS
