Function Start-DevSetupSelfUpdate {
    [CmdletBinding(DefaultParameterSetName="ReleaseInstall")]
    param(
        [Parameter(Mandatory=$true, ParameterSetName="MainWebInstall")]
        [switch]$Main,
        [Parameter(Mandatory=$true, ParameterSetName="DevelopWebInstall")]
        [switch]$Develop,
        [Parameter(Mandatory=$false, ParameterSetName="ReleaseInstall")]
        [string]$Version = "latest"
    ) 

    $successCheck = [char]0x2714 # ✔️
    $failureCheck = [char]0x2613 # 

    # ------ Validate installation type and get update URI ------
    Write-StatusMessage "- Validating Installation Type..." -Width 60 -ForegroundColor Gray -NoNewLine
    $UpdateChoice = Get-DevSetupUpdateUri @PSBoundParameters
    if(-not $UpdateChoice) {
        Write-StatusMessage "Failed to determine update URI." -Verbosity Error
        return $false
    }
    Write-StatusMessage (Format-RightText "[$($UpdateChoice.Version)]" 20) -ForegroundColor Green
    # ------------------------------------------------------

    # ------ Download update ------
    Write-StatusMessage "- Downloading update..." -Width 60 -ForegroundColor Gray -NoNewLine
    $UpdateArchive = Invoke-DevSetupDownloadUpdate -Uri $UpdateChoice.Uri
    if(-not $UpdateArchive) {
        Write-StatusMessage "Failed to download update." -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
        return $false
    }
    Write-StatusMessage (Format-RightText "[$successCheck]" 20) -ForegroundColor Green
    # ------------------------------------------------------


    # ------ Extract update ------
    Write-StatusMessage "- Extracting update..." -Width 60 -ForegroundColor Gray -NoNewLine
    $ExtractPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("devsetup_update_" + [System.Guid]::NewGuid().ToString())
    Write-StatusMessage "Extracting update archive to temporary path: $ExtractPath" -Verbosity Debug
    try {
        if( -not (Expand-DevSetupUpdateArchive -Path $UpdateArchive -DestinationPath $ExtractPath)) {
            Write-StatusMessage "Failed to extract update archive." -Verbosity Error
            Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
            return $false
        }
    } catch {
        Write-StatusMessage "Failed to extract update archive: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
        return $false
    }

    if( -not $ExtractPath -or -not (Test-Path $ExtractPath -ErrorAction SilentlyContinue)) {
        Write-StatusMessage "Extraction path not found: $ExtractPath" -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
        return $false
    }
    Write-StatusMessage (Format-RightText "[$successCheck]" 20) -ForegroundColor Green
    # ------------------------------------------------------

    # ------ Validate downloaded module ------  
    Write-StatusMessage "- Validating downloaded module..." -Width 60 -ForegroundColor Gray -NoNewLine  
    $ExtractedModulePath = (Get-ChildItem -Path $ExtractPath | Select-Object -First 1).FullName
    $DownloadedModulePath = Join-Path -Path $ExtractedModulePath -ChildPath "DevSetup"

    $DownloadedManifest = Get-DownloadedDevSetupManifest -ModulePath $DownloadedModulePath
    if(-not $DownloadedManifest) {
        Write-StatusMessage "Failed to read downloaded module manifest." -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
        return $false
    }
    if(-not $DownloadedManifest.ModuleVersion -or [string]::IsNullOrEmpty($DownloadedManifest.ModuleVersion)) {
        Write-StatusMessage "Downloaded module manifest does not contain a valid version." -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
        return $false
    }
    Write-StatusMessage (Format-RightText "[$successCheck]" 20) -ForegroundColor Green
    # ------------------------------------------------------

    Write-StatusMessage "- Installing DevSetup Version..." -Width 60 -NoNewLine -ForegroundColor Gray
    Write-StatusMessage (Format-RightText "[$($DownloadedManifest.ModuleVersion)]" 20) -ForegroundColor Green

    Write-StatusMessage "- Checking PowerShell Version..." -Width 60 -NoNewLine -ForegroundColor Gray
    Write-StatusMessage (Format-RightText "[$($PSVersionTable.PSVersion)]" 20) -ForegroundColor Green
    Write-StatusMessage "- Checking PowerShell Edition..." -Width 60 -NoNewLine -ForegroundColor Gray 
    Write-StatusMessage (Format-RightText "[$($PSVersionTable.PSEdition)]" 20) -ForegroundColor Green  
    
    # --------- Install prerequisites -------------------------
    Write-StatusMessage "- Installing required prerequisites..." -Width 60 -NoNewLine -ForegroundColor Gray
    try {
        Install-RequiredDevSetupModules -Modules $DownloadedManifest.RequiredModules
    } catch {
        Write-StatusMessage "Failed to install required modules: $_" -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
    }
    Write-StatusMessage (Format-RightText "[$successCheck]" 20) -ForegroundColor Green
    # ------------------------------------------------------

    # --------- Uninstall old module version -------------------------
    Write-StatusMessage "- Uninstalling old DevSetup module..." -Width 60 -NoNewLine -ForegroundColor Gray
    try {
        Uninstall-DevSetupModule
    } catch {
        Write-StatusMessage "Failed to uninstall old DevSetup module: $_" -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
        return $false
    }
    Write-StatusMessage (Format-RightText "[$successCheck]" 20) -ForegroundColor Green
    # ------------------------------------------------------

    # --------- Install new module version -------------------------
    Write-StatusMessage "- Installing new DevSetup module..." -Width 60 -NoNewLine -ForegroundColor Gray
    try {
        if(-not (Install-DevSetupModule -ModulePath $DownloadedModulePath -Manifest $DownloadedManifest)) {
            Write-StatusMessage "Failed to install new DevSetup module." -Verbosity Error
            Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
            return $false
        }
    } catch {
        Write-StatusMessage "Failed to install new DevSetup module: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
        return $false
    }
    Write-StatusMessage (Format-RightText "[$successCheck]" 20) -ForegroundColor Green
    # ------------------------------------------------------

    $ModuleFound = Get-Module -ListAvailable -Name "DevSetup" -ErrorAction SilentlyContinue
    Write-StatusMessage "- Verifying installation..." -Width 60 -NoNewLine -ForegroundColor Gray
    if ($ModuleFound) {
        Write-StatusMessage (Format-RightText "[$($ModuleFound.Version)]" 20) -ForegroundColor Green
    } else {
        Write-StatusMessage (Format-RightText "[$failureCheck]" 20) -ForegroundColor Red
    }
    Write-StatusMessage "`nInstallation completed successfully!" -ForegroundColor Green
    Write-StatusMessage "You can now use DevSetup commands in any PowerShell session." -ForegroundColor White
    Write-StatusMessage "`nTo get started:" -ForegroundColor Cyan
    Write-StatusMessage "  Please restart your PowerShell session to use the updated module." -ForegroundColor White
}