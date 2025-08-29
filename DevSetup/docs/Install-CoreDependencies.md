---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-CoreDependencies

## SYNOPSIS
Installs core dependencies required for the DevSetup module to function properly.

## SYNTAX

```
Install-CoreDependencies [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function installs essential system dependencies and package managers required for DevSetup operations.
It sequentially installs NuGet PackageProvider, required PowerShell modules from the DevSetup manifest,
and platform-specific tools.
On Windows, it also installs Chocolatey, Git, and Scoop.
The function 
validates each installation step and fails fast if any critical component cannot be installed.
It also 
refreshes the PATH environment variable to ensure newly installed tools are immediately available.

## EXAMPLES

### EXAMPLE 1
```
Install-CoreDependencies
```

Installs all core dependencies required for DevSetup functionality.

### EXAMPLE 2
```
if (Install-CoreDependencies) {
    Write-Host "DevSetup is ready for use"
    # Proceed with environment setup
} else {
    Write-Host "Failed to install core dependencies"
    # Handle installation failure
}
```

Demonstrates conditional logic based on installation success.

### EXAMPLE 3
```
$coreReady = Install-CoreDependencies
if ($coreReady) {
    # Continue with package installations
    Install-ChocolateyPackages -YamlData $config
}
```

Shows using the function result to proceed with subsequent operations.

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
### Returns $true if all core dependencies are successfully installed.
### Returns $false if any critical installation fails.
## NOTES
- Cross-platform support with platform detection using $IsWindows, $IsLinux, $IsMacOS
- Sets up platform variables if not defined ($IsWindows = $true, others = $false by default)
- Installs dependencies in a specific order to ensure proper functionality:
  1. NuGet PackageProvider (all platforms)
  2. Required PowerShell modules from DevSetup manifest (all platforms)
  3. Windows-only components:
     - Chocolatey package manager
     - Git version control system via Chocolatey
     - Scoop package manager
- Uses fail-fast approach - stops immediately if any critical component fails
- Installs PowerShell modules with -Force, -AllowClobber, and CurrentUser scope
- Refreshes PATH environment variable after Git installation for immediate availability
- Gets required modules list from Get-DevSetupManifest
- Provides color-coded console output for installation progress
- Skips empty module names in the manifest gracefully
- Returns $true even if no required modules are found (considered success)
- Windows-specific installations are conditionally executed based on platform detection

## RELATED LINKS
