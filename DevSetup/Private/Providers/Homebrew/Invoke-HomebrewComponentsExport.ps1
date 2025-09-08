Function Invoke-HomebrewComponentsExport {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Config,
        [Parameter(Mandatory = $false)]
        [string]$OutFile,
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    $YamlData = Read-ConfigurationFile -Config $Config

    # Ensure scoopPackages and scoopBuckets sections exist
    if (-not $YamlData.devsetup) { $YamlData.devsetup = @{} }
    if (-not $YamlData.devsetup.dependencies) { $YamlData.devsetup.dependencies = @{} }
    if (-not $YamlData.devsetup.dependencies.homebrew) { $YamlData.devsetup.dependencies.homebrew = @() }

    if(-not (Find-Homebrew)) {
        Write-StatusMessage "Homebrew is not installed. Please install Homebrew first." -ForegroundColor Red -Verbosity Verbose
        return $false
    }

    Write-StatusMessage "- Getting list of installed Homebrew packages..." -ForegroundColor Gray
    $AvailablePackages = @{
    }
    $BrewArgs = @{
        Command   = "bash"
        Arguments = @("-c", "$(Find-Homebrew) list --versions")
    }
    (Invoke-ExternalCommand @BrewArgs) | foreach-object { $Parts = $_ -split " "; $AvailablePackages[$Parts[0]] = $Parts[1]} | Out-Null

    $InstalledPackages = @()
    $BrewArgs = @{
        Command   = "bash"
        Arguments = @("-c", "$(Find-Homebrew) list --installed-on-request")
    }
    (Invoke-ExternalCommand @BrewArgs) | Foreach-Object { $InstalledPackages += $_} | Out-Null

    Foreach($Package in $InstalledPackages) {
        $PackageVersion = $AvailablePackages[$Package]
        $existing = $YamlData.devsetup.dependencies.homebrew | Where-Object { $_.name -eq $Package }
        if ($existing) {
            # Update the version if package exists
            Write-StatusMessage "  - Updating package: $Package" -ForegroundColor Gray
            $index = ($YamlData.devsetup.dependencies.homebrew).IndexOf($existing)
            $YamlData.devsetup.dependencies.homebrew[$index].minimumVersion = $PackageVersion
        } else {
            Write-StatusMessage "  - Adding package: $Package" -ForegroundColor Gray
            # Add new package entry
            $YamlData.devsetup.dependencies.homebrew += @{ name = $Package; minimumVersion = $PackageVersion }
        }
    }

    try {
        $yamlOutput = $YamlData | ConvertTo-Yaml
    }
    catch {
        Write-StatusMessage "Could not convert to YAML format. Showing PowerShell object instead:" -Verbosity Warning
        $yamlOutput = $YamlData | ConvertTo-Json -Depth 10
    }

    # Determine output file
    $outputFile = if ($OutFile) { $OutFile } else { $Config }

    try {
        Write-StatusMessage "Saving configuration to: $outputFile" -Verbosity Verbose
        if ($PSCmdlet.ShouldProcess($outputFile, "Out-File")) {
            $yamlOutput | Out-File -FilePath $outputFile
        }
        Write-StatusMessage "Configuration saved successfully!" -Verbosity Verbose
    }
    catch {
        Write-StatusMessage "Failed to save configuration to $outputFile`: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace
        return $false
    }

    Write-StatusMessage "Homebrew packages conversion completed!" -ForegroundColor Green
    return $true
}