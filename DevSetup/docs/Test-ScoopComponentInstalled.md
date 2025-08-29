---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Test-ScoopComponentInstalled

## SYNOPSIS
Tests whether a Scoop package or bucket is installed on the system.

## SYNTAX

### PackageGlobalCheck
```
Test-ScoopComponentInstalled [-Package] -Name <String> [-Global] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### PackageVersionGlobalCheck
```
Test-ScoopComponentInstalled [-Package] -Name <String> -Version <String> [-Global]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### PackageVersionCheck
```
Test-ScoopComponentInstalled [-Package] -Name <String> -Version <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### PackageCheck
```
Test-ScoopComponentInstalled [-Package] -Name <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### BucketCheck
```
Test-ScoopComponentInstalled [-Bucket] -Name <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Checks if a specified Scoop package or bucket is installed by querying Scoop export data.
For packages, verifies installation status, version match, and global/local scope.
For buckets, verifies if the bucket is present in the Scoop configuration.

## EXAMPLES

### EXAMPLE 1
```
Test-ScoopComponentInstalled -Package -Name "git"
# Checks if the 'git' package is installed via Scoop.
```

### EXAMPLE 2
```
Test-ScoopComponentInstalled -Package -Name "nodejs" -Version "18.17.0"
# Checks if the 'nodejs' package version 18.17.0 is installed via Scoop.
```

### EXAMPLE 3
```
Test-ScoopComponentInstalled -Package -Name "7zip" -Global
# Checks if the '7zip' package is installed globally via Scoop.
```

### EXAMPLE 4
```
Test-ScoopComponentInstalled -Bucket -Name "extras"
# Checks if the 'extras' bucket is added to Scoop.
```

## PARAMETERS

### -Package
Indicates checking for a package installation.
Cannot be used with \`-Bucket\`.

```yaml
Type: SwitchParameter
Parameter Sets: PackageGlobalCheck, PackageVersionGlobalCheck, PackageVersionCheck, PackageCheck
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Bucket
Indicates checking for a bucket installation.
Cannot be used with \`-Package\`.

```yaml
Type: SwitchParameter
Parameter Sets: BucketCheck
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the package or bucket to check.
Required for all parameter sets.

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
The specific version to check for when validating package installation.
Optional for package checks; not applicable for bucket checks.

```yaml
Type: String
Parameter Sets: PackageVersionGlobalCheck, PackageVersionCheck
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Global
Specifies checking for global package installation.
Optional for package checks; not applicable for bucket checks.

```yaml
Type: SwitchParameter
Parameter Sets: PackageGlobalCheck, PackageVersionGlobalCheck
Aliases:

Required: True
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

### `[InstalledState]`
### Returns an InstalledState enum value indicating installation status and version match.
### Returns `[InstalledState]::NotInstalled` if not found or Scoop is unavailable.
## NOTES
**Requirements:**
- Scoop must be installed.
- Uses \`Read-ScoopCache\` for cached export data.

**Behavior:**
- Returns \`\[InstalledState\]::NotInstalled\` if Scoop is not installed.
- For packages, checks name, version, and global install status.
- For buckets, checks if the bucket name exists in the configuration.
- Returns an InstalledState enum value for detailed status.

**Error Handling:**
- Provides debug and warning messages for missing Scoop or cache data.
- Returns \`\[InstalledState\]::NotInstalled\` for missing components.

## RELATED LINKS
