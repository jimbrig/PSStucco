@{
    # Modern PowerShell package management
    'Microsoft.PowerShell.PSResourceGet' = @{
        Version = 'latest'
    }
    PSDependOptions                      = @{
        Target = 'CurrentUser'
    }
    'Pester'                             = @{
        Version    = '5.6.1'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    'psake'                              = @{
        Version = 'latest'
    }
    'InvokeBuild'                        = @{
        Version = 'latest'
    }
    'BuildHelpers'                       = @{
        Version = 'latest'
    }
    'Plaster'                            = @{
        Version = 'latest'
    }
    'PowerShellBuild'                    = @{
        Version = 'latest'
    }
    'PSScriptAnalyzer'                   = @{
        Version = '1.22.0'
    }
    'platyPS'                            = @{
        Version = 'latest'
    }
    'PSReadLine'                         = @{
        Version = 'latest'
    }
}
