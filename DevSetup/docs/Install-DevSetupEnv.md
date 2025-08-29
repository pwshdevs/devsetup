---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-DevSetupEnv

## SYNOPSIS
Installs a complete development environment from a YAML configuration file.

## SYNTAX

### Install
```
Install-DevSetupEnv [-Name] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### InstallPath
```
Install-DevSetupEnv [-Path] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### InstallUrl
```
Install-DevSetupEnv [-Url] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function orchestrates the installation of a development environment by reading a YAML configuration file
and processing all defined dependencies and commands.
It sequentially installs PowerShell modules, Chocolatey
packages, Scoop buckets and packages, then executes any custom commands specified in the configuration.
The function provides comprehensive error handling and progress reporting throughout the installation process.

## EXAMPLES

### EXAMPLE 1
```
Install-DevSetupEnv -Name "development"
```

Installs the development environment from the "development.yaml" configuration file.

### EXAMPLE 2
```
Install-DevSetupEnv "web-dev"
```

Installs the web development environment using positional parameter syntax.

### EXAMPLE 3
```
Install-DevSetupEnv -Name "my-environment"
```

Demonstrates the PSCustomObject structure that would be parsed from the YAML file.

## PARAMETERS

### -Name
The name of the environment configuration file to install (without the .yaml extension).
The function will look for a file named "{Name}.yaml" in the DevSetup environment path.
This parameter is mandatory and accepts positional input.

```yaml
Type: String
Parameter Sets: Install
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
{{ Fill Path Description }}

```yaml
Type: String
Parameter Sets: InstallPath
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Url
{{ Fill Url Description }}

```yaml
Type: String
Parameter Sets: InstallUrl
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

### None. This function does not return a value but writes status information to the console.
## NOTES
- Requires the environment YAML file to exist in the DevSetup environment path
- Uses Get-DevSetupEnvPath to determine the configuration file location
- Returns early with error if YAML file is not found or cannot be parsed
- Processes dependencies in a specific order: PowerShell modules, Chocolatey packages, then Scoop components
- Commands are executed after all package installations are complete
- Individual installation failures do not stop the overall process
- Uses Read-ConfigurationFile to parse YAML configuration
- Leverages Install-PowershellModules, Install-ChocolateyPackages, and Install-ScoopComponents functions
- Custom commands are executed using Invoke-CommandFromEnv function
- Provides detailed console output with color-coded status messages
- Skips command entries that are missing the required command property
- Command execution includes package name context for better traceability

## RELATED LINKS
