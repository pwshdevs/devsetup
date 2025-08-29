---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Get-DevSetupVersion

## SYNOPSIS
Retrieves the version of the DevSetup module.

## SYNTAX

```
Get-DevSetupVersion [-Local] [-Remote] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get-DevSetupVersion returns the current version of the DevSetup module either from the locally installed version or from the latest GitHub release.

## EXAMPLES

### EXAMPLE 1
```
Get-DevSetupVersion
Returns the version object of the locally installed DevSetup module.
```

### EXAMPLE 2
```
Get-DevSetupVersion -Local
Returns the version object of the locally installed DevSetup module.
```

### EXAMPLE 3
```
Get-DevSetupVersion -Remote
Returns the version object of the latest release from the GitHub repository.
```

### EXAMPLE 4
```
$version = Get-DevSetupVersion -Local
Write-Host "Major: $($version.Major), Minor: $($version.Minor), Build: $($version.Build)"
Gets the local version and displays individual components.
```

## PARAMETERS

### -Local
Retrieves the version from the locally installed DevSetup module.
This is the default behavior if no parameter is specified.

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

### -Remote
Retrieves the latest version from the GitHub repository using the latest release tag.

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

### System.Version. Returns the version object of the DevSetup module.
## NOTES
This function is used to check the installed version of the DevSetup module and returns a Version object for easy comparison and component access.
The Local and Remote parameters are mutually exclusive.
If neither is specified, Local is used by default.

## RELATED LINKS
