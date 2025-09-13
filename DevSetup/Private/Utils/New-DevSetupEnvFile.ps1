Function New-DevSetupEnvFile {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param()

    return [PSCustomObject][ordered]@{
        devsetup = [PSCustomObject][ordered]@{
            dependencies = [PSCustomObject][ordered]@{
                chocolatey = @{
                    packages = @()
                }
                powershell = @{
                    modules = @()
                    scope = "CurrentUser"
                }
                scoop = @{
                    packages = @()
                    buckets = @()
                }
                homebrew = @{
                    packages = @()
                }
            }
            commands = @()
            configuration = [ordered]@{
                description = "Auto-generated development environment configuration"
                version = "1.0.0"
                createdDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                lastModified = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                createdBy = $null
                os = [PSCustomObject][ordered]@{
                    name = $null
                    version = $null
                    architecture = $null
                }
                powershell = [PSCustomObject][ordered]@{
                    version = $PSVersionTable.PSVersion.ToString()
                    edition = $PSVersionTable.PSEdition
                }
            }
        }
    }
}