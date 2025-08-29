---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-ScoopPackage

## SYNOPSIS
Installs a Scoop package on the system.

## SYNTAX

```
Install-ScoopPackage [-PackageName] <String> [[-Version] <String>] [[-Bucket] <String>] [-Global]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function installs a specified Scoop package by executing the 'scoop install' command.
It includes validation to ensure Scoop is installed and available before attempting the installation.
The function supports package versioning, bucket specification, and global installation scope.
If the package is already installed and the global scope matches, it will be uninstalled first to ensure a clean installation.
The function verifies successful installation using Test-ScoopComponentInstalled with version and scope validation.

## EXAMPLES

### EXAMPLE 1
```
Install-ScoopPackage -PackageName "git"
```

Installs the 'git' package from the main bucket.

### EXAMPLE 2
```
Install-ScoopPackage -PackageName "nodejs" -Version "18.17.0"
```

Installs a specific version of the 'nodejs' package.

### EXAMPLE 3
```
Install-ScoopPackage -PackageName "7zip" -Global
```

Installs the '7zip' package globally for all users.

### EXAMPLE 4
```
Install-ScoopPackage -PackageName "firefox" -Bucket "extras"
```

Installs the 'firefox' package from the 'extras' bucket.

### EXAMPLE 5
```
Install-ScoopPackage -PackageName "python" -Version "3.11.5" -Bucket "main" -Global
```

Installs a specific version of Python from the main bucket globally.

## PARAMETERS

### -PackageName
The name of the Scoop package to install.
This parameter is mandatory and must be a valid string representing a Scoop package.

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
Optional parameter that appends version specification to the package name (e.g., "package@1.2.3").

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

### -Bucket
The bucket name where the package is located.
Optional parameter that prepends bucket specification to the package name (e.g., "extras/package").

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

### -Global
Switch parameter to install the package globally.
When specified, adds the --global flag to the scoop install command.

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
### Returns $true if the package was successfully installed and verified, $false if the installation failed.
## NOTES
- Requires Scoop to be installed on the system
- Only uninstalls existing package if it's already installed AND global scope matches exactly
- Uses Test-ScoopComponentInstalled to verify installation success with version and scope validation
- Supports bucket/package@version syntax for package specification
- Returns $false immediately if Scoop is not installed or cannot be found
- Provides detailed warning and error messages for failure scenarios
- Uses proper argument splatting for reliable command execution
- Includes comprehensive try-catch error handling for robust failure management
- Installation verification checks name, version (if specified), and global scope (if specified)

## RELATED LINKS
