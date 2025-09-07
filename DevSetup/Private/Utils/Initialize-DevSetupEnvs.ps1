Function Initialize-DevSetupEnv {
    try {
        # Define environments repository path
        $environmentsPath = Get-DevSetupEnvPath
        $localEnvironmentsPath = Get-DevSetupLocalEnvPath
        $communityEnvironmentsPath = Get-DevSetupCommunityEnvPath
        
        # Get the environments repository URL from the manifest
        $manifest = Get-DevSetupManifest
        if (-not $manifest) {
            Write-Error "Failed to retrieve DevSetup module manifest."
            return $null
        }
        
        $environmentsProjectUri = $manifest.PrivateData.PSData.EnvironmentsProjectUri
        if (-not $environmentsProjectUri) {
            Write-Error "EnvironmentsProjectUri not found in the DevSetup module manifest."
            return $null
        }
        
        # Check if the URI ends with .git, if not use Get-GitHubRepository to get clone_url
        if ($environmentsProjectUri -notlike "*.git") {
            try {
                Set-GitHubConfiguration -DisableTelemetry
                #Write-Host "GitHub API access is required to retrieve repository information." -ForegroundColor Yellow
                #Write-Host "Please create a GitHub Personal Access Token with 'repo' scope at:" -ForegroundColor Yellow
                #Write-Host "https://github.com/settings/tokens" -ForegroundColor Cyan
                #Write-Host ""
                
                # Prompt for GitHub access token with masked input
                #$secureToken = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
                #if (-not $secureToken -or $secureToken.Length -eq 0) {
                #    Write-Error "GitHub access token is required to continue."
                #    return $null
                #}

                #$cred = New-Object System.Management.Automation.PSCredential "token", $secureToken
                #Set-GitHubAuthentication -Credential $cred
                #$secureToken = $null # clear this out now that it's no longer needed
                #$cred = $null # clear this out now that it's no longer needed                
                $repository = Get-GitHubRepository -Uri $environmentsProjectUri 3>$null
                if (-not $repository -or -not $repository.clone_url) {
                    Write-Error "Failed to retrieve repository information or clone_url from GitHub."
                    return $null
                }
                $repositoryUrl = $repository.clone_url
            }
            catch {
                Write-Error "Failed to get repository information from GitHub: $_"
                return $null
            }
        } else {
            $repositoryUrl = $environmentsProjectUri
        }

        if(-not (Test-Path $environmentsPath)) {
            New-Item -Path $environmentsPath -Type Directory | Out-Null
        }

        if(-not (Test-Path $localEnvironmentsPath)) {
            New-Item -Path $localEnvironmentsPath -Type Directory | Out-Null
        }


        # Clone the environments repository if it doesn't exist
        if (-not (Test-Path -Path $communityEnvironmentsPath)) {
            Write-StatusMessage "- Cloning $repositoryUrl" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
            Install-GitRepository -RepositoryUrl $repositoryUrl -DestinationPath $communityEnvironmentsPath -UpdateExisting:$true *>$null
            if($LASTEXITCODE -ne 0) {
                Write-StatusMessage "[Failed]" -ForegroundColor Red
            } else {
                Write-StatusMessage "[OK]" -ForegroundColor Green
            }
        } else {
            Write-Verbose "Environments repository already exists at: $communityEnvironmentsPath"
        }
        
        Optimize-DevSetupEnvs | Out-Null

        # Return the path for use by other functions
        return @{
            Local = $localEnvironmentsPath
            Community = $communityEnvironmentsPath
        }
    }
    catch {
        Write-Error "Failed to initialize DevSetup environment: $_"
        return $null
    }    
}