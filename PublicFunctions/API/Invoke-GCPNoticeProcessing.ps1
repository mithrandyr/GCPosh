<#
.Synopsis
    Invokes the Notice Processing API Endpoints.

.Description
    Invokes the Notice Processing API Endpoints.
    Primarily this is:
        app/notice/process    
        app/notice/submitted
        
.Parameter Interval
    Number of seconds between touching each endpoint.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

#>
function Invoke-GCPNoticeProcessing {
    [cmdletBinding()]
    param(
        [int]$Interval = 0    
        , [string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)        
    )

    $ErrorActionPreference = "Stop"
    [string[]]$EndpointList = @(
        "app/notice/process"
        "app/notice/submitted"
    )

    foreach ($ep in $EndpointList) {
        Write-Verbose "API: $ep"
        Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api $ep -Method Post | Out-Null
        Start-Sleep -Seconds $Interval
    }
}

Export-ModuleMember -Function Invoke-GCPNoticeProcessing