Function Test-RunningAsAdmin {
    # Check if we're on Windows - Windows security principals are Windows-only
    if (-not (Test-OperatingSystem -Windows)) {
        # On non-Windows platforms, assume we have sufficient privileges
        return $true
    }
    
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return $false
    }    
    return $true
}