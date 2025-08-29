---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Use-DevSetup

## SYNOPSIS
Manages development environment configurations using the DevSetup module.

## SYNTAX

### InstallPath
```
Use-DevSetup [-Install] -Path <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### InstallUrl
```
Use-DevSetup [-Install] -Url <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Install
```
Use-DevSetup [-Install] -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Update
```
Use-DevSetup [-Update] -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Init
```
Use-DevSetup [-Init] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Export
```
Use-DevSetup [-Export] -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### List
```
Use-DevSetup [-List] [-Platform <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Uninstall
```
Use-DevSetup [-Uninstall] -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Use-DevSetup is the main function for managing development environments.
It provides actions to install, update, initialize, export, list, and uninstall development environment configurations.
The function supports multiple installation sources including local configurations by name, remote URLs, and local file paths.

Run 'Use-DevSetup -Init' first to set up the DevSetup environment and initialize the necessary directory structure and configuration files.

## EXAMPLES

### EXAMPLE 1
```
Use-DevSetup -Init
```

Initializes the DevSetup environment.
Run this first to set up the necessary directory structure and configuration files.

### EXAMPLE 2
```
Use-DevSetup -List
```

Lists development environment configurations for the current platform.

### EXAMPLE 3
```
Use-DevSetup -List -Platform "all"
```

Lists all available development environment configurations regardless of platform.

### EXAMPLE 4
```
Use-DevSetup -List -Platform "Linux"
```

Lists development environment configurations specifically for Linux.

### EXAMPLE 5
```
Use-DevSetup -Install -Name "WebDev"
```

Installs the development environment using the "WebDev" configuration from local configurations.

### EXAMPLE 6
```
Use-DevSetup -Install -Url "https://raw.githubusercontent.com/user/configs/main/webdev.devsetup"
```

Installs a development environment from a remote configuration file URL.

### EXAMPLE 7
```
Use-DevSetup -Install -Path "C:\Configs\MySetup.devsetup"
```

Installs a development environment from a local configuration file path.

### EXAMPLE 8
```
Use-DevSetup -Update -Name "WebDev"
```

Updates the existing "WebDev" development environment with any new packages or changes.

### EXAMPLE 9
```
Use-DevSetup -Export -Name "MyCurrentSetup"
```

Exports the current system's installed packages and tools to a new configuration file named "MyCurrentSetup".

### EXAMPLE 10
```
Use-DevSetup -Uninstall -Name "WebDev"
```

Uninstalls all packages and tools associated with the "WebDev" configuration.

## PARAMETERS

### -Install
Installs a development environment from a configuration file.
Can be used with Name, Url, or FilePath parameters.

```yaml
Type: SwitchParameter
Parameter Sets: InstallPath, InstallUrl, Install
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Update
Updates an existing development environment configuration.
Requires the Name parameter.

```yaml
Type: SwitchParameter
Parameter Sets: Update
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Init
Initializes the DevSetup environment and sets up the necessary directory structure and configuration files.
This should be run first before using other actions.

```yaml
Type: SwitchParameter
Parameter Sets: Init
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Export
Exports the current development environment to a configuration file.
Requires the Name parameter to specify the name for the exported configuration.

```yaml
Type: SwitchParameter
Parameter Sets: Export
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -List
Lists all available development environment configurations.

```yaml
Type: SwitchParameter
Parameter Sets: List
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uninstall
Uninstalls a development environment configuration.
Requires the Name parameter.

```yaml
Type: SwitchParameter
Parameter Sets: Uninstall
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the environment configuration to use.
Required for Install, Update, Export, and Uninstall actions when using local configurations.

```yaml
Type: String
Parameter Sets: Install, Update, Export, Uninstall
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Url
The URL of a remote configuration file to install.
Used with the Install action for remote installations.

```yaml
Type: String
Parameter Sets: InstallUrl
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
The local file path to a configuration file to install.
Used with the Install action for local file installations.

```yaml
Type: String
Parameter Sets: InstallPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Platform
The platform to filter environments by when using the List action.
Use "current" (default) to show environments for the current platform, "all" to show all environments, or specify a platform like "Windows", "Linux", "macOS".

```yaml
Type: String
Parameter Sets: List
Aliases:

Required: False
Position: Named
Default value: Current
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
### Returns $true if the action completes successfully, $false otherwise.
## NOTES
- Run 'Use-DevSetup -Init' first to initialize the DevSetup environment before using other actions
- Only one action can be specified at a time using parameter sets
- Supports three installation methods:
  * By Name: Uses local configuration files from the DevSetup directory
  * By URL: Downloads and installs from a remote configuration file
  * By Path: Installs from a local file path outside the DevSetup directory
- The function validates input and provides appropriate error messages for invalid combinations
- Displays formatted progress headers with color-coded output for better user experience
- Includes comprehensive try-catch error handling with descriptive error messages
- Update and Uninstall actions are marked as TODO and not yet implemented

## RELATED LINKS
