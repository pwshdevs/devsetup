---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-ScoopPackage

## SYNOPSIS
Uninstalls a Scoop package from the system.

## SYNTAX

```
Uninstall-ScoopPackage [-PackageName] <String> [-Global] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function removes a specified Scoop package from the system by executing the 'scoop uninstall' command.
It includes validation to ensure Scoop is installed and available before attempting the uninstall operation.
The function checks if the package is installed before attempting removal and provides error handling with 
a boolean result indicating success or failure.

## EXAMPLES

### EXAMPLE 1
```
Uninstall-ScoopPackage -PackageName "git"
```

Uninstalls the 'git' package from Scoop.

### EXAMPLE 2
```
Uninstall-ScoopPackage -PackageName "nodejs"
```

Removes the 'nodejs' package from the system via Scoop.

### EXAMPLE 3
```
$result = Uninstall-ScoopPackage -PackageName "7zip"
if ($result) {
    Write-Host "7zip successfully removed or was not installed"
} else {
    Write-Host "Failed to remove 7zip"
}
```

Demonstrates capturing the return value to check uninstall success.

## PARAMETERS

### -PackageName
The name of the Scoop package to uninstall.
This parameter is mandatory and must be a valid string representing an installed Scoop package.

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

### -Global
{{ Fill Global Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
### Returns $true if the package was successfully uninstalled or if the package was not installed,
### $false if the uninstall operation failed.
## NOTES
- Requires Scoop to be installed on the system
- Uses Test-ScoopPackageInstalled function to verify package existence before uninstall
- Returns $true if package is not installed (considered successful since goal is achieved)
- Returns $false immediately if Scoop is not installed or cannot be found
- Provides warning messages for common failure scenarios

## RELATED LINKS
