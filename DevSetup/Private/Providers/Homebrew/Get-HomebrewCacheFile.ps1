Function Get-HomebrewCacheFile {
    [CmdletBinding()]
    Param()

    $CacheFile = Join-Path -Path (Get-DevSetupCachePath) -ChildPath "homebrew.cache"
    return $CacheFile
}