---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Test-ChocolateyPackageInstalled

## SYNOPSIS
Tests whether a Chocolatey package is installed with optional version validation.

## SYNTAX

### PackageVersionCheck
```
Test-ChocolateyPackageInstalled -PackageName <String> -Version <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### PackageCheck
```
Test-ChocolateyPackageInstalled -PackageName <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function checks if a Chocolatey package is installed on the system and optionally validates
a specific version requirement.
It uses 'choco list' with exact matching to find installed packages
and examines the returned package information to determine installation status and version details.
The function supports multiple parameter sets to check different combinations of package existence
and version matching.

## EXAMPLES

### EXAMPLE 1
```
Test-ChocolateyPackageInstalled -PackageName "git"
```

Checks if the git package is installed (any version).

### EXAMPLE 2
```
Test-ChocolateyPackageInstalled -PackageName "nodejs" -Version "18.17.0"
```

Checks if nodejs package version 18.17.0 is installed.

### EXAMPLE 3
```
$isInstalled = Test-ChocolateyPackageInstalled -PackageName "vscode"
if ($isInstalled) {
    Write-Host "Visual Studio Code is installed"
} else {
    Write-Host "Visual Studio Code is not installed"
}
```

Demonstrates capturing the return value to check installation status.

## PARAMETERS

### -PackageName
The name of the Chocolatey package to check.
This parameter is mandatory for all parameter sets and must be a valid, non-empty string representing a Chocolatey package name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The specific version of the package to validate.
Mandatory parameter for PackageVersionCheck parameter set.
When specified, the function checks if the installed package matches this exact version.

```yaml
Type: String
Parameter Sets: PackageVersionCheck
Aliases:

Required: True
Position: Named
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
### Returns $true if the package meets all specified criteria (exists, version matches if specified).
### Returns $false if the package is not installed, doesn't meet the specified criteria, or an error occurs.
## NOTES
- Requires Chocolatey to be installed on the system
- Uses Test-ChocolateyInstalled to verify Chocolatey availability before proceeding
- Returns $false immediately if Chocolatey is not installed
- Uses 'choco list' with -exact and -r flags for precise package matching and machine-readable output
- Parses package information in "packagename|version" format returned by Chocolatey
- Suppresses command output using '*\>$null' to avoid console clutter
- Parameter sets determine validation criteria:
  * PackageCheck: Only checks if package exists (PackageName parameter only)
  * PackageVersionCheck: Checks existence and exact version match (PackageName and Version parameters)
- Includes comprehensive try-catch error handling with descriptive error messages
- Provides detailed debug logging for troubleshooting installation issues
- Uses ValidateNotNullOrEmpty attribute to ensure parameters contain valid values
- Returns early if package is not found to avoid unnecessary processing

## RELATED LINKS
