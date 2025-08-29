---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-ChocolateyPackage

## SYNOPSIS
Installs a Chocolatey package with optional version and parameter specification.

## SYNTAX

```
Install-ChocolateyPackage [-PackageName] <String> [[-Version] <String>] [[-Param] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function installs a Chocolatey package using the 'choco install' command with comprehensive
validation and conflict resolution.
It checks for existing installations, handles version conflicts
by reinstalling when necessary, and validates administrator privileges before proceeding.
The function
supports custom installation parameters and provides detailed error handling throughout the process.

## EXAMPLES

### EXAMPLE 1
```
Install-ChocolateyPackage -PackageName "git"
```

Installs the latest version of git package.

### EXAMPLE 2
```
Install-ChocolateyPackage -PackageName "nodejs" -Version "18.17.0"
```

Installs a specific version of nodejs package.

### EXAMPLE 3
```
Install-ChocolateyPackage -PackageName "googlechrome" -Param "/nogoogle"
```

Installs Google Chrome with custom installation parameters.

### EXAMPLE 4
```
$result = Install-ChocolateyPackage -PackageName "vscode" -Version "1.75.0" -Param "/silent"
if ($result) {
    Write-Host "Visual Studio Code installed successfully"
} else {
    Write-Host "Failed to install Visual Studio Code"
}
```

Demonstrates capturing the return value and using custom parameters.

## PARAMETERS

### -PackageName
The name of the Chocolatey package to install.
This parameter is mandatory and must be a valid, non-empty string representing a Chocolatey package name.

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

### -Version
The specific version of the package to install.
Optional parameter that specifies the exact version required.
If not provided, the latest version is installed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Param
Custom installation parameters to pass to the Chocolatey package.
Optional parameter that allows passing package-specific installation arguments using the --params flag.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
### Returns $true if the package was successfully installed or already meets requirements.
### Returns $false if the installation failed or insufficient privileges.
## NOTES
- Requires administrator privileges to install packages
- Uses Test-RunningAsAdmin to validate privileges before proceeding
- Uses Test-ChocolateyPackageInstalled to check existing installations
- Automatically uninstalls existing packages when version conflicts exist
- Uses comprehensive logic to determine installation necessity:
  * Returns immediately if package with correct version exists
  * Uninstalls and reinstalls if package exists but version differs
  * Installs directly if package doesn't exist
- Uses $LASTEXITCODE to verify command execution success
- Includes comprehensive try-catch error handling with descriptive error messages
- Provides detailed debug logging for troubleshooting installation issues
- Suppresses command output using Out-Null to avoid console clutter

## RELATED LINKS
