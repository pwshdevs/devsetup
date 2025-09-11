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

        $YamlFile = Join-Path -Path (Join-Path -Path (Get-DevSetupEnvPath) -ChildPath $Provider) -ChildPath "$Name.devsetup"
    } elseif($PSBoundParameters.ContainsKey('Path')) {
        if(-not (Test-Path -Path $Path)) {
            Write-StatusMessage "Invalid Path provided" -Verbosity Error
            return
        }
        $YamlFile = $Path
    }

    Write-StatusMessage "Reading environment file: $YamlFile" -ForegroundColor Gray
    if (-not (Test-Path $YamlFile)) {
        Write-StatusMessage "Environment file not found: $YamlFile" -Verbosity Error
        return
    }

    $YamlData = Read-DevSetupEnvFile -Config $YamlFile
    if (-not $YamlData) {
        Write-StatusMessage "Failed to read or parse environment file: $YamlFile" -Verbosity Error
        return
    }

    $overviewTableFormat = @{
        BorderColor = "DarkGray"
        NoHeader = $true
    }

    $overviewData = @(
        @{ Name = "Environment Name:"; Value = $YamlData.devsetup.name; Color = "DarkCyan" }
        @{ Name = "Description:"; Value = $YamlData.devsetup.configuration.description; Color = "DarkCyan" }
        @{ Name = "Version:"; Value = $YamlData.devsetup.configuration.version; Color = "DarkCyan" }
        @{ Name = "Created By:"; Value = $YamlData.devsetup.configuration.createdBy; Color = "DarkCyan" }
        @{ Name = "Created Date:"; Value = $YamlData.devsetup.configuration.createdDate; Color = "DarkCyan" }
        @{ Name = "Last Updated:"; Value = $YamlData.devsetup.configuration.lastUpdatedDate; Color = "DarkCyan" }
        @{ Name = "OS:"; Value = $YamlData.devsetup.configuration.os.name; Color = "DarkCyan" }
        @{ Name = "OS Version:"; Value = $YamlData.devsetup.configuration.os.version; Color = "DarkCyan" }
        @{ Name = "Architecture:"; Value = $YamlData.devsetup.configuration.os.architecture; Color = "DarkCyan" }
        @{ Name = "Providers:"; Value = ($YamlData.devsetup.dependencies.Keys | Measure-Object).Count; Color = "DarkCyan" }
        @{ Name = "Packages:"; Value = ($YamlData.devsetup.dependencies | Foreach-Object { $_[$_.Keys].packages.Count } | Measure-Object -Sum).Sum; Color = "DarkCyan" }
        @{ Name = "Modules:"; Value = ($YamlData.devsetup.dependencies | Foreach-Object { $_[$_.Keys].modules.Count } | Measure-Object -Sum).Sum; Color = "DarkCyan" }
        @{ Name = "Commands:"; Value = $YamlData.devsetup.commands.Count; Color = "DarkCyan" }
    )
    $overviewColumns = [ordered]@{
        Name = @{ Name = "Name"; Width = 30; Alignment = "Right"; Color = "White"; Key = "Name" }
        Value   = @{ Name = "Value"; Width = 87; Alignment = "Left"; Color = "White"; Key = "Value" }
    }

    Format-PrettyTable -Rows $overviewData -Columns $overviewColumns -TableFormat $overviewTableFormat

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
        if ($packages -and $packages.Count -gt 0) {
            foreach ($package in $packages) {
                $tableData += @{
                    Name = $package.name
                    Version = $package.version
                    Provider = $manager
                    Color = "DarkGray"
                }
            }
        }
        if ($modules -and $modules.Count -gt 0) {
            foreach ($module in $modules) {
                $tableData += @{
                    Name = $module.name
                    Version = $module.minimumVersion
                    Provider = $manager
                    Color = "DarkGray"
                }
            }
        }
    }
    if( $tableData.Count -eq 0 ) {
        Write-StatusMessage "No packages or modules defined in this environment." -ForegroundColor Yellow
        return
    }
    Format-PrettyTable -Rows $tableData -Columns $columnDefinitions -TableFormat $tableFormat
}