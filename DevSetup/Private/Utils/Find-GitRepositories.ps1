Function Find-GitRepository {
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0,
            HelpMessage = "The top level path to search"
        )]
        [ValidateScript({
            if (Test-Path $_) {
                $True
            }
            else {
                Throw "Cannot validate path $_"
            }
        })]    
        [string]$Path = "."
    )

    Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"
    Write-Verbose "[PROCESS] Searching $(Convert-Path -path $path) for Git repositories"

    # Define directories to exclude from search (just the folder names)
    $ExcludeFolders = @('Windows', 'Program Files', 'Program Files (x86)', '$RECYCLE.BIN')
    
    Write-Verbose "[PROCESS] Excluding system folders: $($ExcludeFolders -join ', ')"

    # Use a more efficient search strategy
    function Search-GitRepo {
        param([string]$SearchPath, [string[]]$ExcludeFolders)
        
        try {
            # Get all directories first, excluding system folders at the top level
            $directories = Get-ChildItem -Path $SearchPath -Directory -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -notin $ExcludeFolders }
            
            foreach ($dir in $directories) {
                # Check if this directory IS a git repo
                $gitDir = Join-Path $dir.FullName ".git"
                if (Test-Path $gitDir) {
                    # Found a git repo, yield it
                    Get-Item $gitDir -Force -ErrorAction SilentlyContinue
                }
                
                # Recursively search subdirectories (but don't exclude here since we're deeper)
                Search-GitRepos -SearchPath $dir.FullName -ExcludeFolders @()
            }
        }
        catch {
            # Silently continue on errors
        }
    }

    # Collect all repositories in an array
    $repositories = @()
    
    Search-GitRepos -SearchPath $Path -ExcludeFolders $ExcludeFolders |
        ForEach-Object {
            $gitItem = $_
            $repoPath = Split-Path $gitItem.FullName -Parent
            Write-Verbose "Found repository at: $repoPath"
            
            # Get the branch information
            $branchName = "unknown"
            $remoteUrl = "none"
            if ($repoPath -and (Test-Path $repoPath)) {
                $originalLocation = Get-Location
                try {
                    Write-Verbose "Changing to repository: $repoPath"
                    Set-Location -Path $repoPath
                    
                    # Get current branch
                    $branchOutput = & git rev-parse --abbrev-ref HEAD 2>$null
                    if ($LASTEXITCODE -eq 0 -and $branchOutput) { 
                        $branchName = $branchOutput.Trim()
                    }
                    
                    # Get remote origin URL
                    $remoteOutput = & git remote get-url origin 2>$null
                    if ($LASTEXITCODE -eq 0 -and $remoteOutput) {
                        $remoteUrl = $remoteOutput.Trim()
                    }
                }
                catch {
                    Write-Verbose "Branch/Remote detection error for $repoPath`: $_"
                    $branchName = "error"
                    $remoteUrl = "error"
                }
                finally {
                    Set-Location -Path $originalLocation
                }
            } else {
                Write-Verbose "Invalid repository path: '$repoPath'"
                $branchName = "invalid-path"
                $remoteUrl = "invalid-path"
            }
            
            # Add to repositories collection
            $repositories += [PSCustomObject]@{
                Repository = $repoPath
                Branch = $branchName
                RemoteUrl = $remoteUrl
            }
        }
    
    # Output formatted table
    if ($repositories.Count -gt 0) {
        Write-Host "`nFound $($repositories.Count) Git repositories:" -ForegroundColor Green
        Write-Host "=" * 80 -ForegroundColor Gray
        
        $repositories | Sort-Object Repository | Format-Table -AutoSize -Wrap @(
            @{Label="Repository"; Expression={$_.Repository}; Width=40},
            @{Label="Branch"; Expression={$_.Branch}; Width=20},
            @{Label="Remote URL"; Expression={$_.RemoteUrl}; Width=50}
        )
    } else {
        Write-Host "No Git repositories found in the specified path." -ForegroundColor Yellow
    }

    Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"

} #end function