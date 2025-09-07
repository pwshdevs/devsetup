Function Install-Homebrew {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
    )

    try {
        Write-StatusMessage "- Checking for sudo access" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
        if ((Test-HasSudoAccess)) {
            Write-StatusMessage "[OK]" -ForegroundColor Green
        } else {
            Write-StatusMessage "[FAILED]" -ForegroundColor Red
            Write-StatusMessage "Sudo access is required to install Homebrew. Please run this script with a user that has sudo privileges." -Verbosity Warning
            return $false
        }

        # Install Homebrew
        Write-StatusMessage "- Installing Homebrew package manager" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
        if (-not (Find-Homebrew)) {
            # Installation command for Homebrew (Linux/Mac)
            $installCmd = 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            $BrewArgs = @{
                Command = "bash"
                Arguments = @("-c", "$installCmd")
            }
            Invoke-ExternalCommand @BrewArgs *> $null
            $HomebrewPath = Find-Homebrew
            if ([string]::IsNullOrEmpty($HomebrewPath)) {
                Write-StatusMessage "[FAILED]" -ForegroundColor Red
                return $false
            } else {
                Write-StatusMessage "[OK]" -ForegroundColor Green
                switch ((Get-EnvironmentVariable SHELL)) {
                    { $_ -like "*zsh*" } {
                        Write-StatusMessage "- Adding Homebrew path to $HOME/.zshrc" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
                        Add-Content -Path "$HOME/.zshrc" -Value ""
                        Add-Content -Path "$HOME/.zshrc" -Value ([string]::Format('eval "$({0} shellenv)"', $HomebrewPath))
                        Write-StatusMessage "[OK]" -ForegroundColor Green
                    }
                    { $_ -like "*bash*" } {
                        Write-StatusMessage "- Adding Homebrew path to $HOME/.bashrc" -ForegroundColor Gray -Indent 2 -Width 77 -NoNewline
                        Add-Content -Path "$HOME/.bashrc" -Value ""
                        Add-Content -Path "$HOME/.bashrc" -Value ([string]::Format('eval "$({0} shellenv)"', $HomebrewPath))
                        Write-StatusMessage "[OK]" -ForegroundColor Green
                    }
                    default {
                        Write-StatusMessage "Unknown shell: $($env:SHELL). You may need to manually add Homebrew to your PATH." -Verbosity Warning
                    }
                }

                return $true
            }
        } else {
            Write-StatusMessage "[OK]" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-StatusMessage "An error occurred while installing Homebrew: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return $false
    }
}