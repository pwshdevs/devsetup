Function Read-HomebrewCache {
    [CmdletBinding()]
    [OutputType([hashtable])]
    Param()

    $cacheFile = Get-HomebrewCacheFile

    if (Test-Path $cacheFile) {
        $jsonData = Get-Content -Path $cacheFile | ConvertFrom-Json
        
        # Convert PSCustomObject to Hashtable for cross-platform compatibility
        $hashtable = @{}
        $jsonData.PSObject.Properties | ForEach-Object {
            $hashtable[$_.Name] = $_.Value
        }
        
        return $hashtable
    }

    return @{}
}