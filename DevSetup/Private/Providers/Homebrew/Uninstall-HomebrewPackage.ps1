Function Uninstall-HomebrewPackage {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    Param(
        [string]$PackageName
    )

    if ($PSCmdlet.ShouldProcess($PackageName, "brew uninstall")) {
        Write-StatusMessage "- Uninstalling Homebrew package '$PackageName'" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
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

        if(-not (Test-HomebrewPackageInstalled -PackageName $PackageName).HasFlag([InstalledState]::Installed)) {
            Write-StatusMessage "Homebrew package '$PackageName' is not installed." -Verbosity Verbose
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        }        
        # Uninstall Homebrew package
        $BrewArgs = @{
            Command = "bash"
            Arguments = @("-c", [string]::Format("{0} uninstall {1}", (Find-Homebrew), $PackageName))
        }
        (Invoke-ExternalCommand @BrewArgs) *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        } else {
            Write-StatusMessage "Failed to uninstall Homebrew package '$PackageName'." -Verbosity Verbose
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            return $false
        }
    }
}