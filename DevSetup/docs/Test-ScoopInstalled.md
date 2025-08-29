---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Test-ScoopInstalled

## SYNOPSIS
Tests whether Scoop package manager is installed on the system.

## SYNTAX

```
Test-ScoopInstalled [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function checks if Scoop is installed and available on the system by first attempting to locate
the scoop command in the PATH, and if not found, checking for Scoop installation files in the default
user profile directory.
It provides a comprehensive check for both standard installations and cases
where Scoop may not be properly added to the PATH environment variable.

## EXAMPLES

### EXAMPLE 1
```
Test-ScoopInstalled
```

Checks if Scoop is installed on the current system.

### EXAMPLE 2
```
if (Test-ScoopInstalled) {
    Write-Host "Scoop is available"
    # Proceed with Scoop operations
} else {
    Write-Host "Scoop is not installed"
    # Install Scoop or handle the missing dependency
}
```

Demonstrates using the function result to conditionally execute Scoop-dependent code.

### EXAMPLE 3
```
$scoopAvailable = Test-ScoopInstalled
switch ($scoopAvailable) {
    $true { "Scoop package manager detected" }
    $false { "Scoop package manager not found" }
}
```

Shows capturing the boolean result for later use.

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
### Returns $true if Scoop is installed and available, $false otherwise.
## NOTES
- Performs multiple checks to ensure reliable detection
- First checks if 'scoop' command is available in PATH using Get-Command
- Falls back to checking specific file paths in the user profile directory:
  * ~\scoop\shims\scoop.ps1 (PowerShell script)
  * ~\scoop\shims\scoop.cmd (Command batch file)
  * ~\scoop\shims\scoop (Executable)
- Does not verify that Scoop is functional, only that installation files exist
- Suppresses errors when checking for the scoop command to avoid console output

## RELATED LINKS
