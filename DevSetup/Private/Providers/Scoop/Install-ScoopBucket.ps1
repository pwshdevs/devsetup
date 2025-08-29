<#
.SYNOPSIS
    Adds a Scoop bucket to the system.

.DESCRIPTION
    This function adds a specified Scoop bucket by executing the 'scoop bucket add' command.
    It includes validation to ensure Scoop is installed and available before attempting the bucket addition.
    The function supports adding both official buckets (by name only) and custom buckets (with source URL).
    It checks if the bucket is already installed before attempting to add it and provides error handling 
    with a boolean result indicating success or failure.

.PARAMETER Name
    The name of the Scoop bucket to add.
    This parameter is mandatory and must be a valid string representing a bucket name.

.PARAMETER Source
    The source URL or Git repository for the bucket.
    Optional parameter used for adding custom buckets. If not specified, Scoop will attempt to add an official bucket by name.

.OUTPUTS
    [System.Boolean]
    Returns $true if the bucket was successfully added or is already installed, $false if the operation failed.

.EXAMPLE
    Install-ScoopBucket -Name "extras"
    
    Adds the official 'extras' bucket to Scoop.

.EXAMPLE
    Install-ScoopBucket -Name "nonportable"
    
    Adds the official 'nonportable' bucket to Scoop.

.EXAMPLE
    Install-ScoopBucket -Name "custom-bucket" -Source "https://github.com/user/scoop-bucket"
    
    Adds a custom bucket from a GitHub repository.

.EXAMPLE
    $result = Install-ScoopBucket -Name "games"
    if ($result) {
        Write-Host "Games bucket added successfully"
    } else {
        Write-Host "Failed to add games bucket"
    }
    
    Demonstrates capturing the return value to check bucket addition success.

.NOTES
    - Requires Scoop to be installed on the system
    - Uses Test-ScoopComponentInstalled to check if bucket is already installed before attempting to add it
    - Returns $true if bucket is already installed (considered successful since goal is achieved)
    - Returns $false immediately if Scoop is not installed or cannot be found
    - Uses $LASTEXITCODE to verify command execution success
    - Provides warning messages for common failure scenarios
    - Uses try-catch error handling for robust failure management
    - Official buckets can be added by name only (extras, nonportable, games, etc.)
    - Custom buckets require both name and source URL parameters
    - Suppresses command output using Out-Null to avoid console clutter

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Bucket Management, Repository Addition
#>
Function Install-ScoopBucket {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [string]$Source
    )

    if(-Not (Test-ScoopInstalled)) {
        return $false
    }

    $scoopCommand = Find-Scoop
    if (-Not ($scoopCommand)) {
        return $false
    }

    try {
        [InstalledState]$bucketState = Test-ScoopComponentInstalled -Bucket -Name $Name
        if ($bucketState -ne [InstalledState]::Pass) {
            $installArgs = @("bucket", "add", $Name)
            
            # If a source is provided, add it to the command arguments
            if ($Source) {
                $installArgs += $Source
            }

            # Execute the command to add the bucket
            $command = {
                & $scoopCommand @installArgs *> $null
            }
            Invoke-Command -ScriptBlock $command | Out-Null
            if ($LASTEXITCODE -ne 0) {
                return $false
            }

            if (-not (Write-ScoopCache)) {
                return $false
            }            
            
            return $true
        } else {
            return $true
        }        
    } catch {
        return $false
    }
}