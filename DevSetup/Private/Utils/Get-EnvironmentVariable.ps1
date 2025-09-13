Function Get-EnvironmentVariable {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name,
        
        [Parameter()]
        [ValidateSet("Process", "User", "Machine")]
        [string]$Scope = "Process"
    )
    process {
        try {
            # Handle different scopes for environment variables
            switch ($Scope) {
                "Process" {
                    Write-Output ([System.Environment]::GetEnvironmentVariable($Name))
                }
                "User" {
                    # On Windows, get User-scoped environment variables
                    # On non-Windows platforms, this will return $null
                    if (Test-OperatingSystem -Windows) {
                        Write-Output ([System.Environment]::GetEnvironmentVariable($Name, "User"))
                    } else {
                        Write-Output $null
                    }
                }
                "Machine" {
                    # On Windows, get Machine-scoped environment variables
                    # On non-Windows platforms, this will return $null
                    if (Test-OperatingSystem -Windows) {
                        Write-Output ([System.Environment]::GetEnvironmentVariable($Name, "Machine"))
                    } else {
                        Write-Output $null
                    }
                }
            }
        }
        catch {
            # If there's an error accessing environment variables, return $null
            Write-Output $null
        }
    }
}