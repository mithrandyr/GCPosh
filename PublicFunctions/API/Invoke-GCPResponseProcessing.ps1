<#
.Synopsis
    Invokes the Response Processing API Endpoints.

.Description
    Invokes the Response Processing API Endpoints.
    Primarily this is:
        app/response/process

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

#>
function Invoke-GCPResponseProcessing {
    [cmdletBinding()]
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)        
    )

    $ErrorActionPreference = "Stop"
    Write-Verbose "API: app/response/process"
    Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "app/response/process" -Method Post | Out-Null
}

Export-ModuleMember -Function Invoke-GCPResponseProcessing