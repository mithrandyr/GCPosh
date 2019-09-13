<#
.Synopsis
    Gets all Security Roles in GeoCall.

.Description
    Gets all Security Roles in GeoCall.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.
    
#>
function Get-GCPSecurityRole {
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)
    )

    $ErrorActionPreference = "stop"
    Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/roles" -Method Get |
        Select-Object -ExpandProperty roles |
        Select-Object -ExpandProperty role |
        Select-Object -ExpandProperty name
}

Export-ModuleMember -Function Get-GCPSecurityRole