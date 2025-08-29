<#
.SYNOPSIS
    Uninstalls a Scoop bucket from the system.

.DESCRIPTION
    This function removes a Scoop bucket using the 'scoop bucket rm' command. It validates
    Scoop installation, locates the Scoop command, and checks if the bucket is currently
    installed before attempting removal. The function provides comprehensive error handling
    and updates the Scoop cache after successful removal operations.

.PARAMETER Name
    The name of the Scoop bucket to uninstall.
    This parameter is mandatory and must be a valid, non-empty string representing an installed Scoop bucket name.

.OUTPUTS
    [System.Boolean]
    Returns $true if the bucket is successfully uninstalled or already uninstalled.
    Returns $false if the uninstallation fails or Scoop is not available.

.EXAMPLE
    Uninstall-ScoopBucket -Name "extras"
    
    Uninstalls the "extras" bucket from Scoop.

.EXAMPLE
    $result = Uninstall-ScoopBucket -Name "java"
    if ($result) {
        Write-Host "Java bucket removed successfully"
    } else {
        Write-Host "Failed to remove Java bucket"
    }
    
    Demonstrates capturing the return value to check uninstallation success.

.EXAMPLE
    @("extras", "versions", "java") | ForEach-Object {
        Uninstall-ScoopBucket -Name $_
    }
    
    Shows bulk uninstallation of multiple Scoop buckets.

.NOTES
    - Requires Scoop to be installed on the system
    - Uses Test-ScoopInstalled to validate Scoop availability
    - Uses Find-Scoop to locate the Scoop command executable
    - Returns $false immediately if Scoop is not available or cannot be found
    - Uses Test-ScoopComponentInstalled to check if bucket is currently installed
    - Returns $true if bucket is already uninstalled (idempotent behavior)
    - Executes 'scoop bucket rm' command with output suppression
    - Uses $LASTEXITCODE to verify command execution success
    - Updates Scoop cache using Write-ScoopCache after successful removal
    - Provides debug logging for successful and skipped operations
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Suppresses all command output using *> $null to avoid console clutter

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Package Management, Bucket Management, Repository Removal
#>

Function Uninstall-ScoopBucket {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    if(-Not (Test-ScoopInstalled)) {
        return $false
    }

    $scoopCommand = Find-Scoop
    if (-not $scoopCommand) {
        return $false
    }

    try {
        $bucketState = Test-ScoopComponentInstalled -Bucket -Name $Name
        if (-not ($bucketState.HasFlag([InstalledState]::Pass))) {
            # If a source is provided, add it to the command arguments
            Write-Debug "Removing Scoop bucket: $Name without source"

            # Execute the command to add the bucket
            Invoke-Expression "& $scoopCommand bucket rm $Name" *> $null
            if ($LASTEXITCODE -ne 0) {
                return $false
            }

            if (-not (Write-ScoopCache)) {
                return $false
            }            
            
            Write-Debug "Scoop bucket '$Name' removed successfully."
            return $true
        } else {
            Write-Debug "Scoop bucket '$Name' is already uninstalled."
            return $true
        }        
    } catch {
        return $false
    }
}