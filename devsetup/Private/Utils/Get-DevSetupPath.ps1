Function Get-DevSetupPath {
        # Get user's home directory
        $homeDirectory = Get-EnvironmentVariable USERPROFILE
        
        # Define .devsetup folder path
        $devSetupPath = Join-Path -Path $homeDirectory -ChildPath ".devsetup"

        return $devSetupPath
}