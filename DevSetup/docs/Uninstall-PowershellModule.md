---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Uninstall-PowershellModule

## SYNOPSIS
Uninstalls a PowerShell module from the system.

## SYNTAX

```
Uninstall-PowershellModule [-ModuleName] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function removes a PowerShell module from the system by first removing it from the current session
using Remove-Module, then uninstalling it completely using Uninstall-Module.
The function includes
validation to check if the module is installed before attempting removal, validates administrator 
privileges for AllUsers scope modules, and provides comprehensive error handling throughout the 
uninstallation process.

## EXAMPLES

### EXAMPLE 1
```
Uninstall-PowershellModule -ModuleName "posh-git"
```

Uninstalls the posh-git module from the system.

### EXAMPLE 2
```
$result = Uninstall-PowershellModule -ModuleName "PSReadLine"
if ($result) {
    Write-Host "PSReadLine module removed successfully"
} else {
    Write-Host "Failed to remove PSReadLine module"
}
```

Demonstrates capturing the return value to check uninstallation success.

### EXAMPLE 3
```
@("Module1", "Module2", "Module3") | ForEach-Object {
    Uninstall-PowershellModule -ModuleName $_
}
```

Shows bulk uninstallation of multiple modules.

## PARAMETERS

### -ModuleName
The name of the PowerShell module to uninstall.
This parameter is mandatory and must be a valid string representing an installed PowerShell module name.

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
### Returns $true if the module was successfully uninstalled or was not installed.
### Returns $false if the uninstallation failed or insufficient privileges for AllUsers modules.
## NOTES
- Uses Test-PowershellModuleInstalled to verify module existence before attempting removal
- Returns $true if module is not installed (considered successful since goal is achieved)
- Validates administrator privileges for AllUsers scope modules using Test-RunningAsAdmin
- Returns $false immediately if AllUsers module requires elevation but session is not elevated
- Performs two-step removal process:
  1. Remove-Module: Removes from current PowerShell session (with -Force flag)
  2. Uninstall-Module: Completely removes from system (with -Force flag)
- Uses -ErrorAction Stop for proper exception handling
- Includes comprehensive try-catch error handling with descriptive error messages
- Provides detailed debug logging for troubleshooting uninstallation issues
- Uses Write-Warning for non-critical issues (module not found, privilege issues)
- Uses Write-Error for actual uninstallation failures

## RELATED LINKS
