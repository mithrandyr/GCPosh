<#
.Synopsis
    Invokes the Ticket Processing API Endpoints.

.Description
    Invokes the Ticket Processing API Endpoints.
    Primarily this is:
        queue/process/prepare
        queue/process/queue
        queue/process/queuesubmitted

.Parameter Interval
    Number of seconds between touching each endpoint.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

#>
function Invoke-GCPQueueProcessing {
    [cmdletBinding()]
    param(
        [int]$Interval = 0    
        , [string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)        
    )

    $ErrorActionPreference = "Stop"
    [string[]]$EndpointList = @(
        "queue/process/prepare"
        "queue/process/queue"
        "queue/process/queuesubmitted"
    )

    foreach ($ep in $EndpointList) {
        Write-Verbose "API: $ep"
        Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api $ep -Method Post | Out-Null
        Start-Sleep -Seconds $Interval
    }
}

Export-ModuleMember -Function Invoke-GCPQueueProcessing