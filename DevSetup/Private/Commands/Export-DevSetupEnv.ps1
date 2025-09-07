<#
.SYNOPSIS
    Exports the current system environment to a new DevSetup configuration file.

.DESCRIPTION
    This function creates a new DevSetup environment configuration by scanning the current system
    for installed packages and components. It automatically sanitizes the environment name to ensure
    file system compatibility and exports the configuration to a YAML file in the DevSetup
    environments directory. The function captures the current state of PowerShell modules,
    Chocolatey packages, and other installed components for later reproduction.

.PARAMETER Name
    The name for the new environment configuration.
    This parameter is mandatory and will be sanitized to contain only alphanumeric characters, hyphens, and periods.
    The resulting YAML file will be named "{Name}.yaml" in the DevSetup environments directory.

.OUTPUTS
    [System.String]
    Returns the full path to the created configuration file if successful.
    Returns $null if the export operation fails.

.EXAMPLE
    Export-DevSetupEnv -Name "MyCurrentSetup"
    
    Exports the current system state to a configuration file named "MyCurrentSetup.yaml".

.EXAMPLE
    $configPath = Export-DevSetupEnv -Name "WebDev-2024"
    if ($configPath) {
        Write-Host "Configuration saved to: $configPath"
    } else {
        Write-Host "Export failed"
    }
    
    Demonstrates capturing the return value to verify export success.

.EXAMPLE
    Export-DevSetupEnv -Name "Data Science Environment!"
    
    The exclamation mark will be removed, resulting in "DataScienceEnvironment.yaml".
    A warning message will indicate the sanitization that occurred.

.NOTES
    - Automatically sanitizes the environment name by removing non-alphanumeric characters except hyphens and periods
    - Displays a warning message if sanitization changes the original name
    - Uses Get-DevSetupEnvPath to determine the target directory for the configuration file
    - Calls Write-NewConfig to perform the actual system scanning and file creation
    - Returns the full file path on success for further processing or verification
    - Returns $null if Write-NewConfig fails to create the configuration
    - The exported configuration can be used with Install-DevSetupEnv to recreate the environment
    - Provides color-coded console output: Yellow for warnings, Green for success, Red for errors

.LINK

.COMPONENT
    DevSetup.Commands

.FUNCTIONALITY
    Environment Export, Configuration Creation, System State Capture
#>

Function Export-DevSetupEnv {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ParameterSetName="Export")]
        [string]$Name,
        [Parameter(Mandatory=$true, ParameterSetName="ExportPath")]
        [string]$Path,
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    $OutFile = $null
    if($PSBoundParameters.ContainsKey('Name')) {
        $Provider = "local"

        if($Name -like "*:*") {
            $Parts = $Name.Split(":")
            $Name = $Parts[1];
            $Provider = $Parts[0]
        }
        $SanitizedEnvName = $Name -replace '[^a-zA-Z0-9\-\.]', ''
        if ($SanitizedEnvName -ne $Name) {
            Write-Host "EnvName sanitized from '$Name' to '$SanitizedEnvName' (removed non-alphanumeric characters)" -ForegroundColor Yellow
        }

        $BasePath = Join-Path -Path (Get-DevSetupEnvPath) -ChildPath $Provider
        if(-not (Test-Path -Path $BasePath)) {
            New-Item -Path $BasePath -ItemType Directory -Force | Out-Null
        }

        $OutFile = Join-Path -Path $BasePath -ChildPath "$SanitizedEnvName.devsetup"
    } elseif($PSBoundParameters.ContainsKey('Path')) {
        $BasePath = Split-Path -Path $Path -Parent
        if(-not (Test-Path -Path $BasePath)) {
            New-Item -Path $BasePath -ItemType Directory -Force | Out-Null
        }
        $Name = Split-Path -Path $Path -Leaf
        if($Name -notlike "*.devsetup") {
            $Name = "$Name.devsetup"
        }
        
        $SanitizedEnvName = $Name -replace '[^a-zA-Z0-9\-\.]', ''

        if ($SanitizedEnvName -ne $Name) {
            Write-Host "EnvName sanitized from '$Name' to '$SanitizedEnvName' (removed non-alphanumeric characters)" -ForegroundColor Yellow
        }
        $OutFile = Join-Path -Path $BasePath -ChildPath $SanitizedEnvName
    }

    if(-not $OutFile) {
        Write-Error "Failed to determine output file path"
        return $null
    }

    $config = Write-NewConfig -OutFile $OutFile -DryRun:$DryRun
    if (-not $config) {
        Write-Error "Failed to create configuration file"
        return $null
    }
    Write-Host "Configuration file exported to: $OutFile" -ForegroundColor Green
    return $OutFile   
}