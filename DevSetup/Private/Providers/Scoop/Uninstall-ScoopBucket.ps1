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
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    try {
        if(-Not (Test-ScoopInstalled)) {
            return $false
        }
    } catch {
        Write-StatusMessage "Scoop is not installed. $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $scoopCommand = Find-Scoop
        if (-not $scoopCommand) {
            return $false
        }
    } catch {
        Write-StatusMessage "Failed to find Scoop command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $bucketState = Test-ScoopComponentInstalled -Bucket -Name $Name
    } catch {
        Write-StatusMessage "Could not verify if Scoop bucket '$Name' is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if (-not ($bucketState.HasFlag([InstalledState]::Pass))) {
        # If a source is provided, add it to the command arguments
        Write-StatusMessage "Removing Scoop bucket: $Name without source" -Verbosity Debug

        # Execute the command to add the bucket
        try {
            if ($PSCmdlet.ShouldProcess($Name, "Uninstall Scoop bucket")) {
                Invoke-Command -ScriptBlock { & $scoopCommand bucket rm $Name } *> $null   
            } else {
                Write-StatusMessage "Skipping uninstalling Scoop bucket '$Name' due to ShouldProcess" -Verbosity Debug
                return $true
            }
            if ($LASTEXITCODE -ne 0) {
                return $false
            }
        } catch {
            Write-StatusMessage "Failed to uninstall Scoop bucket '$Name': $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false
        }

        try {
            if (-not (Write-ScoopCache -WhatIf:$PSCmdlet.WhatIf)) {
                return $false
            }    
        } catch {
            Write-StatusMessage "Error writing Scoop cache: $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return $false        
        }

        Write-StatusMessage "Scoop bucket '$Name' removed successfully."
        return $true
    } else {
        Write-StatusMessage "Scoop bucket '$Name' is already uninstalled."
        return $true
    }
}