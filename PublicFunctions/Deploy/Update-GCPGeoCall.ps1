<#
.Synopsis
    GCDM App Upgrade, grabs the latest version of GeoCall.

.Description
    GCDM App Upgrade, grabs the latest version of GeoCall.

.Parameter versionNumber
    which version, defaults to latest

.Parameter Existing
    If doing upgrade against installed environment, then additional steps are useful.
#>
function Update-GCPGeoCall {
    [cmdletBinding()]
    param([string]$versionNumber, [switch]$Existing)
    $ErrorActionPreference = "Stop"
    VerifyGCPosh

    try {
        if($versionNumber) { RunGCDM app get $versionNumber }
        else { RunGCDM app latest }
    }
    catch {
        if($versionNumber) { RunGCDM app get $versionNumber }
        else { RunGCDM app latest }
    }
    

    if(Get-Service GeoCallHostService -ErrorAction Ignore) { Stop-Service GeoCallHostService }
    if($versionNumber) { RunGCDM app upgrade $versionNumber }
    else { RunGCDM app upgrade }

    if($Existing) {
        Initialize-GCPSqlDb -UpdateDateFieldDefaultsOnly
        if(Get-Service GeoCallHostService -ErrorAction Ignore) { Start-Service GeoCallHostService }
    }
    
}

Export-ModuleMember -Function Update-GCPGeoCall