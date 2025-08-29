---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-ChocolateyPackage

## SYNOPSIS
Uninstalls a Chocolatey package and its dependencies from the system.

## SYNTAX

```
Uninstall-ChocolateyPackage [-PackageName] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function removes a Chocolatey package from the system using the 'choco uninstall' command.
It validates administrator privileges before proceeding, handles package dependencies by uninstalling
them first, and removes all versions of the specified package including metapackages.
The function
provides comprehensive error handling and uses exit codes to verify successful uninstallation.

## EXAMPLES

### EXAMPLE 1
```
Uninstall-ChocolateyPackage -PackageName "git"
```

Uninstalls the git package and any dependent packages from the system.

### EXAMPLE 2
```
$result = Uninstall-ChocolateyPackage -PackageName "nodejs"
if ($result) {
    Write-Host "Node.js and dependencies removed successfully"
} else {
    Write-Host "Failed to remove Node.js"
}
```

Demonstrates capturing the return value to check uninstallation success.

### EXAMPLE 3
```
@("git", "nodejs", "vscode") | ForEach-Object {
    Uninstall-ChocolateyPackage -PackageName $_
}
```

Shows bulk uninstallation of multiple packages with dependency handling.

## PARAMETERS

### -PackageName
The name of the Chocolatey package to uninstall.
This parameter is mandatory and must be a valid, non-empty string representing an installed Chocolatey package name.

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

### [System.Boolean]
### Returns $true if the package and all dependencies were successfully uninstalled.
### Returns $false if the uninstallation failed or insufficient privileges.
## NOTES
- Requires administrator privileges to uninstall packages
- Uses Test-RunningAsAdmin to validate privileges before proceeding
- Throws an exception if not running as administrator
- Handles package dependencies by uninstalling them first using Get-ChocolateyPackageDependencies
- Uses recursive calls to uninstall dependency packages before the main package
- Automatically handles metapackages (packages ending with .install)
- Uses 'choco uninstall' with -y flag for automatic confirmation
- Uses --all-versions flag to remove all installed versions of the package
- Uses $LASTEXITCODE to verify command execution success
- Suppresses command output using Out-Null to avoid console clutter
- Includes comprehensive try-catch error handling with descriptive error messages
- Provides detailed debug logging for troubleshooting uninstallation issues
- Checks for and removes associated .install metapackages after main package removal

## RELATED LINKS
