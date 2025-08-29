---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-PowershellModule

## SYNOPSIS
Installs a PowerShell module with specified parameters and scope validation.

## SYNTAX

```
Install-PowershellModule [-ModuleName] <String> [[-Version] <String>] [-Force] [-AllowClobber]
 [[-Scope] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Installs a PowerShell module using \`Install-Module\` with comprehensive validation and scope management.
Checks for existing installations and handles version/scope conflicts by intelligently uninstalling and reinstalling as needed.
Supports both \`CurrentUser\` and \`AllUsers\` scopes, with privilege validation for \`AllUsers\`.

## EXAMPLES

### EXAMPLE 1
```
Install-PowershellModule -ModuleName "posh-git"
# Installs the latest version of posh-git module for the current user.
```

### EXAMPLE 2
```
Install-PowershellModule -ModuleName "PSReadLine" -Version "2.2.6"
# Installs a specific version of PSReadLine module for the current user.
```

### EXAMPLE 3
```
Install-PowershellModule -ModuleName "PowerShellGet" -Scope "AllUsers" -Force
# Installs PowerShellGet module for all users with force flag (requires administrator privileges).
```

### EXAMPLE 4
```
Install-PowershellModule -ModuleName "Az" -AllowClobber -Scope "CurrentUser"
# Installs the Az module allowing cmdlet name conflicts for the current user.
```

## PARAMETERS

### -ModuleName
The name of the PowerShell module to install.
Mandatory and must be a valid, non-empty string.

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
The specific version of the module to install.
Optional; installs the latest version if not provided.

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

### -Force
Switch to force installation even if the module already exists.
Optional; passes the \`-Force\` flag to \`Install-Module\`.

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

### -AllowClobber
Switch to allow installation of modules that contain cmdlets with the same names as existing cmdlets.
Optional; passes the \`-AllowClobber\` flag to \`Install-Module\`.

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

### -Scope
The installation scope for the module.
Optional; valid values are \`'CurrentUser'\` or \`'AllUsers'\`.
Defaults to \`'CurrentUser'\`.
\`AllUsers\` scope requires administrator privileges.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: CurrentUser
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

### `[System.Boolean]`
### Returns `$true` if the module was successfully installed or already meets requirements.
### Returns `$false` if the installation failed.
## NOTES
**Scope Requirements:**
- Administrator privileges required for \`AllUsers\` scope.
- Uses \`Test-PowershellModuleInstalled\` to check existing installations.

**Installation Logic:**
- Returns immediately if module with correct version and scope exists.
- Uninstalls and reinstalls if version matches but scope differs.
- Reinstalls in-place if scope matches but version differs.
- Uninstalls and reinstalls if both version and scope differ.

**Error Handling:**
- Uses try/catch for robust error handling.
- Returns \`$false\` on any failure.

**Parameter Splatting:**
- Uses parameter splatting for reliable \`Install-Module\` execution.

## RELATED LINKS
