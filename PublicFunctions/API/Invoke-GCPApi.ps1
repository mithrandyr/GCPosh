function Invoke-GCPApi {
    [cmdletbinding(DefaultParameterSetName="apikey")]
    param([string]$DnsHost = (Get-GCPDnsHost)
            , [string]$Api
            , [Parameter(ParameterSetName="apikey")][string]$Token = (Get-GCPConfigApiKey)
            , [Parameter(Mandatory, ParameterSetName="userpw")][string]$Username
            , [Parameter(Mandatory, ParameterSetName="userpw")][string]$UserPW
            , [ValidateSet("Post", "Get", "Put", "Delete")][string]$Method = "Get"
            , $Body
        )
    if($Username) { $token = Request-GCPAuthToken -Username $Username -Password $UserPW -DnsHost $DnsHost }
    
    $headers = @{}
    if($token -like "GCS *") { $headers["WWW-Authenticate"] = $Token }
    else { $headers["X-GeoCall-ApiKey"] = $Token }
    
    Invoke-RestMethod -UseBasicParsing -Uri ("$DnsHost/geocall/api/$api") -Headers $headers -Method $Method -Body $Body
}

Export-ModuleMember -Function Invoke-GCPApi