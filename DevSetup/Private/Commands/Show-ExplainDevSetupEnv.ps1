Function Show-ExplainDevSetupEnv {
    [CmdletBinding()]
    [OutputType([void])]
    Param(
        [Parameter(Mandatory = $true, ParameterSetName = "Explain")]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = "ExplainPath")]
        [string]$Path
    )

    $YamlFile = $null

    if($PSBoundParameters.ContainsKey('Name')) {
        $Provider = "local"

        if($Name -like "*:*") {
            $parts = $Name.Split(":")
            $Name = $parts[1];
            $Provider = $parts[0]
        }

        try {
            $envPath = Get-DevSetupEnvPath -Provider $Provider
        } catch {
            Write-StatusMessage "Failed to get environment path. $_" -Verbosity Error
            Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
            return
        }
        $YamlFile = Join-Path -Path (Join-Path -Path $envPath -ChildPath $Provider) -ChildPath "$Name.devsetup"
    } elseif($PSBoundParameters.ContainsKey('Path')) {
        if(-not (Test-Path -Path $Path)) {
            Write-StatusMessage "Invalid Path provided" -Verbosity Error
            return
        }
        $YamlFile = $Path
        $Name = (Split-Path -Path $YamlFile -Leaf).Replace(".devsetup","")
        $Provider = "Path"
    }

    Write-StatusMessage "Reading environment file: $YamlFile" -ForegroundColor Gray
    try {
        if (-not (Test-Path $YamlFile)) {
            Write-StatusMessage "Environment file not found: $YamlFile" -Verbosity Error
            return
        }
    } catch {
        Write-StatusMessage "Failed to access environment file: $YamlFile. $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return
    }

    try {
        $YamlData = Read-DevSetupEnvFile -Config $YamlFile
        if (-not $YamlData) {
            Write-StatusMessage "Failed to read or parse environment file: $YamlFile" -Verbosity Error
            return
        }
    } catch {
        Write-StatusMessage "Failed to read or parse environment file: $YamlFile. $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return
    }

    if ((-not $YamlData.devsetup) -or (-not $YamlData.devsetup.configuration) -or (-not $YamlData.devsetup.dependencies)) {
        Write-StatusMessage "Malformed devsetup environment file: $YamlFile" -Verbosity Warning
        return
    }

    $overviewTableFormat = @{
        BorderColor = "DarkGray"
        NoHeader = $true
    }

    $overviewData = @(
        @{ Name = "Name:"; Value = $Name; Color = "DarkCyan" }
        @{ Name = "Provider:"; Value = $Provider; Color = "DarkCyan" }
        @{ Name = "Description:"; Value = $YamlData.devsetup.configuration.description; Color = "DarkCyan" }
        @{ Name = "Version:"; Value = $YamlData.devsetup.configuration.version; Color = "DarkCyan" }
        @{ Name = "Created By:"; Value = $YamlData.devsetup.configuration.createdBy; Color = "DarkCyan" }
        @{ Name = "Created Date:"; Value = $YamlData.devsetup.configuration.createdDate; Color = "DarkCyan" }
        @{ Name = "Last Updated:"; Value = $YamlData.devsetup.configuration.lastUpdatedDate; Color = "DarkCyan" }
        @{ Name = "Operating System:"; Value = $YamlData.devsetup.configuration.os.name; Color = "DarkCyan" }
        @{ Name = "Packages:"; Value = ($YamlData.devsetup.dependencies | Foreach-Object { $_[$_.Keys].packages.Count } | Measure-Object -Sum).Sum; Color = "DarkCyan" }
        @{ Name = "Modules:"; Value = ($YamlData.devsetup.dependencies | Foreach-Object { $_[$_.Keys].modules.Count } | Measure-Object -Sum).Sum; Color = "DarkCyan" }
        @{ Name = "Commands:"; Value = $YamlData.devsetup.commands.Count; Color = "DarkCyan" }
    )
    $overviewColumns = [ordered]@{
        Name = @{ Name = "Name"; Width = 30; Alignment = "Right"; Color = "White"; Key = "Name" }
        Value   = @{ Name = "Value"; Width = 87; Alignment = "Left"; Color = "White"; Key = "Value" }
    }

    try {
        Format-PrettyTable -Rows $overviewData -Columns $overviewColumns -TableFormat $overviewTableFormat
    } catch {
        Write-StatusMessage "Failed to format overview table: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return
    }

    Write-StatusMessage "`nThis environment installs the following packages and modules:" -ForegroundColor Gray

    $tableFormat = @{
        BorderColor = "DarkGray"
    }

    $tableData = @()
    $columnDefinitions = [ordered]@{
        Name     = @{ Name = "Name"; Width = 81; Alignment = "Left"; Color = "White"; Key = "Name" }
        Version  = @{ Name = "Version"; Width = 15; Alignment = "Center"; Color = "White"; Key = "Version" }
        Provider = @{ Name = "Provider"; Width = 20; Alignment = "Center"; Color = "White"; Key = "Provider" }
    }

    $YamlData.devsetup.dependencies.GetEnumerator() | ForEach-Object {
        $manager = $_.Key
        $packages = $_.Value.packages
        $modules = $_.Value.modules
        $color = "DarkGray"
        if ($packages -and $packages.Count -gt 0) {
            switch ($manager) {
                "chocolatey" { $color = "DarkCyan" }
                "scoop" { $color = "DarkMagenta" }
                "homebrew" { $color = "DarkYellow" }
                default { $color = "DarkGray" }
            }
            foreach ($package in $packages) {
                $tableData += @{
                    Name = $package.name
                    Version = $package.version
                    Provider = $manager
                    Color = $color
                }
            }
        }
        if ($modules -and $modules.Count -gt 0) {
            foreach ($module in $modules) {
                $tableData += @{
                    Name = $module.name
                    Version = $module.minimumVersion
                    Provider = $manager
                    Color = "DarkBlue"
                }
            }
        }
    }
    if( $tableData.Count -eq 0 ) {
        Write-StatusMessage "No packages or modules defined in this environment." -ForegroundColor Yellow
        return
    }

    try {
        Format-PrettyTable -Rows $tableData -Columns $columnDefinitions -TableFormat $tableFormat
    } catch {
        Write-StatusMessage "Failed to format table: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return
    }
}