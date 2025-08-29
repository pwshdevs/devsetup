Function ConvertFrom-Base64 {
    param (
        [string]$EncodedString,
        [string]$OutputFile
    )

    if (-not $EncodedString) {
        Write-Error "Base64 string is empty."
        return $false
    }

    try {
        # Decode the base64 string
        $decodedBytes = [System.Convert]::FromBase64String($EncodedString)
        
        if ($OutputFile) {
            # Write to file if OutputFile is provided
            [System.IO.File]::WriteAllBytes($OutputFile, $decodedBytes)
            return $true
        } else {
            # Return the decoded string if no OutputFile is provided
            $decodedString = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            return $decodedString
        }
    } catch {
        Write-Error "Failed to convert Base64: $_"
        return $false
    }
}