---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-ChocolateyPackages

## SYNOPSIS
Uninstalls multiple Chocolatey packages from the system based on YAML configuration.

## SYNTAX

```
Uninstall-ChocolateyPackages [-YamlData] <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function removes multiple Chocolatey packages specified in a DevSetup YAML configuration.
It validates administrator privileges, parses the configuration for Chocolatey package definitions,
and systematically uninstalls each package.
The function supports both simple string format and
complex object format for package specifications, handles version constraints, and provides
comprehensive progress reporting during the uninstallation process.

## EXAMPLES

### EXAMPLE 1
```
$config = Read-ConfigurationFile -Path "environment.yaml"
Uninstall-ChocolateyPackages -YamlData $config
```

Uninstalls all Chocolatey packages defined in the environment.yaml configuration.

### EXAMPLE 2
```
$yamlData = @{
    devsetup = @{
        dependencies = @{
            chocolatey = @{
                packages = @("git", "nodejs", "vscode")
            }
        }
    }
}
Uninstall-ChocolateyPackages -YamlData $yamlData
```

Demonstrates uninstalling packages using a programmatically created configuration.

### EXAMPLE 3
```
if (Uninstall-ChocolateyPackages -YamlData $config) {
    Write-Host "All Chocolatey packages processed successfully"
} else {
    Write-Host "Chocolatey uninstallation encountered errors"
}
```

Shows checking the return value to verify uninstallation completion.

## PARAMETERS

### -YamlData
The parsed YAML configuration data containing Chocolatey package definitions.
This parameter is mandatory and must be a PSCustomObject with the structure:
devsetup.dependencies.chocolatey.packages containing an array of package specifications.

```yaml
Type: PSObject
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
### Returns $true if all packages are successfully processed (even if some individual uninstalls fail).
### Returns $false if the operation encounters critical errors or cannot proceed.
## NOTES
- Requires administrator privileges to uninstall Chocolatey packages
- Uses Test-RunningAsAdmin to validate privileges before proceeding
- Throws an exception if not running as administrator
- Updates Chocolatey cache using Write-ChocolateyCache before uninstallation
- Skips uninstallation gracefully if no Chocolatey packages are found in configuration
- Supports two package specification formats:
  * Simple string: "packagename"
  * Complex object: @{ name = "packagename"; version = "1.0.0" }
- Validates package names and skips entries with missing names
- Uses Uninstall-ChocolateyPackage for individual package removal
- Provides detailed progress reporting with package counts and status indicators
- Uses color-coded console output: Cyan for progress, Gray for package status, Green/Red for results
- Continues processing remaining packages even if individual uninstalls fail
- Returns $true for overall success even with individual package failures
- Includes comprehensive try-catch error handling with descriptive error messages

## RELATED LINKS
