Function Get-HomebrewVersion {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
    )

    try {
        # Get Homebrew version
        if( -not (Test-HomebrewInstalled) ) {
            Write-StatusMessage "Homebrew is not installed" -Verbosity Verbose
            return $null
        }

        $HomebrewPath = Find-Homebrew
        if (-not $HomebrewPath) {
            Write-StatusMessage "Homebrew installation not found" -Verbosity Verbose
            return $null
        }

        $BrewArgs = @{
            Command = $HomebrewPath
            Arguments = @("--version")
        }

        $HomeBrewVersion = (Invoke-ExternalCommand @BrewArgs) -match "([0-9]+\.[0-9]+\.[0-9]+)"
        if ($HomeBrewVersion) {
            $version = $matches[1]
            return $version
        } else {
            return $null
        }
    } catch {
        Write-StatusMessage "Failed to get Homebrew version: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }
}