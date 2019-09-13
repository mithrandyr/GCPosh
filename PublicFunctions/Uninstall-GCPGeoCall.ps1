function Uninstall-GCPGeoCall {
    [CmdletBinding()]
    param()
    $ErrorActionPreference = "Stop"

    VerifyGCPosh
    VerifyGeoCallDeployed

    RunGCHost /rm:uninstall /quiet
}

Export-ModuleMember -Function Uninstall-GCPGeoCall