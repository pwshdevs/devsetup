---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-Chocolatey

## SYNOPSIS
Installs Chocolatey package manager on Windows systems.

## SYNTAX

```
Install-Chocolatey [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function installs the Chocolatey package manager by downloading and executing the official
installation script from the Chocolatey website.
It includes comprehensive validation for platform
compatibility, administrator privileges, and existing installations.
The function handles security
protocol configuration and execution policy adjustments required for the installation process.

## EXAMPLES

### EXAMPLE 1
```
Install-Chocolatey
```

Installs Chocolatey package manager on the current system.

### EXAMPLE 2
```
if (Install-Chocolatey) {
    Write-Host "Chocolatey is ready for use"
    # Proceed with package installations
} else {
    Write-Host "Failed to install Chocolatey"
    # Handle installation failure
}
```

Demonstrates conditional logic based on installation success.

### EXAMPLE 3
```
$chocoReady = Install-Chocolatey
if ($chocoReady) {
    choco install git -y
}
```

Shows using the function result to proceed with package operations.

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
### Returns $true if Chocolatey is successfully installed or already exists.
### Returns $false if the installation fails or system requirements are not met.
## NOTES
- Requires administrator privileges on Windows systems
- Uses Test-RunningAsAdmin to validate privileges before proceeding
- Automatically skips installation on non-Windows platforms (returns $true)
- Checks for existing Chocolatey installation before attempting download
- Sets execution policy to Bypass for the current process scope during installation
- Configures TLS 1.2 security protocol for secure download
- Downloads installation script from https://community.chocolatey.org/install.ps1
- Verifies successful installation by checking for 'choco' command availability
- Displays version information after successful installation
- Uses comprehensive try-catch error handling with descriptive error messages
- Suppresses command output using Out-Null to avoid console clutter
- Returns $true even if Chocolatey is already installed (idempotent behavior)

## RELATED LINKS
