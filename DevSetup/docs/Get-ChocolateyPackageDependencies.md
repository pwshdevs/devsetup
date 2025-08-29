---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Get-ChocolateyPackageDependencies

## SYNOPSIS
Retrieves all package dependencies from installed Chocolatey packages.

## SYNTAX

```
Get-ChocolateyPackageDependencies [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function scans all installed Chocolatey packages and extracts their dependency information
by parsing the .nuspec files in the Chocolatey lib directory.
It reads the XML metadata from
each package's nuspec file and collects all non-Chocolatey dependencies into a consolidated
list.
The function automatically filters out Chocolatey-specific dependencies to focus on
actual package dependencies.

## EXAMPLES

### EXAMPLE 1
```
Get-ChocolateyPackageDependencies
```

Returns all package dependencies from installed Chocolatey packages.

### EXAMPLE 2
```
$dependencies = Get-ChocolateyPackageDependencies
if ($dependencies.Count -gt 0) {
    Write-Host "Found $($dependencies.Count) dependencies"
    $dependencies | ForEach-Object { Write-Host "- $_" }
}
```

Demonstrates retrieving and displaying all package dependencies.

### EXAMPLE 3
```
$allDeps = Get-ChocolateyPackageDependencies
$uniqueDeps = $allDeps | Select-Object -Unique | Sort-Object
```

Gets all dependencies and creates a sorted list of unique dependency names.

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

### [System.Array]
### Returns an array of package dependency names (strings) found across all installed packages.
### Returns an empty array if no dependencies are found or Chocolatey is not installed.
## NOTES
- Requires Chocolatey to be installed with packages in the standard lib directory
- Uses $Env:ChocolateyInstall environment variable to locate the Chocolatey installation
- Scans all .nuspec files recursively in the Chocolatey lib directory
- Parses XML metadata from nuspec files to extract dependency information
- Automatically filters out dependencies with IDs starting with "chocolatey" (Chocolatey system packages)
- Returns all dependencies in a flat array, including duplicates from multiple packages
- Provides debug logging for troubleshooting package discovery issues
- Returns empty array gracefully if Chocolatey installation path is not found
- Uses ForEach-Object (%) for efficient processing of large package collections

## RELATED LINKS
