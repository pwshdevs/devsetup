---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-Scoop

## SYNOPSIS
Installs the Scoop package manager on the system.

## SYNTAX

```
Install-Scoop [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function installs Scoop package manager by downloading and executing the official installation script
from get.scoop.sh.
It automatically configures PowerShell execution policy settings and validates the
installation success.
The function performs pre-installation checks to avoid duplicate installations
and uses Get-ScoopVersion to verify successful installation completion.

## EXAMPLES

### EXAMPLE 1
```
Install-Scoop
```

Installs Scoop package manager on the current system.

### EXAMPLE 2
```
if (-not (Test-ScoopInstalled)) {
    Install-Scoop
    Write-Host "Scoop is now available for package management"
}
```

Shows conditional installation only when Scoop is not already present.

## PARAMETERS

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
### Returns $true if Scoop was successfully installed or was already installed.
### Returns $false if the installation verification fails.
## NOTES
**Installation Process:**
- Checks if Scoop is already installed using Test-ScoopInstalled
- Sets execution policy to RemoteSigned for script download
- Downloads and executes installation script from get.scoop.sh with -RunAs parameter
- Sets execution policy to Bypass after installation
- Verifies installation using Get-ScoopVersion

**Requirements:**
- Internet connection to download the installation script
- PowerShell execution policy modification permissions

**Installation Method:**
- Uses \`Invoke-RestMethod get.scoop.sh\` to download the installation script
- Executes with \`-RunAs\` parameter for non-elevated user installation from elevated PowerShell
- Automatically handles execution policy configuration (RemoteSigned → Bypass)

**Verification:**
- Uses Get-ScoopVersion to confirm successful installation
- Returns boolean based on version retrieval success
- Performs same verification check whether installing or if already installed

**Error Handling:**
- Throws exception if installation script execution fails
- Uses SilentlyContinue for execution policy to avoid errors
- Suppresses installation output using Out-Null for clean console experience

## RELATED LINKS
