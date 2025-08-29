---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Test-PowershellModuleInstalled

## SYNOPSIS
Tests whether a PowerShell module is installed, with optional version and scope validation.

## SYNTAX

### ModuleVersionAndScopeCheck
```
Test-PowershellModuleInstalled -ModuleName <String> -Version <String> -Scope <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ModuleScopeCheck
```
Test-PowershellModuleInstalled -ModuleName <String> -Scope <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ModuleVersionCheck
```
Test-PowershellModuleInstalled -ModuleName <String> -Version <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ModuleCheck
```
Test-PowershellModuleInstalled -ModuleName <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Checks if a PowerShell module is installed on the system and optionally validates
specific version requirements and installation scope.
Uses \`Get-Module -ListAvailable\`
to find installed modules and examines their installation paths to determine scope
(\`CurrentUser\` vs \`AllUsers\`).
Supports multiple parameter sets to check different
combinations of module existence, version matching, and scope validation.

## EXAMPLES

### EXAMPLE 1
```
Test-PowershellModuleInstalled -ModuleName "posh-git"
# Checks if the posh-git module is installed (any version, any scope).
```

### EXAMPLE 2
```
Test-PowershellModuleInstalled -ModuleName "PSReadLine" -Version "2.2.6"
# Checks if PSReadLine module version 2.2.6 is installed.
```

### EXAMPLE 3
```
Test-PowershellModuleInstalled -ModuleName "PowerShellGet" -Scope "AllUsers"
# Checks if PowerShellGet module is installed in AllUsers scope.
```

### EXAMPLE 4
```
Test-PowershellModuleInstalled -ModuleName "Az" -Version "9.0.1" -Scope "CurrentUser"
# Checks if Az module version 9.0.1 is installed in CurrentUser scope.
```

## PARAMETERS

### -ModuleName
The name of the PowerShell module to check.
Mandatory for all parameter sets.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The specific version of the module to validate.
Optional; only used in version-related parameter sets.

```yaml
Type: String
Parameter Sets: ModuleVersionAndScopeCheck, ModuleVersionCheck
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scope
The installation scope to validate (\`CurrentUser\` or \`AllUsers\`).
Optional; only used in scope-related parameter sets.

```yaml
Type: String
Parameter Sets: ModuleVersionAndScopeCheck, ModuleScopeCheck
Aliases:

Required: True
Position: Named
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

### `[InstalledState]`
### Returns an InstalledState enum value indicating installation status and version/scope match.
### Returns `[InstalledState]::NotInstalled` if not found or criteria are not met.
## NOTES
**Module Paths:**
- CurrentUser (PS5.1): \`$HOME\Documents\WindowsPowerShell\Modules\`
- CurrentUser (PS7+): \`$HOME\Documents\PowerShell\Modules\`
- AllUsers (PS5.1): \`$Env:ProgramFiles\WindowsPowerShell\Modules\`
- AllUsers (PS7+): \`$Env:ProgramFiles\PowerShell\Modules\`

**Parameter Sets:**
- \`ModuleCheck\`: Checks if module exists.
- \`ModuleVersionCheck\`: Checks existence and exact version match.
- \`ModuleScopeCheck\`: Checks existence and scope match.
- \`ModuleVersionAndScopeCheck\`: Checks existence, version, and scope match.

**Behavior:**
- Returns the highest version when multiple versions are installed.
- Uses \`\[InstalledState\]\` enum for detailed status.
- Includes error handling and debug logging.

## RELATED LINKS

[Get-Module]()

