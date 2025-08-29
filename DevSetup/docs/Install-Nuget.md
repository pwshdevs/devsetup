---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-Nuget

## SYNOPSIS
Installs the NuGet PackageProvider for PowerShell package management.

## SYNTAX

```
Install-Nuget [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function installs the NuGet PackageProvider which is required for PowerShell package management
operations.
It validates platform compatibility (Windows-only), administrator privileges, and existing
installations before proceeding.
The function also detects and reports on the availability of the
NuGet CLI tool if present on the system.

## EXAMPLES

### EXAMPLE 1
```
Install-Nuget
```

Installs the NuGet PackageProvider on the current system.

### EXAMPLE 2
```
if (Install-Nuget) {
    Write-Host "NuGet PackageProvider is ready for use"
    # Proceed with PowerShell module installations
} else {
    Write-Host "Failed to install NuGet PackageProvider"
    # Handle installation failure
}
```

Demonstrates conditional logic based on installation success.

### EXAMPLE 3
```
$nugetReady = Install-Nuget
if ($nugetReady) {
    Install-Module -Name SomeModule -Force
}
```

Shows using the function result to proceed with module operations.

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
### Returns $true if NuGet PackageProvider is successfully installed or already exists.
### Returns $false if the installation fails or system requirements are not met.
## NOTES
- Requires administrator privileges on Windows systems
- Uses Test-RunningAsAdmin to validate privileges before proceeding
- Throws an exception if not running as administrator
- Windows-only functionality - automatically skips installation on non-Windows platforms
- Installs minimum version 2.8.5.201 of the NuGet PackageProvider
- Uses CurrentUser scope for installation to minimize system impact
- Verifies successful installation by re-querying the PackageProvider
- Detects and reports NuGet CLI availability if present
- Uses -Force flag to bypass confirmation prompts
- Includes comprehensive try-catch error handling with descriptive error messages
- Returns $true for successful installation or if already installed (idempotent behavior)

## RELATED LINKS
