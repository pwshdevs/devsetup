---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Get-ChocolateyVersion

## SYNOPSIS
Retrieves the version of the installed Chocolatey package manager.

## SYNTAX

```
Get-ChocolateyVersion [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function gets the version information from Chocolatey by executing the 'choco --version' command.
It includes validation to ensure Chocolatey is installed before attempting to retrieve version information
and provides comprehensive error handling with appropriate warning messages for various failure scenarios.

## EXAMPLES

### EXAMPLE 1
```
Get-ChocolateyVersion
```

Returns the installed Chocolatey version, e.g., "1.4.0"

### EXAMPLE 2
```
$chocoVersion = Get-ChocolateyVersion
if ($chocoVersion) {
    Write-Host "Chocolatey version: $chocoVersion"
} else {
    Write-Host "Could not determine Chocolatey version"
}
```

Demonstrates capturing and validating the version result.

### EXAMPLE 3
```
$version = Get-ChocolateyVersion
if ($version -and [version]$version -lt [version]"1.0.0") {
    Write-Warning "Chocolatey version is outdated. Consider upgrading."
}
```

Shows version comparison for compatibility checking.

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
### Returns the Chocolatey version string (trimmed of whitespace) if successful.
### Returns $null if Chocolatey is not installed, version retrieval fails, or an error occurs.
## NOTES
- Requires Chocolatey to be installed on the system
- Uses Test-ChocolateyInstalled to verify Chocolatey availability before proceeding
- Returns $null immediately if Chocolatey is not installed
- Suppresses stderr output using '2\>$null' to avoid console clutter
- Trims whitespace from the version string for clean output
- Includes comprehensive try-catch error handling
- Provides descriptive warning messages for different failure scenarios
- Does not require administrator privileges

## RELATED LINKS
