function Install-GCPGeoCall {
    [CmdletBinding()]
    param()
    $ErrorActionPreference = "Stop"
    VerifyGCPosh

    VerifyGeoCallDeployed
    RunGCHost /rm:install /quiet
    Get-Service -Name GeoCallApacheInstance | Set-Service -StartupType Manual
    SC.exe CONFIG GeoCallHostService Start= delayed-auto
}

Export-ModuleMember -Function Install-GCPGeoCall