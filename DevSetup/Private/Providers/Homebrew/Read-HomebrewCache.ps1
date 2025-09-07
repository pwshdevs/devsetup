Function Read-HomebrewCache {
    [CmdletBinding()]
    [OutputType([hashtable])]
    Param()

    $cacheFile = Get-HomebrewCacheFile

    if (Test-Path $cacheFile) {
        $cacheData = Get-Content -Path $cacheFile | ConvertFrom-Json -AsHashtable
        return $cacheData
    }

    return @{}
}