Function Get-ScoopPackagesAvailable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    Param()
    
    try {
        if(-Not (Test-ScoopInstalled)) {
            Write-StatusMessage "Scoop is not installed. Cannot check for available packages." -Verbosity "Warning"
            return $null
        }
    } catch {
        Write-StatusMessage "Could not get available Scoop packages: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }  
    
    try {
        $scoopCommand = Find-Scoop
        if (-not $scoopCommand) {
            Write-StatusMessage "Failed to find Scoop command. Cannot check for available packages." -Verbosity "Warning"
            return $null
        }
    } catch {
        Write-StatusMessage "Error finding Scoop command: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    try {
        $scoopSearchResults = Invoke-Command -ScriptBlock {& $scoopCommand search }  6>$null | Out-String
        if ($LASTEXITCODE -ne 0 -or -not $scoopSearchResults) {
            Write-StatusMessage "No Scoop packages found or scoop search command failed." -Verbosity Warning
            return $null
        }
    } catch {
        Write-StatusMessage "Could not execute 'scoop search': $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    $scoopPackages = @{}

    try {
        $scoopSearchResults -Split "`n" | select-object -skip 4 | Foreach-Object {  
            $Parts = $_.Trim() -Split "\s+"; 
            $NewParts = @($Parts | Where-Object { 
                $_ -ne $null -and $_ -ne "" 
            }); 
            if($NewParts.Count -gt 0) { 
                $packageName = $NewParts[0]
                $packageVersion = if ($NewParts.Count -gt 1) { $NewParts[1] } else { $null }
                $packageSource = if ($NewParts.Count -gt 2) { $NewParts[2] } else { $null }
                
                $scoopPackages[$packageName] = @{ 
                    Name = $packageName
                    Version = $packageVersion
                    Source = $packageSource
                }
            }
        }
    } catch {
        Write-StatusMessage "Could not parse 'scoop search' output: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $null
    }

    return $scoopPackages

}