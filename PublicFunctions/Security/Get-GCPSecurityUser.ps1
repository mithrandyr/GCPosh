<#
.Synopsis
    Get all Security Users in GeoCall.

.Description
    Get all Security Uses in GeoCall.  Can use parameters to filter
    which users are returned.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

.Parameter IncludeDeleted
    Will return deleted users.

.Parameter Search
    Will restrict results to username names matching the pattern supplied,
    supports the wildcard character '*'.
#>
function Get-GCPSecurityUser {
    [cmdletBinding()]
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)
        , [switch]$IncludeDeleted
        , [Parameter(ValueFromPipelineByPropertyName, Position=0)][string]$Search)

    [string]$listApi = "core/security/users"
    [string[]]$apiOptions = @()
    if($IncludeDeleted) { $apiOptions += "deleted=true" }
    if($Search -and $Search.Trim().Length -gt 0 -and $Search.Trim().Replace("**","*") -ne "*") { $apiOptions += "pattern=$Search" }
    if($apiOptions.Count -gt 0) { $listApi += "?" + ($apiOptions -join "&") }

    [string[]]$userList = Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api $listApi -Method Get |
        Select-Object -ExpandProperty users |
        Select-Object -ExpandProperty user -ErrorAction Ignore |
        Select-Object -ExpandProperty username
    
    foreach($username in $userList) {
        try {
            $u = Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users/$username" -Method Get | Select-Object -ExpandProperty user
            $userData = [PSCustomObject]@{
                username = $u.username
                email = $u.email
                isApproved = [bool]::Parse($u.isApproved)
                isLockedOut = [bool]::Parse($u.isLockedOut)
                isDeleted = [bool]::Parse($u.isDeleted)
                createdDate = [datetime]$u.createdDate
                lastLoginDate = if($u.lastLoginDate) { [datetime]$u.lastLoginDate } else { $null }
                lastActivityDate = if($u.lastActivityDate) { [datetime]$u.lastActivityDate } else { $null }
                lastPasswordChangeDate = if($u.lastPasswordChangeDate) { [datetime]$u.lastPasswordChangeDate } else { $null }
                allowedApplications = [string[]]@()
                roles = [string[]]@()
            }
            
            if($u.roles) { $u.roles.role.name | ForEach-Object { $userData.roles += $_ } }
            if($u.allowedApplications) { $u.allowedApplications -split ";" | ForEach-Object { $userData.allowedApplications += $_ } }
            
            $userData
        }
        catch { Write-Error "Cannot Process '$username' >> $_" }
    }
}

Export-ModuleMember -Function Get-GCPSecurityUser