---
external help file: DevSetup-help.xml
Module Name: DevSetup
online version:
schema: 2.0.0
---

# Install-GitRepository

## SYNOPSIS
Clones or updates a Git repository to a specified local destination.

## SYNTAX

```
Install-GitRepository [-RepositoryUrl] <String> [-DestinationPath] <String> [[-Branch] <String>]
 [-UpdateExisting] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
This function clones a Git repository from a remote URL to a local destination path.
It includes
intelligent Git detection, handles existing repositories with update or replace options, supports
branch specification, and provides comprehensive error handling.
The function automatically detects
Git installation in both PATH and common installation locations.

## EXAMPLES

### EXAMPLE 1
```
Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo"
```

Clones a repository to the specified path using the default branch.

### EXAMPLE 2
```
Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo" -Branch "develop"
```

Clones a specific branch of the repository.

### EXAMPLE 3
```
Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo" -UpdateExisting
```

Updates an existing repository instead of removing and re-cloning.

### EXAMPLE 4
```
$success = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo"
if ($success) {
    Write-Host "Repository ready for use"
} else {
    Write-Host "Failed to clone repository"
}
```

Demonstrates capturing the return value to check operation success.

## PARAMETERS

### -RepositoryUrl
The URL of the Git repository to clone.
This parameter is mandatory and must be a valid, non-empty string representing a Git repository URL.

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

### -DestinationPath
The local path where the repository should be cloned.
This parameter is mandatory and must be a valid, non-empty string representing a local directory path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Branch
The specific branch to clone from the repository.
Optional parameter that specifies which branch to clone.
If not provided, the default branch is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateExisting
Switch parameter that controls behavior when the destination path already exists.
When specified, performs a git pull to update the existing repository instead of removing and re-cloning.

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
### Returns $true if the repository was successfully cloned or updated.
### Returns $false if the operation failed or Git is not available.
## NOTES
- Requires Git to be installed on the system
- Automatically detects Git in PATH using Get-Command
- Falls back to common Git installation path: "C:\Program Files\Git\cmd\git.exe"
- Uses $LASTEXITCODE to verify Git command execution success
- Handles existing destinations in two ways:
  * UpdateExisting: Performs git pull to update existing repository
  * Default: Removes existing directory and performs fresh clone
- Uses Push-Location/Pop-Location for safe directory operations during updates
- Provides color-coded console output for different operation types
- Includes comprehensive try-catch error handling
- Uses parameter splatting for reliable Git command execution

## RELATED LINKS
