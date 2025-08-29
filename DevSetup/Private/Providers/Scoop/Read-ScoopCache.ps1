<#
.SYNOPSIS
    Reads cached Scoop package information from the DevSetup cache file.

.DESCRIPTION
    This function reads and deserializes cached Scoop package data from the DevSetup cache system.
    It automatically handles cache file creation if the file doesn't exist by calling Write-ScoopCache,
    and provides comprehensive error handling for file operations and JSON parsing. The function
    returns the cached data as a PowerShell object for use by other Scoop-related functions.

.OUTPUTS
    [System.Object]
    Returns the deserialized cache data as a PowerShell object if successful.
    Returns $null if the cache file cannot be read or parsed.

.EXAMPLE
    Read-ScoopCache
    
    Reads the Scoop cache data and returns it as a PowerShell object.

.EXAMPLE
    $scoopCache = Read-ScoopCache
    if ($scoopCache) {
        Write-Host "Found $($scoopCache.Count) cached packages"
    } else {
        Write-Host "No cache data available"
    }
    
    Demonstrates reading cache data and checking for successful retrieval.

.EXAMPLE
    $cachedPackages = Read-ScoopCache
    $gitPackage = $cachedPackages | Where-Object { $_.name -eq "git" }
    
    Shows reading cache data and filtering for specific package information.

.NOTES
    - Uses Get-ScoopCacheFile to determine the cache file location
    - Automatically creates cache file if it doesn't exist using Write-ScoopCache
    - Throws an exception if cache file creation fails
    - Uses ConvertFrom-Json to deserialize the cached data
    - Provides comprehensive error handling for both file operations and JSON parsing
    - Returns $null on any error to allow calling functions to handle gracefully
    - Used by other Scoop functions to avoid repeated system queries for performance

.LINK

.COMPONENT
    DevSetup.Providers.Scoop

.FUNCTIONALITY
    Cache Management, Data Deserialization, Performance Optimization
#>

Function Read-ScoopCache {
    [CmdletBinding()]
    Param()

    $CacheFilePath = Get-ScoopCacheFile

    if (-Not (Test-Path $CacheFilePath)) {
        Write-Debug "Scoop cache file not found: $CacheFilePath"
        if (-not (Write-ScoopCache)) {
            throw "Failed to create Scoop cache file: $CacheFilePath"
        }
    }

    try {
        $cacheData = Get-Content $CacheFilePath | ConvertFrom-Json
        return $cacheData
    } catch {
        return $null
    }
}