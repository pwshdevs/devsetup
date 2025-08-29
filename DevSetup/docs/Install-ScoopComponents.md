---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-ScoopComponents

## SYNOPSIS
Installs Scoop buckets and packages from YAML configuration data.

## SYNTAX

```
Install-ScoopComponents [-YamlData] <PSObject> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function processes YAML configuration data to install Scoop buckets and packages in sequence.
It validates Scoop installation, updates the cache before proceeding, and processes buckets before
packages to ensure bucket availability.
The function supports both simple string formats and complex
object formats for buckets and packages, allowing for detailed configuration including versions,
custom sources, and global installation scope.
Progress is tracked and reported for both buckets
and packages using color-coded status messages.

## EXAMPLES

### EXAMPLE 1
```
$yamlData = Get-Content "config.yaml" | ConvertFrom-Yaml
Install-ScoopComponents -YamlData $yamlData
```

Installs Scoop buckets and packages from a YAML configuration file.

### EXAMPLE 2
```
$yamlData = @{
    devsetup = @{
        dependencies = @{
            scoop = @{
                buckets = @(
                    "extras",
                    @{
                        name = "custom-bucket"
                        source = "https://github.com/user/scoop-bucket"
                    }
                )
                packages = @(
                    "git",
                    @{
                        name = "nodejs"
                        version = "18.17.0"
                    },
                    @{
                        name = "7zip"
                        global = $true
                    },
                    @{
                        name = "firefox"
                        bucket = "extras"
                    }
                )
            }
        }
    }
}
Install-ScoopComponents -YamlData $yamlData
```

Demonstrates the PSCustomObject structure and installs the configured components.

### EXAMPLE 3
```
if (Install-ScoopComponents -YamlData $config) {
    Write-Host "Scoop components installation completed"
} else {
    Write-Host "Scoop components installation failed"
}
```

Shows checking the return value to verify installation completion.

## PARAMETERS

### -YamlData
The YAML configuration data containing Scoop bucket and package definitions.
This parameter is mandatory and must be a PSCustomObject with the structure:
devsetup.dependencies.scoop.buckets and/or devsetup.dependencies.scoop.packages

```yaml
Type: PSObject
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
### Returns $false if Scoop is not installed, cannot be found, configuration is invalid, or cache update fails.
### Returns $true if installation completes successfully (even if individual items fail).
## NOTES
- Requires Scoop to be installed on the system using Test-ScoopInstalled
- Returns $false immediately if Scoop is not installed or cannot be found
- Returns $false if YAML configuration structure is invalid or missing scoop section
- Updates Scoop cache using Write-ScoopCache before installation begins
- Returns $false if cache update fails to ensure accurate installation state
- Processes buckets before packages to ensure bucket availability for package installations
- Gracefully handles missing buckets or packages sections in configuration
- Supports two bucket specification formats:
  * Simple string: "bucketname"
  * Complex object: @{ name = "bucketname"; source = "https://github.com/user/scoop-bucket" }
- Supports two package specification formats:
  * Simple string: "packagename"
  * Complex object: @{ name = "packagename"; version = "1.0.0"; bucket = "extras"; global = $true }
- Validates component names and skips entries with missing names
- Uses Install-ScoopBucket and Install-ScoopPackage functions for actual installation
- Provides detailed progress reporting with component counts and property information
- Uses color-coded console output: Cyan for headers, Gray for items, Green/Red for status
- Displays formatted component information including version, bucket, and global flags
- Continues processing remaining components even if individual installations fail
- Returns $true for overall success even with individual component failures
- Includes comprehensive try-catch error handling with descriptive error messages
- Tracks and reports separate counts for buckets and packages processed

## RELATED LINKS
