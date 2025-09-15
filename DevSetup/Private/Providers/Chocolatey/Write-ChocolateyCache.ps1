<#
.SYNOPSIS
    Writes current Chocolatey package information to the DevSetup cache file.

.DESCRIPTION
    This function exports the current Chocolatey package installation data and writes it to the DevSetup
    cache file for performance optimization and offline reference. It validates Chocolatey installation,
    executes 'choco list -r' to generate machine-readable package data, and saves the output to the
    cache file. The function provides comprehensive error handling and validation throughout the process.

.OUTPUTS
    [System.Boolean]
    Returns $true if the cache file is successfully written.
    Returns $false if Chocolatey is not installed or the write operation fails.

.EXAMPLE
    Write-ChocolateyCache
    
    Exports current Chocolatey packages and writes them to the cache file.

.EXAMPLE
    if (Write-ChocolateyCache) {
        Write-Host "Chocolatey cache updated successfully"
    } else {
        Write-Host "Failed to update Chocolatey cache"
    }
    
    Demonstrates checking the return value to verify cache update success.

.EXAMPLE
    $cacheUpdated = Write-ChocolateyCache
    if ($cacheUpdated) {
        $cachedData = Read-ChocolateyCache
    }
    
    Shows writing cache data and then reading it back for use.

.NOTES
    - Requires Chocolatey to be installed on the system
    - Uses Test-ChocolateyInstalled to validate Chocolatey availability
    - Returns $false immediately if Chocolatey is not available
    - Executes 'choco list -r' to generate machine-readable package data with pipe-delimited format
    - Uses Get-ChocolateyCacheFile to determine the cache file location
    - Overwrites existing cache file using -Force flag
    - Provides debug logging for successful cache operations
    - Includes comprehensive try-catch error handling for command execution and file operations
    - Uses Set-Content for reliable file writing with proper encoding

.LINK

.COMPONENT
    DevSetup.Providers.Chocolatey

.FUNCTIONALITY
    Cache Management, Data Serialization, Performance Optimization
#>

Function Write-ChocolateyCache {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    Param()

    try {
        $cacheFile = Get-ChocolateyCacheFile
    } catch {
        Write-StatusMessage "Error determining Chocolatey cache file path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        if(-not (Test-ChocolateyInstalled)) {
            Write-StatusMessage "Chocolatey is not installed. Cannot write cache file." -Verbosity Error
            return $false
        }
    } catch {
        Write-StatusMessage "Error checking if Chocolatey is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $chocoCommand = Find-Chocolatey
    } catch {
        Write-StatusMessage "Error locating Chocolatey command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if(-not $chocoCommand -or [string]::IsNullOrWhiteSpace($chocoCommand)) {
        Write-StatusMessage "Could not find Chocolatey command. Cannot write cache file." -Verbosity Warning
        return $false
    }

    try {
        $chocoPackages = Invoke-Command -ScriptBlock { & $chocoCommand list -r } 2>$null 3>$null 4>$null 5>$null 6>$null
    }
    catch {
        Write-StatusMessage "Failed to write Chocolatey cache file: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
    
    Write-StatusMessage "Retrieved Chocolatey packages successfully." -Verbosity Debug
    if ($LASTEXITCODE -ne 0 -or -not $chocoPackages) {
        Write-StatusMessage "Failed to retrieve Chocolatey packages or no packages found." -Verbosity Warning
        return $false
    }    

    try {
        if ($PSCmdlet.ShouldProcess($cacheFile, "Update Chocolatey cache")) {
            $chocoPackages | Set-Content $cacheFile -Force
            Write-StatusMessage "Chocolatey cache written successfully to: $cacheFile" -Verbosity Debug            
            return $true
        } else {
            Write-StatusMessage "Operation to write Chocolatey cache was cancelled." -Verbosity Warning
            return $true
        }

    } catch {
        Write-StatusMessage "Failed to write Chocolatey cache file: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}