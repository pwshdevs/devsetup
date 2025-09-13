Function Test-RunningAsAdmin {
    # Check if we're on Windows - Windows security principals are Windows-only
    if (-not (Test-OperatingSystem -Windows)) {
        # On non-Windows platforms, assume we have sufficient privileges
        return $true
    }

    try {
        $WindowsIdentity = Invoke-Command { [Security.Principal.WindowsIdentity]::GetCurrent() }
        if($null -eq $WindowsIdentity) {
            return $false
        }
        $WindowsBuiltInRole = Invoke-Command { [Security.Principal.WindowsBuiltInRole]::Administrator }
        if ($null -eq $WindowsBuiltInRole) {
            return $false
        }
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($WindowsIdentity)
        if (-not $currentPrincipal.IsInRole($WindowsBuiltInRole)) {
            return $false
        }    
        return $true
    } catch {
        return $false
    }
}