<#
.SYNOPSIS
    Writes current Scoop package information to the DevSetup cache file.

.DESCRIPTION
    This function exports the current Scoop package installation data and writes it to the DevSetup
    cache file for performance optimization and offline reference. It validates Scoop installation,
    locates the Scoop command, and uses 'scoop export' to generate package data before saving it
    to the cache file. The function provides comprehensive error handling and validation throughout
    the process.

.OUTPUTS
    [System.Boolean]
    Returns $true if the cache file is successfully written.
    Returns $false if Scoop is not installed, cannot be found, or the write operation fails.

.EXAMPLE
    Write-ScoopCache
    
    Exports current Scoop packages and writes them to the cache file.

.EXAMPLE
    if (Write-ScoopCache) {
        Write-Host "Scoop cache updated successfully"
    } else {
        Write-Host "Failed to update Scoop cache"
    }
    
    Demonstrates checking the return value to verify cache update success.

.EXAMPLE
    $cacheUpdated = Write-ScoopCache
    if ($cacheUpdated) {
        $cachedData = Read-ScoopCache
    }
    
    Shows writing cache data and then reading it back for use.

.NOTES
    - Requires Scoop to be installed on the system
    - Uses Test-ScoopInstalled to validate Scoop availability
    - Uses Find-Scoop to locate the Scoop command executable
    - Executes 'scoop export' to generate current package data
    - Uses Get-ScoopCacheFile to determine the cache file location
    - Overwrites existing cache file using -Force flag
    - Provides debug logging for successful cache operations
    - Returns $false immediately if Scoop is not available
    - Includes comprehensive try-catch error handling for file operations

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Cache Management, Data Serialization, Performance Optimization
#>

Function Write-ScoopCache {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param()

    try {
        $CacheFilePath = Get-ScoopCacheFile
    } catch {
        Write-StatusMessage "Failed to get Scoop cache file path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        if(-Not (Test-ScoopInstalled)) {
            return $false
        }
    } catch {
        Write-StatusMessage "Failed to test if Scoop is installed: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    try {
        $scoopCommand = Find-Scoop
    } catch {
        Write-StatusMessage "Failed to find Scoop command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }

    if (-not $scoopCommand) {
        return $false
    }

    try {
        $exportData = Invoke-Command -ScriptBlock { & $scoopCommand export } 2>$null 3>$null 4>$null 5>$null 6>$null
        if ($LASTEXITCODE -ne 0 -or -not $exportData) {
            Write-StatusMessage "Failed to export Scoop package data" -Verbosity Error
            return $false
        }
    } catch {
        return $false
    }

    try {
        if ($PSCmdlet.ShouldProcess($CacheFilePath, "Write")) {
            Set-Content -Path $CacheFilePath -Value $exportData -Encoding UTF8 -Force
        } else {
            Write-StatusMessage "Skipping writing Scoop cache file due to ShouldProcess" -Verbosity Debug
            return $true
        }
    } catch {
        Write-StatusMessage "Failed to write Scoop cache file: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity  Error
        return $false
    }
    Write-StatusMessage "Scoop cache written successfully: $CacheFilePath" -Verbosity Debug
    return $true
}