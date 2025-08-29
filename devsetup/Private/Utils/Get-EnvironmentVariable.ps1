Function Get-EnvironmentVariable {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Name
    )
    process {
        Write-Output ([System.Environment]::GetEnvironmentVariable($Name))
    }
}