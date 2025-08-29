Function Use-DevSetup {
    <#
    .SYNOPSIS
    Manages development environment configurations using the DevSetup module.

    .DESCRIPTION
    Use-DevSetup is the main function for managing development environments. It provides actions to install, update, initialize, export, list, and uninstall development environment configurations.
    The function supports multiple installation sources including local configurations by name, remote URLs, and local file paths.
    
    Run 'Use-DevSetup -Init' first to set up the DevSetup environment and initialize the necessary directory structure and configuration files.

    .PARAMETER Install
    Installs a development environment from a configuration file. Can be used with Name, Url, or FilePath parameters.

    .PARAMETER Update
    Updates an existing development environment configuration. Requires the Name parameter.

    .PARAMETER Init
    Initializes the DevSetup environment and sets up the necessary directory structure and configuration files. This should be run first before using other actions.

    .PARAMETER Export
    Exports the current development environment to a configuration file. Requires the Name parameter to specify the name for the exported configuration.

    .PARAMETER List
    Lists all available development environment configurations.

    .PARAMETER Uninstall
    Uninstalls a development environment configuration. Requires the Name parameter.

    .PARAMETER Name
    The name of the environment configuration to use. Required for Install, Update, Export, and Uninstall actions when using local configurations.

    .PARAMETER Url
    The URL of a remote configuration file to install. Used with the Install action for remote installations.

    .PARAMETER Path
    The local file path to a configuration file to install. Used with the Install action for local file installations.

    .PARAMETER Platform
    The platform to filter environments by when using the List action. Use "current" (default) to show environments for the current platform, "all" to show all environments, or specify a platform like "Windows", "Linux", "macOS".

    .OUTPUTS
    [System.Boolean]
    Returns $true if the action completes successfully, $false otherwise.

    .EXAMPLE
    Use-DevSetup -Init
    
    Initializes the DevSetup environment. Run this first to set up the necessary directory structure and configuration files.

    .EXAMPLE
    Use-DevSetup -List
    
    Lists development environment configurations for the current platform.

    .EXAMPLE
    Use-DevSetup -List -Platform "all"
    
    Lists all available development environment configurations regardless of platform.

    .EXAMPLE
    Use-DevSetup -List -Platform "Linux"
    
    Lists development environment configurations specifically for Linux.

    .EXAMPLE
    Use-DevSetup -Install -Name "WebDev"
    
    Installs the development environment using the "WebDev" configuration from local configurations.

    .EXAMPLE
    Use-DevSetup -Install -Url "https://raw.githubusercontent.com/user/configs/main/webdev.devsetup"
    
    Installs a development environment from a remote configuration file URL.

    .EXAMPLE
    Use-DevSetup -Install -Path "C:\Configs\MySetup.devsetup"
    
    Installs a development environment from a local configuration file path.

    .EXAMPLE
    Use-DevSetup -Update -Name "WebDev"
    
    Updates the existing "WebDev" development environment with any new packages or changes.

    .EXAMPLE
    Use-DevSetup -Export -Name "MyCurrentSetup"
    
    Exports the current system's installed packages and tools to a new configuration file named "MyCurrentSetup".

    .EXAMPLE
    Use-DevSetup -Uninstall -Name "WebDev"
    
    Uninstalls all packages and tools associated with the "WebDev" configuration.

    .NOTES
    - Run 'Use-DevSetup -Init' first to initialize the DevSetup environment before using other actions
    - Only one action can be specified at a time using parameter sets
    - Supports three installation methods:
      * By Name: Uses local configuration files from the DevSetup directory
      * By URL: Downloads and installs from a remote configuration file
      * By Path: Installs from a local file path outside the DevSetup directory
    - The function validates input and provides appropriate error messages for invalid combinations
    - Displays formatted progress headers with color-coded output for better user experience
    - Includes comprehensive try-catch error handling with descriptive error messages
    - Update and Uninstall actions are marked as TODO and not yet implemented

    .LINK

    .COMPONENT
    DevSetup.Public

    .FUNCTIONALITY
    Environment Management, Configuration Installation, System Setup
#>
    
    Param(
        [Parameter(Mandatory = $true, ParameterSetName = "Install")]
        [Parameter(Mandatory = $true, ParameterSetName = "InstallUrl")]
        [Parameter(Mandatory = $true, ParameterSetName = "InstallPath")]
        [switch]$Install,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Update")]
        [switch]$Update,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Init")]
        [switch]$Init,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Export")]
        [switch]$Export,
        
        [Parameter(Mandatory = $true, ParameterSetName = "List")]
        [switch]$List,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Uninstall")]
        [switch]$Uninstall,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Install")]
        [Parameter(Mandatory = $true, ParameterSetName = "Update")]
        [Parameter(Mandatory = $true, ParameterSetName = "Export")]
        [Parameter(Mandatory = $true, ParameterSetName = "Uninstall")]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = "InstallUrl")]
        [string]$Url,
        
        [Parameter(Mandatory = $true, ParameterSetName = "InstallPath")]
        [string]$Path,
        
        [Parameter(Mandatory = $false, ParameterSetName = "List")]
        [string]$Platform = "current"
    )

    try {
        # Determine which action was selected based on parameter set
        $selectedAction = $PSCmdlet.ParameterSetName.ToLower()
        

        function Repeat-Char($char, $count) { -join (1..$count | ForEach-Object { $char }) }

        # Display fancy action header
        #Write-Host ""
        #Write-Host "+===============================================================================+" -ForegroundColor Cyan
        #Write-Host "|" -ForegroundColor Cyan -NoNewline
        #Write-Host "                                   DEVSETUP                                    " -ForegroundColor Yellow -NoNewline
        #Write-Host "|" -ForegroundColor Cyan
        #Write-Host "|" -ForegroundColor Cyan -NoNewline
        #Write-Host "                        Development Environment Manager                        " -ForegroundColor White -NoNewline
        #Write-Host "|" -ForegroundColor Cyan
        #Write-Host "+===============================================================================+" -ForegroundColor Cyan
# Define box drawing characters using [char] codes
        $b = [char]0x2588  # █ (full block)
        $tl = [char]0x2554 # ╔ (top-left)
        $tr = [char]0x2557 # ╗ (top-right)
        $bl = [char]0x255A # ╚ (bottom-left)
        $br = [char]0x255D # ╝ (bottom-right)
        $h = [char]0x2550  # ═ (horizontal)
        $v = [char]0x2551  # ║ (vertical)
        $ml = [char]0x2560 # 
        $mr = [char]0x2563
        
        $tb = "$tl" + (Repeat-Char $h 118) + "$tr"
        $bm = "$ml" + (Repeat-Char $h 118) + "$mr"
        $bb = "$bl" + (Repeat-Char $h 118) + "$br"
        $sp = "$v" + (Repeat-Char " " 118) + "$v"
        
        Write-Host ""
        Write-Host "$tb" -ForegroundColor Cyan
        Write-Host "$sp" -ForegroundColor Cyan
        Write-Host "$v" (Repeat-Char " " 25) -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine 
        Write-Host "$b$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b" -ForegroundColor White -NoNewLine 
        Write-Host "$tr" (Repeat-Char " " 24) "$v" -ForegroundColor Cyan

        #Write-Host "$v     $b$b$tl$h$h$b$b$tr$b$b$tl$h$h$h$h$br$b$b$v   $b$b$v$b$b$tl$h$h$h$h$br$b$b$tl$h$h$h$h$br$bl$h$h$b$b$tl$h$h$br$b$b$v   $b$b$v$b$b$tl$h$h$b$b$tr       $v" -ForegroundColor Cyan
        Write-Host "$v" (Repeat-Char " " 25) -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h$h$h$br" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h$h$h$br" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h$h$h$br$bl$h$h" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h$br" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" (Repeat-Char " " 23) "$v" -ForegroundColor Cyan

        #Write-Host "$v     $b$b$v  $b$b$v$b$b$b$b$b$tr  $b$b$v   $b$b$v$b$b$b$b$b$b$b$tr$b$b$b$b$b$tr     $b$b$v   $b$b$v   $b$b$v$b$b$b$b$b$b$tl$br       $v" -ForegroundColor Cyan
        Write-Host "$v" (Repeat-Char " " 25) -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v  " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr  " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr     " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$br" (Repeat-Char " " 23) "$v" -ForegroundColor Cyan

        #Write-Host "$v     $b$b$v  $b$b$v$b$b$tl$h$h$br  $bl$b$b$tr $b$b$tl$br$bl$h$h$h$h$b$b$v$b$b$tl$h$h$br     $b$b$v   $b$b$v   $b$b$v$b$b$tl$h$h$h$br        $v" -ForegroundColor Cyan
        Write-Host "$v" (Repeat-Char " " 25) -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v  " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h$br  $bl" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$br$bl$h$h$h$h" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h$br     " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$h$h$h$br" (Repeat-Char " " 24) "$v" -ForegroundColor Cyan

        #Write-Host "$v     $b$b$b$b$b$b$tl$br$b$b$b$b$b$b$b$tr $bl$b$b$b$b$tl$br $b$b$b$b$b$b$b$v$b$b$b$b$b$b$b$tr   $b$b$v   $bl$b$b$b$b$b$b$tl$br$b$b$v            $v" -ForegroundColor Cyan
        Write-Host "$v" (Repeat-Char " " 25) -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$br" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr $bl" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$br " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tr   " -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v   $bl" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b$b$b$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$tl$br" -ForegroundColor Cyan -NoNewLine
        Write-Host "$b$b" -ForegroundColor White -NoNewLine
        Write-Host "$v" (Repeat-Char " " 28) "$v" -ForegroundColor Cyan
        
        Write-Host "$v" (Repeat-Char " " 24) "$bl$h$h$h$h$h$br $bl$h$h$h$h$h$h$br  $bl$h$h$h$br  $bl$h$h$h$h$h$h$br$bl$h$h$h$h$h$h$br   $bl$h$br    $bl$h$h$h$h$h$br $bl$h$br" (Repeat-Char " " 28) "$v" -ForegroundColor Cyan
        
        Write-Host "$v" -ForegroundColor Cyan -NoNewline
        $version = Get-DevSetupVersion -Local
        $versionDisplay = "Development Environment Manager v$version"
        $paddedAction = $versionDisplay.PadLeft(($versionDisplay.Length + 118) / 2).PadRight(118)
        Write-Host "$paddedAction" -ForegroundColor White -NoNewline
        Write-Host "$v" -ForegroundColor Cyan
        Write-Host "$sp" -ForegroundColor Cyan
        Write-Host "$bm" -ForegroundColor Cyan

        
        $actionDisplay = switch ($selectedAction) {
            'install'   { ">> INSTALLING Development Environment" }
            'update'    { ">> UPDATING Development Environment" }
            'init'      { ">> INITIALIZING DevSetup System" }
            'export'    { ">> EXPORTING Current Configuration" }
            'list'      { ">> LISTING Available Environments" }
            'uninstall' { ">> UNINSTALLING Development Environment" }
        }

        $paddedAction = $actionDisplay.PadLeft(($actionDisplay.Length + 118) / 2).PadRight(118)
        Write-Host "$v" -ForegroundColor Cyan -NoNewline
        Write-Host "$paddedAction" -ForegroundColor Yellow -NoNewline
        Write-Host "$v" -ForegroundColor Cyan
        Write-Host "$bb" -ForegroundColor Cyan
        Write-Host ""
        
        switch ($selectedAction) {
            'install' {
                Write-Host "Installing development environment..." -ForegroundColor Yellow
                Install-DevSetupEnv @PSBoundParameters
            }
            'update' {
                Write-Host "Updating development environment..." -ForegroundColor Yellow
                # TODO: Implement update logic
            }
            'init' {
                Write-Host "Initializing DevSetup environment..." -ForegroundColor Yellow
                Initialize-DevSetup | Out-Null
            }
            'export' {
                Write-Host "Exporting current development environment..." -ForegroundColor Yellow
                Export-DevSetupEnv -Name $Name
            }
            'list' {
                Show-DevSetupEnvList -Platform $Platform
            }
            'uninstall' {
                Write-Host "Uninstalling development environment..." -ForegroundColor Yellow
                Uninstall-DevSetupEnv -Name $Name
            }
        }

        #Write-Host "DevSetup action '$selectedAction' completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Error executing DevSetup action '$selectedAction': $_"
    }
}