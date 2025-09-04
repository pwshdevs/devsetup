Function Get-DevSetupVersion {
    <#
    .SYNOPSIS
    Retrieves the version of the DevSetup module.

    .DESCRIPTION
    Get-DevSetupVersion returns the current version of the DevSetup module either from the locally installed version or from the latest GitHub release.

    .PARAMETER Local
    Retrieves the version from the locally installed DevSetup module. This is the default behavior if no parameter is specified.

    .PARAMETER Remote
    Retrieves the latest version from the GitHub repository using the latest release tag.

    .OUTPUTS
    System.Version. Returns the version object of the DevSetup module.

    .EXAMPLE
    Get-DevSetupVersion
    Returns the version object of the locally installed DevSetup module.

    .EXAMPLE
    Get-DevSetupVersion -Local
    Returns the version object of the locally installed DevSetup module.
    
    .EXAMPLE
    Get-DevSetupVersion -Remote
    Returns the version object of the latest release from the GitHub repository.
    
    .EXAMPLE
    $version = Get-DevSetupVersion -Local
    Write-Host "Major: $($version.Major), Minor: $($version.Minor), Build: $($version.Build)"
    Gets the local version and displays individual components.
    
    .NOTES
    This function is used to check the installed version of the DevSetup module and returns a Version object for easy comparison and component access.
    The Local and Remote parameters are mutually exclusive. If neither is specified, Local is used by default.
    #>
    
    Param(
        [Parameter(Mandatory = $false)]
        [switch]$Local,
        
        [Parameter(Mandatory = $false)]
        [switch]$Remote
    )

    # Validate that only one parameter is specified
    if ($Local -and $Remote) {
        Write-Error "Local and Remote parameters are mutually exclusive. Please specify only one."
        return $null
    }

    # Default to Local if no parameter is specified
    if (-not $Local -and -not $Remote) {
        $Local = $true
    }

    $manifest = Get-DevSetupManifest
    if (-not $manifest) {
        Write-Error "Failed to retrieve DevSetup module manifest."
        return $null
    }

    if ($Local) {
        if (-not $manifest.ModuleVersion) {
            Write-Error "Version information not found in the DevSetup module manifest."
            return $null
        }
        try {
            $versionObject = [Version]::new($manifest.ModuleVersion)
            return $versionObject
        }
        catch {
            Write-Error "Failed to parse version '$($manifest.ModuleVersion)' as a valid version object: $_"
            return $null
        }
    }

    if ($Remote) {
        try {
            $projectUri = $manifest.PrivateData.PSData.ProjectUri
            if (-not $projectUri) {
                Write-Error "ProjectUri not found in the DevSetup module manifest."
                return $null
            }
            
            $release = (Get-GitHubRelease -Uri $projectUri | Select-Object -First 1)
            if (-not $release -or -not $release.tag_name) {
                Write-Error "Failed to retrieve latest release information from GitHub."
                return $null
            }
            
            # Remove 'v' prefix if present in tag name
            Write-Host $release.tag_name
            $versionString = $release.tag_name -replace '^v', ''
            $versionObject = [Version]::new($versionString)
            return $versionObject
        }
        catch {
            Write-Error "Failed to retrieve or parse remote version: $_"
            return $null
        }
    }
}