---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Find-Scoop

## SYNOPSIS
Locates the Scoop package manager executable on the system.

## SYNTAX

```
Find-Scoop [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function searches for the Scoop package manager executable using multiple detection methods.
It first attempts to find 'scoop' in the system PATH, and if not found, searches for Scoop
installation files in the default user profile directory.
The function returns the appropriate
command or file path that can be used to execute Scoop operations.

## EXAMPLES

### EXAMPLE 1
```
Find-Scoop
```

Locates the Scoop executable on the current system.

### EXAMPLE 2
```
$scoopCommand = Find-Scoop
if ($scoopCommand) {
    & $scoopCommand list
} else {
    Write-Warning "Scoop not found"
}
```

Demonstrates using the returned command to execute Scoop operations.

### EXAMPLE 3
```
switch (Find-Scoop) {
    "scoop" { "Scoop found in PATH" }
    { $_ -like "*scoop.ps1" } { "Found PowerShell script: $_" }
    { $_ -like "*scoop.cmd" } { "Found batch file: $_" }
    { $_ -like "*scoop" } { "Found executable: $_" }
    $null { "Scoop not found" }
}
```

Shows handling different types of Scoop installations.

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
### Returns "scoop" if found in PATH, the full file path to the Scoop executable if found in the user profile,
### or $null if Scoop cannot be located.
## NOTES
- Performs multiple checks to locate Scoop installations:
  1. Checks if 'scoop' command is available in PATH using Get-Command
  2. Searches for ~\scoop\shims\scoop.ps1 (PowerShell script)
  3. Searches for ~\scoop\shims\scoop.cmd (Command batch file)
  4. Searches for ~\scoop\shims\scoop (Executable)
- Returns the most accessible form first (PATH command before file paths)
- Suppresses errors when checking for the scoop command to avoid console output
- The returned value can be used directly with the call operator (&) or Invoke-Expression
- Does not verify that the found executable is functional, only that it exists

## RELATED LINKS
