Function Get-ScoopComponentsInstalled {
    [CmdletBinding()]
    [OutputType([hashtable])]
    Param()
    
    try {
        if(-Not (Test-ScoopInstalled)) {
            Write-StatusMessage "Scoop is not installed. Cannot check for installed components." -Verbosity "Warning"
            return $null
        }
    } catch {
        Write-StatusMessage "Could not get installed Scoop components: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }  
    
    try {
        $scoopCommand = Find-Scoop
        if (-not $scoopCommand) {
            Write-StatusMessage "Failed to find Scoop command. Cannot check for installed components." -Verbosity "Warning"
            return $null
        }
    } catch {
        Write-StatusMessage "Error finding Scoop command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $scoopListResults = Invoke-Command -ScriptBlock {& $scoopCommand export }
        if ($LASTEXITCODE -ne 0 -or -not $scoopListResults) {
            Write-StatusMessage "No Scoop components found or scoop list command failed." -Verbosity Warning
            return $null
        }
    } catch {
        Write-StatusMessage "Could not execute 'scoop export': $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $scoopComponentsList = $scoopListResults | ConvertFrom-Json
    } catch {
        Write-StatusMessage "Could not parse 'scoop export' output: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    return $scoopComponentsList
}