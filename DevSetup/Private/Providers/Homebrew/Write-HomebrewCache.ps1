Function Write-HomebrewCache {
    [CmdletBinding()]
    [OutputType([void])]
    Param()

    $cacheFile = Get-HomebrewCacheFile
    $cacheData = @{}

    try {
        if (Test-HomebrewInstalled) {
            $BrewArgs = @{
                Command = "bash"
                Arguments = @("-c", "$(Find-Homebrew) list --versions")
            }

            (Invoke-ExternalCommand @BrewArgs) | ForEach-Object {
                $parts = $_ -split ' '
                if ($parts.Length -ge 2) {
                    $packageName = $parts[0]
                    $packageVersion = $parts[1]
                    $cacheData[$packageName] = $packageVersion
                }
            } | Out-Null
            $cacheData | ConvertTo-Json | Set-Content -Path $cacheFile
        }
    } catch {
        Write-StatusMessage "Failed to write Homebrew cache: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
    }
}