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
    [CmdletBinding()]
    Param()

    $cacheFile = Get-ChocolateyCacheFile

    if(-not (Test-ChocolateyInstalled)) {
        Write-Error "Chocolatey is not installed. Cannot write cache file."
        return $false
    }

    try {
        #$chocolatelyPackages = @{}
        #choco list -r | foreach-object { 
        #    $package = $_ -split '\|' 
        #    if($package.Count -eq 2) {  
        #        $chocolatelyPackages[$package[0]] = @{
        #            Name = $package[0]
        #            Version = $package[1]
        #        }
        #    }
        #}        
        Invoke-Expression "& choco list -r" | Set-Content $cacheFile -Force
        Write-Debug "Chocolatey cache written successfully to: $cacheFile"
        return $true
    }
    catch {
        Write-Error "Failed to write Chocolatey cache file: $_"
        return $false
    }
}