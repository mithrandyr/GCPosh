<#
.Synopsis
    Disables a Security User in GeoCall.

.Description
    Disables a Security User in GeoCall.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

#>
filter Disable-GCPSecurityUser {
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)
        , [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName, Position = 0)][string]$username)
    
    try { Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users/$username" -Method Delete | Out-Null } 
    catch { Write-Error "Could not delete the user '$username'!" }
}

Export-ModuleMember -Function Disable-GCPSecurityUser