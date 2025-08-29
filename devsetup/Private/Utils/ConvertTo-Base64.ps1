Function ConvertTo-Base64 {
    param (
        [Parameter(ParameterSetName = "File", Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(ParameterSetName = "String", Mandatory = $true)]
        [string]$InputString
    )

    try {
        if ($PSCmdlet.ParameterSetName -eq "String") {
            # Convert string to Base64
            $stringBytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
            $base64String = [System.Convert]::ToBase64String($stringBytes)
            return $base64String
        }
        else {
            # Convert file to Base64 (existing functionality)
            if (-not (Test-Path -Path $FilePath)) {
                Write-Error "File not found: $FilePath"
                return $null
            }
            
            $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
            $base64String = [System.Convert]::ToBase64String($fileBytes)
            return $base64String
        }
    } catch {
        Write-Error "Failed to convert to Base64: $_"
        return $null
    }
}