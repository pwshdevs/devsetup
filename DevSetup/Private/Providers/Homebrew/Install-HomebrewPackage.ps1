Function Install-HomebrewPackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="Install")]
        [Parameter(Mandatory=$true, Position=0, ParameterSetName="InstallMinimumVersion")]
        [string]$PackageName,
        [Parameter(Mandatory=$true, Position=1, ParameterSetName="InstallMinimumVersion")]
        [string]$MinimumVersion
    )

    if ($PSCmdlet.ShouldProcess($PackageName, "brew install")) {
        Write-StatusMessage "- Installing Homebrew package '$PackageName'" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline

        if(-not (Test-HasSudoAccess)) {
            Write-StatusMessage "Sudo Access is required to install Homebrew packages." -ForegroundColor Red -Verbosity Verbose
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            return $false
        }

        if (-not (Find-Homebrew)) {
            Write-StatusMessage "Homebrew is not installed. Please install Homebrew first." -ForegroundColor Red -Verbosity Verbose
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            return $false
        }

        if((Test-HomebrewPackageInstalled -PackageName $PackageName).HasFlag([InstalledState]::Pass)) {
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        }
        # Install Homebrew package
        $BrewArgs = @{
            Command   = (Find-Homebrew)
            Arguments = @("install", $PackageName)
        }
        Invoke-ExternalCommand @BrewArgs *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        } else {
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            return $false
        }
    }
}