---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-DevSetupEnv

## SYNOPSIS
Uninstalls a development environment configuration and removes all associated packages.

## SYNTAX

```
Uninstall-DevSetupEnv [-Name] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function removes a complete development environment by uninstalling all packages and components
defined in a YAML configuration file.
It processes PowerShell modules, Chocolatey packages, and
Scoop packages in sequence, effectively reversing the installation performed by Install-DevSetupEnv.
The function validates the configuration file exists and can be parsed before proceeding with
the uninstallation process.

## EXAMPLES

### EXAMPLE 1
```
Uninstall-DevSetupEnv -Name "WebDev"
```

Uninstalls all packages and components from the "WebDev" environment configuration.

### EXAMPLE 2
```
Uninstall-DevSetupEnv "DataScience"
```

Removes the complete "DataScience" development environment using positional parameter.

### EXAMPLE 3
```
$envName = "GameDev"
Uninstall-DevSetupEnv -Name $envName
```

Demonstrates using a variable to specify the environment name for uninstallation.

## PARAMETERS

### -Name
The name of the environment configuration to uninstall.
This parameter is mandatory and must match an existing YAML configuration file in the DevSetup environments directory.
The file should be named "{Name}.yaml" and contain valid DevSetup configuration structure.

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

### None
### This function does not return a value but provides console output indicating the progress of uninstallation operations.
## NOTES
- Requires the specified environment configuration file to exist in the DevSetup environments directory
- Uses Get-DevSetupEnvPath to locate the environments directory
- Validates YAML file existence before attempting to parse configuration
- Processes uninstallation in specific order:
  1. PowerShell modules via Uninstall-PowershellModules
  2. Chocolatey packages via Uninstall-ChocolateyPackages  
  3. Scoop packages via Uninstall-ScoopComponents
- Each uninstaller function handles its own error reporting and validation
- Does not remove the YAML configuration file itself after uninstallation
- Provides descriptive error messages for missing or invalid configuration files
- Status variables are assigned but not currently used for flow control

## RELATED LINKS
