---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Test-ChocolateyInstalled

## SYNOPSIS
Tests whether Chocolatey package manager is installed on the system.

## SYNTAX

```
Test-ChocolateyInstalled [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function checks if Chocolatey is installed and available by attempting to locate the 'choco' command.
It uses Get-Command to verify that the Chocolatey executable is accessible in the system PATH.
The function provides a warning message when Chocolatey is not found and returns a boolean result
indicating the installation status.

## EXAMPLES

### EXAMPLE 1
```
Test-ChocolateyInstalled
```

Checks if Chocolatey is installed on the system.

### EXAMPLE 2
```
if (Test-ChocolateyInstalled) {
    Write-Host "Chocolatey is available"
    # Proceed with Chocolatey operations
} else {
    Write-Host "Chocolatey is not installed"
    # Handle missing Chocolatey
}
```

Demonstrates conditional logic based on Chocolatey availability.

### EXAMPLE 3
```
$hasChocolatey = Test-ChocolateyInstalled
if (-not $hasChocolatey) {
    Install-Chocolatey
}
```

Shows using the function result to trigger Chocolatey installation if needed.

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
### Returns $true if Chocolatey is installed and the 'choco' command is available.
### Returns $false if Chocolatey is not installed or the 'choco' command cannot be found.
## NOTES
- Uses Get-Command with -ErrorAction SilentlyContinue to suppress errors when 'choco' is not found
- Provides a descriptive warning message when Chocolatey is not installed
- Does not require administrator privileges to check installation status
- Checks for command availability rather than file system presence for more reliable detection
- Used as a prerequisite check by other Chocolatey-related functions in the DevSetup module

## RELATED LINKS
