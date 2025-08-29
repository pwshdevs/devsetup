<#
.SYNOPSIS
    Clones or updates a Git repository to a specified local destination.

.DESCRIPTION
    This function clones a Git repository from a remote URL to a local destination path. It includes
    intelligent Git detection, handles existing repositories with update or replace options, supports
    branch specification, and provides comprehensive error handling. The function automatically detects
    Git installation in both PATH and common installation locations.

.PARAMETER RepositoryUrl
    The URL of the Git repository to clone.
    This parameter is mandatory and must be a valid, non-empty string representing a Git repository URL.

.PARAMETER DestinationPath
    The local path where the repository should be cloned.
    This parameter is mandatory and must be a valid, non-empty string representing a local directory path.

.PARAMETER Branch
    The specific branch to clone from the repository.
    Optional parameter that specifies which branch to clone. If not provided, the default branch is used.

.PARAMETER UpdateExisting
    Switch parameter that controls behavior when the destination path already exists.
    When specified, performs a git pull to update the existing repository instead of removing and re-cloning.

.OUTPUTS
    [System.Boolean]
    Returns $true if the repository was successfully cloned or updated.
    Returns $false if the operation failed or Git is not available.

.EXAMPLE
    Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo"
    
    Clones a repository to the specified path using the default branch.

.EXAMPLE
    Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo" -Branch "develop"
    
    Clones a specific branch of the repository.

.EXAMPLE
    Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo" -UpdateExisting
    
    Updates an existing repository instead of removing and re-cloning.

.EXAMPLE
    $success = Install-GitRepository -RepositoryUrl "https://github.com/user/repo.git" -DestinationPath "C:\Code\repo"
    if ($success) {
        Write-Host "Repository ready for use"
    } else {
        Write-Host "Failed to clone repository"
    }
    
    Demonstrates capturing the return value to check operation success.

.NOTES
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

.LINK

.COMPONENT
    DevSetup.Providers.Core

.FUNCTIONALITY
    Version Control, Repository Management, Git Operations
#>

Function Install-GitRepository {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryUrl,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Branch,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateExisting = $false
    )

    # Check if Git is installed
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        # Check common Git installation path
        $gitPath = "C:\Program Files\Git\cmd\git.exe"
        if (Test-Path $gitPath) {
            Write-Host "Using Git from: $gitPath" -ForegroundColor Gray
            # Use the full path for git commands
            $gitExecutable = $gitPath
        } else {
            Write-Error "Git is not installed or not found in PATH. Please install Git and try again."
            return $false
        }
    } else {
        $gitExecutable = "git"
        Write-Host "Git found in PATH" -ForegroundColor Gray
    }

    try {
        # Check if destination already exists
        if (Test-Path -Path $DestinationPath) {
            if ($UpdateExisting) {
                Write-Host "Updating existing repository at $DestinationPath" -ForegroundColor Yellow
                
                # Change to the repository directory and pull updates
                Push-Location $DestinationPath
                try {
                    & $gitExecutable pull
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Failed to update repository at $DestinationPath"
                        return $false
                    }
                    Write-Host "Repository updated successfully" -ForegroundColor Green
                    return $true
                }
                finally {
                    Pop-Location
                }
            } else {
                Write-Host "Removing existing directory to perform fresh clone: $DestinationPath" -ForegroundColor Yellow
                Remove-Item -Path $DestinationPath -Recurse -Force
            }
        }

        # Build git clone command
        $gitArgs = @("clone")
        
        # Add branch parameter only if specified
        if (-not [string]::IsNullOrWhiteSpace($Branch)) {
            $gitArgs += "--branch"
            $gitArgs += $Branch
            Write-Host "Cloning repository from $RepositoryUrl (branch: $Branch) to $DestinationPath" -ForegroundColor Cyan
        } else {
            Write-Host "Cloning repository from $RepositoryUrl (default branch) to $DestinationPath" -ForegroundColor Cyan
        }
        
        # Add repository URL and destination path
        $gitArgs += $RepositoryUrl
        $gitArgs += $DestinationPath
        
        # Execute git clone command
        & $gitExecutable @gitArgs
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to clone repository from $RepositoryUrl to $DestinationPath"
            return $false
        }
        
        Write-Host "Repository cloned successfully to $DestinationPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Error cloning repository: $_"
        return $false
    }
}