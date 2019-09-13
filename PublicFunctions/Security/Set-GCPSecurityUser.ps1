<#
.Synopsis
    Sets properties on the GeoCall Security User.

.Description
    Sets properties on the GeoCall Security User.
    Any property not specified will be ignored.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

.Parameter Username
    The username of the user to modify.

.Parameter NewPassword
    The new password for the user.

.Parameter Email
    This is the email address for the user.

.Parameter Comment
    Description for the user.

.Parameter NotApproved
    User will be created with "Is Approved" not set.

.Parameter Locked
    User will be created with "Is Locked" set.

.Parameter Roles
    Which roles, if any, should the user be added to.

.Parameter Applications
    Which applications should be enabled for the user.
#>
filter Set-GCPSecurityUser {
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)
        , [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$Username
        , [Parameter(ValueFromPipelineByPropertyName)][string]$NewPassword
        , [Parameter(ValueFromPipelineByPropertyName)][string]$Email
        , [Parameter(ValueFromPipelineByPropertyName)][string]$Comment
        , [Parameter(ValueFromPipelineByPropertyName)][bool]$Approved
        , [Parameter(ValueFromPipelineByPropertyName)][bool]$Locked
        , [Parameter(ValueFromPipelineByPropertyName)][string[]]$Roles
        , [Parameter(ValueFromPipelineByPropertyName)][ValidateSet("GeoCallV3", "GeoCallClient", "GeoCallPortal")][string[]]$Applications
    )

    $ErrorActionPreference = "Stop"

    try {
        $global:result = Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users/$Username" -Method Get |
        Select-Object -ExpandProperty user -ErrorAction Ignore
    }
    catch { throw "No such user '$username' exists!" }
    [string[]]$RoleNames = Get-GCPSecurityRole -DnsHos $DnsHost -Token $Token

    if($NewPassword) {
        try { Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users/$username/password" -Method Put -Body $NewPassword | Out-Null }
        catch { throw "Failed to set the password of $username! >> $_" }
    }

    [xml]$global:xmlObject = @"
<user xmlns="http://schemas.progressivepartnering.com/geocall/v3/1/security">
    <username></username>
    <email></email>
    <comment></comment>
    <isApproved>true</isApproved>
    <isLockedOut>false</isLockedOut>
    <roles></roles>
    <allowedApplications></allowedApplications>
</user>
"@

    $xmlObject.user.username = $result.username
    if($email) { $xmlObject.user.email = $Email }
    else { $xmlObject.user.email = $result.email.InnerText }
    
    if($comment) { $xmlObject.user.comment = $Comment }
    elseif($result.comment) { $xmlObject.user.comment = $result.comment.InnerText }
    
    if($PSBoundParameters.ContainsKey("Approved")) { $xmlObject.user.isApproved = $Approved.ToString().ToLower() }
    else { $xmlObject.user.isApproved = $result.isApproved }
    
    if($PSBoundParameters.ContainsKey("Locked")) { $xmlObject.user.isLockedOut = $Locked.ToString().ToLower() }
    else { $xmlObject.user.isLockedOut = $result.isLockedout }

    if($PSBoundParameters.ContainsKey("Applications")) { $xmlObject.user.allowedApplications = (($Applications | Select-Object -Unique) -join ";") }
    else { $xmlObject.user.allowedApplications = $result.allowedApplications }

    if($PSBoundParameters.ContainsKey("Roles")) {
        foreach($r in $Roles | Select-Object -Unique) {
            $rName = $RoleNames -eq $r
            if($rName) {
                newXmlElement -xmlObject $xmlObject -Name role -attributes (newXmlAttribute -xmlObject $xmlObject -Name name -Value $rName) -Parent $xmlObject.user.Item("roles") | Out-Null
            }
        }
    }
    elseif($result.roles) {
        foreach($r in $result.roles.role.name) {
            newXmlElement -xmlObject $xmlObject -Name role -attributes (newXmlAttribute -xmlObject $xmlObject -Name name -Value $r) -Parent $xmlObject.user.Item("roles") | Out-Null
        }
    }

    try {
        Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users" -Method Put -Body $xmlObject | Out-Null
    }
    catch {
        Write-Verbose $xmlObject.InnerXml
        throw "Failed to update the user! >> $_"
    }
}

Export-ModuleMember -Function Set-GCPSecurityUser