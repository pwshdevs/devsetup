<#
.SYNOPSIS
    Installs a complete development environment from a YAML configuration file.

.DESCRIPTION
    This function orchestrates the installation of a development environment by reading a YAML configuration file
    and processing all defined dependencies and commands. It sequentially installs PowerShell modules, Chocolatey
    packages, Scoop buckets and packages, then executes any custom commands specified in the configuration.
    The function provides comprehensive error handling and progress reporting throughout the installation process.

.PARAMETER Name
    The name of the environment configuration file to install (without the .yaml extension).
    The function will look for a file named "{Name}.yaml" in the DevSetup environment path.
    This parameter is mandatory and accepts positional input.

.OUTPUTS
    None. This function does not return a value but writes status information to the console.

.EXAMPLE
    Install-DevSetupEnv -Name "development"

    Installs the development environment from the "development.yaml" configuration file.

.EXAMPLE
    Install-DevSetupEnv "web-dev"

    Installs the web development environment using positional parameter syntax.

.EXAMPLE
    Install-DevSetupEnv -Name "my-environment"

    Demonstrates the PSCustomObject structure that would be parsed from the YAML file.

.NOTES
    - Requires the environment YAML file to exist in the DevSetup environment path
    - Uses Get-DevSetupEnvPath to determine the configuration file location
    - Returns early with error if YAML file is not found or cannot be parsed
    - Processes dependencies in a specific order: PowerShell modules, Chocolatey packages, then Scoop components
    - Commands are executed after all package installations are complete
    - Individual installation failures do not stop the overall process
    - Uses Read-DevSetupEnvFile to parse YAML configuration
    - Leverages Install-PowershellModules, Install-ChocolateyPackages, and Install-ScoopComponents functions
    - Custom commands are executed using Invoke-CommandFromEnv function
    - Provides detailed console output with color-coded status messages
    - Skips command entries that are missing the required command property
    - Command execution includes package name context for better traceability

.LINK

.COMPONENT
    DevSetup.Commands

.FUNCTIONALITY
    Environment Installation, Configuration Processing, Development Setup
#>

Function Install-DevSetupEnv {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName = "Install")]
        [string]$Name,
        [Parameter(Mandatory=$true, Position=0, ParameterSetName = "InstallPath")]
        [string]$Path,
        [Parameter(Mandatory=$true, Position=0, ParameterSetName = "InstallUrl")]
        [string]$Url,
        [Parameter(Mandatory=$false)]
        [switch]$DryRun = $false
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
                Write-StatusMessage "Invalid Path provided" -Verbosity Error
                return
            }
            $YamlFile = $Path
        } elseif($PSBoundParameters.ContainsKey('Url')) {
            $FileName = Split-Path $Url -Leaf
            Write-StatusMessage "Downloading DevSetup environment from:" -ForegroundColor Cyan
            Write-StatusMessage "- $Url" -Indent 2 -ForegroundColor Gray
            $YamlFile = Join-Path -Path (Get-DevSetupLocalEnvPath) -ChildPath $FileName
            Write-StatusMessage "Saving Devsetup environment file to:" -ForegroundColor Cyan
            Write-StatusMessage "- $YamlFile" -Indent 2 -ForegroundColor Gray
            if((Test-Path -Path $YamlFile)) {
                Write-Warning "File $YamlFile already exists"
                do {
                    if(($sAnswer = Read-Host "Overwrite existing file and continue? [Y/N]") -eq '') { $sAnswer = 'N' }
                } until ($sAnswer.ToUpper()[0] -match '[yYnN]')
                if(-not ($sAnswer.ToUpper()[0] -match '[Y]')) {
                    return
                }
            }
            try {
                Invoke-WebRequest -Uri $Url -OutFile $YamlFile | Out-Null
            } catch {
                Write-StatusMessage "Failed to download devsetup env file" -Verbosity Error
                return
            }
        }

        if (-not (Test-Path $YamlFile)) {
            Write-StatusMessage "Environment file not found: $YamlFile" -Verbosity Error
            return
        }

        Write-StatusMessage "Installing DevSetup environment from:" -ForegroundColor Cyan
        Write-StatusMessage "- $YamlFile`n" -Indent 2 -ForegroundColor Gray

        # Read the configuration from the YAML file
        $YamlData = Read-DevSetupEnvFile -Config $YamlFile

        # Check if YAML data was successfully parsed
        if ($null -eq $YamlData) {
            Write-StatusMessage "Failed to parse YAML configuration from: $YamlFile" -Verbosity Error
            return
        }

        # Install PowerShell module dependencies
        Invoke-PowershellModulesInstall -YamlData $YamlData -DryRun:$DryRun | Out-Null

        if ((Test-OperatingSystem -Windows)) {
            # Install Chocolatey package dependencies
            Install-ChocolateyPackages -YamlData $YamlData | Out-Null

            # Install Scoop package dependencies
            Install-ScoopComponents -YamlData $YamlData | Out-Null
        } else {
            # Install Homebrew package dependencies
            Invoke-HomebrewComponentsInstall -YamlData $YamlData -DryRun:$DryRun | Out-Null
        }
        # Execute any commands defined in the configuration
        if ($YamlData.devsetup.commands -and $YamlData.devsetup.commands.Count -gt 0) {
            Write-StatusMessage "Executing configuration commands..." -ForegroundColor Cyan

            foreach ($commandEntry in $YamlData.devsetup.commands) {
                if ($commandEntry.command) {
                    Write-StatusMessage "- Executing command for: $($commandEntry.packageName)" -Indent 2 -ForegroundColor Gray
                    if ($commandEntry.params) {
                        Write-StatusMessage "Running command: $Command with parameters: " -Verbosity Debug
                        $CommandParams = @{}
                        if ($commandEntry.params -is [hashtable]) {
                            foreach ($param in $commandEntry.params.GetEnumerator()) {
                                $CommandParams[$param.Key] = $param.Value
                                Write-StatusMessage " - Parameter: $($param.Key) = $($param.Value)" -Verbosity Debug
                            }
                        } elseif ($commandEntry.params -is [PSCustomObject]) {
                            foreach ($param in $commandEntry.params.PSObject.Properties) {
                                $CommandParams[$param.Name] = $param.Value
                                Write-StatusMessage " - Parameter: $($param.Name) = $($param.Value)" -Verbosity Debug
                            }
                        }
                        $CommandParams.LogFile = $PSDefaultParameterValues['Write-EZLog:LogFile']
                        $Command = $commandEntry.command
                        $commandScript = {
                            & $Command @CommandParams
                        }
                        $result = Invoke-Command -ScriptBlock $commandScript
                        if ($LASTEXITCODE -ne 0) {
                            Write-StatusMessage "Command failed with exit code $LASTEXITCODE : $result" -Verbosity Error
                        } else {
                            Write-StatusMessage "Command completed successfully." -Verbosity Verbose
                            Write-StatusMessage "- Command $($commandEntry.packageName) completed successfully." -ForegroundColor Gray -Indent 2
                        }
                    } else {
                        Invoke-Command -ScriptBlock { $commandEntry.command *> $null }
                        if ($LASTEXITCODE -ne 0) {
                            Write-StatusMessage "Command failed with exit code $LASTEXITCODE" -Verbosity Error
                        } else {
                            Write-StatusMessage "Command completed successfully." -Verbosity Verbose
                            Write-StatusMessage "- Command $($commandEntry.packageName) completed successfully." -ForegroundColor Gray -Indent 2
                        }
                    }
                } else {
                    Write-StatusMessage "Skipping command entry with missing command property" -Verbosity Warning
                }
            }
        } else {
            Write-StatusMessage "No commands found in configuration to execute." -ForegroundColor Gray
        }
    } catch {
        Write-StatusMessage "An error occurred during installation: $_" -Verbosity Error
        Write-StatusMessage $_.ScriptStackTrace -Verbosity Error
        return
    }
}