<#
.Synopsis
    Returns results from UISearch.

.Description
    Returns results from UISearch.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

#>
function Invoke-GCPUISearch {
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)
        , [Parameter(Mandatory)][string]$SearchName
    )

    Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "ui/searches/$SearchName/execute" |
        Select-Object -ExpandProperty results |
        Select-Object -ExpandProperty records |
        Select-Object -ExpandProperty record
}

Export-ModuleMember -Function Invoke-GCPUISearch