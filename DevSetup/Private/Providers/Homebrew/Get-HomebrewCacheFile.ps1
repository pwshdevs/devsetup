Function Get-HomebrewCacheFile {
    [CmdletBinding()]
    Param()

    try {
    $CacheFile = Join-Path -Path (Get-DevSetupCachePath) -ChildPath "homebrew.cache"
    } catch {
        Write-StatusMessage "Failed to get Homebrew cache file path: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }
    return $CacheFile
}