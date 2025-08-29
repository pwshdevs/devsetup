---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Get-ScoopVersion

## SYNOPSIS
Retrieves the version information for the installed Scoop package manager.

## SYNTAX

```
Get-ScoopVersion [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function queries the installed Scoop package manager to determine its version.
It uses the 'scoop --version'
command and parses the output to extract version information.
The function handles both tagged releases 
(e.g., "v0.5.3") and development builds identified by commit hashes.
Output is completely suppressed during
execution to avoid console clutter.

## EXAMPLES

### EXAMPLE 1
```
Get-ScoopVersion
```

Retrieves the version of the currently installed Scoop package manager.

### EXAMPLE 2
```
$version = Get-ScoopVersion
if ($version) {
    Write-Host "Scoop version: $version"
} else {
    Write-Host "Scoop is not installed"
}
```

Demonstrates checking if Scoop is installed and displaying its version.

### EXAMPLE 3
```
switch (Get-ScoopVersion) {
    $null { "Scoop not found" }
    "installed" { "Scoop is installed but version unknown" }
    default { "Scoop version: $_" }
}
```

Shows handling different return scenarios from the function.

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
### Returns the Scoop version string if found, "installed" if version cannot be determined but Scoop is present,
### or $null if Scoop is not installed or cannot be found.
## NOTES
- Requires Scoop to be installed and accessible via Find-Scoop function
- Uses Start-Process with output redirection to completely suppress console output
- Parses version output with two fallback strategies:
  1. Tagged release format: "v0.5.3 - Released at..."
  2. Development build format: "ebd8c036 (HEAD -\> master..."
- Creates temporary files for output capture which are automatically cleaned up
- Returns "installed" if Scoop responds but version cannot be parsed
- Returns $null if Scoop is not found or accessible
- Handles errors gracefully without stopping execution

## RELATED LINKS
