<#
.Synopsis
    Requests a User AuthToken from GeoCall.
.Description
    Requests a User AuthToken from GeoCall by passing in a UserName
    and password.
.Parameter DnsHost
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.
.Parameter UserName
    Username for the authentication request
.Parameter Password
    Password for the authentication request 
#>
function Request-GCPAuthToken {
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [Parameter(Mandatory, Position=0)][string]$Username
        , [Parameter(Mandatory)][string]$Password
    )

    [string]$encodedPW = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Password))
    $hdr = @{"WWW-Authenticate" = $encodedPW}
    $result = Invoke-WebRequest -UseBasicParsing -Uri ("$DnsHost/geocall/api/core/security/users/$Username/authenticate?app=GeoCallV3") -Headers $hdr -Method Post
    "GCS {0}" -f $result.Headers.Authorization
}

Export-ModuleMember -Function Request-GCPAuthToken