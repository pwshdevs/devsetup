<#
.SYNOPSIS
    Uninstalls a development environment configuration and removes all associated packages.

.DESCRIPTION
    This function removes a complete development environment by uninstalling all packages and components
    defined in a YAML configuration file. It processes PowerShell modules, Chocolatey packages, and
    Scoop packages in sequence, effectively reversing the installation performed by Install-DevSetupEnv.
    The function validates the configuration file exists and can be parsed before proceeding with
    the uninstallation process.

.PARAMETER Name
    The name of the environment configuration to uninstall.
    This parameter is mandatory and must match an existing YAML configuration file in the DevSetup environments directory.
    The file should be named "{Name}.yaml" and contain valid DevSetup configuration structure.

.OUTPUTS
    None
    This function does not return a value but provides console output indicating the progress of uninstallation operations.

.EXAMPLE
    Uninstall-DevSetupEnv -Name "WebDev"

    Uninstalls all packages and components from the "WebDev" environment configuration.

.EXAMPLE
    Uninstall-DevSetupEnv "DataScience"

    Removes the complete "DataScience" development environment using positional parameter.

.EXAMPLE
    $envName = "GameDev"
    Uninstall-DevSetupEnv -Name $envName

    Demonstrates using a variable to specify the environment name for uninstallation.

.NOTES
    - Requires the specified environment configuration file to exist in the DevSetup environments directory
    - Uses Get-DevSetupEnvPath to locate the environments directory
    - Validates YAML file existence before attempting to parse configuration
    - Processes uninstallation in specific order:
      1. PowerShell modules via Uninstall-PowershellModules
      2. Chocolatey packages via Uninstall-ChocolateyPackages
      3. Scoop packages via Uninstall-ScoopComponents
    - Each uninstaller function handles its own error reporting and validation
    - Does not remove the YAML configuration file itself after uninstallation
    - Provides descriptive error messages for missing or invalid configuration files
    - Status variables are assigned but not currently used for flow control

.LINK

.COMPONENT
    DevSetup.Commands

.FUNCTIONALITY
    Environment Management, Package Removal, Configuration Processing
#>

Function Uninstall-DevSetupEnv {
    [CmdletBinding()]
    [OutputType([void])]
    Param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName = "Uninstall")]
        [Parameter(Mandatory=$true, Position=0, ParameterSetName = "UninstallDry")]
        [string]$Name,
        [Parameter(Mandatory=$true, Position=0, ParameterSetName = "UninstallPath")]
        [Parameter(Mandatory=$true, Position=0, ParameterSetName = "UninstallPathDry")]
        [string]$Path,
        [Parameter(Mandatory=$true, Position=1, ParameterSetName = "UninstallDry")]
        [Parameter(Mandatory=$true, Position=1, ParameterSetName = "UninstallPathDry")]
        [switch]$DryRun
    )

    try {
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
                Write-Error "Invalid Path provided"
                return
            }
            $YamlFile = $Path
        }

        #$YamlFile = Join-Path -Path (Get-DevSetupEnvPath) -ChildPath "$Name.yaml"
        if (-not (Test-Path $YamlFile)) {
            Write-StatusMessage "Environment file not found: $YamlFile" -Verbosity Error
            return
        }

        Write-StatusMessage "Uninstalling DevSetup environment from:" -ForegroundColor Cyan
        Write-StatusMessage "- $YamlFile`n" -Indent 2 -ForegroundColor Gray

        # Read the configuration from the YAML file
        $YamlData = Read-ConfigurationFile -Config $YamlFile

        # Check if YAML data was successfully parsed
        if ($null -eq $YamlData) {
            Write-StatusMessage "Failed to parse YAML configuration from: $YamlFile" -Verbosity Error
            return
        }

        # Uninstall PowerShell module dependencies
        Invoke-PowershellModulesUninstall -YamlData $YamlData -DryRun:$DryRun | Out-Null

        $windows = Test-OperatingSystem -Windows

        if ($windows) {
            # Uninstall Chocolatey package dependencies
            Uninstall-ChocolateyPackages -YamlData $YamlData | Out-Null

            # Uninstall Scoop package dependencies
            Uninstall-ScoopComponents -YamlData $YamlData | Out-Null
        } else {
            # Uninstall Homebrew package dependencies
            Invoke-HomebrewComponentsUninstall -YamlData $YamlData -DryRun:$DryRun | Out-Null
        }
    } catch {
        Write-StatusMessage "An error occurred during uninstallation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return
    }
}