<#
.Synopsis
    Creates a new Security User in GeoCall.

.Description
    Creates a new Security User in GeoCall.

.Parameter Host
    Defaults to Get-GCPDnsHost, can specify the hostname to operate against.

.Parameter Token
    Defaults to Get-GCPConfigApiKey, can specify the token to use.

.Parameter Username
    The username to create, must be unique.

.Parameter Password
    The password for the user.

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
filter New-GCPSecurityUser {
    param([string]$DnsHost = (Get-GCPDnsHost)
        , [string]$Token = (Get-GCPConfigApiKey)
        , [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)][string]$Username
        , [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$Password
        , [Parameter(ValueFromPipelineByPropertyName)][string]$Email
        , [Parameter(ValueFromPipelineByPropertyName)][string]$Comment
        , [Parameter(ValueFromPipelineByPropertyName)][switch]$NotApproved
        , [Parameter(ValueFromPipelineByPropertyName)][switch]$Locked
        , [Parameter(ValueFromPipelineByPropertyName)][string[]]$Roles
        , [Parameter(ValueFromPipelineByPropertyName)][ValidateSet("GeoCallV3", "GeoCallClient", "GeoCallPortal")][string[]]$Applications
    )

    $result = Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users?pattern=$Username&deleted=true" -Method Get |
         Select-Object -ExpandProperty users -ErrorAction Ignore |
         Select-Object -ExpandProperty user -ErrorAction Ignore

    if($result) {
        if([bool]::Parse($result.isDeleted)) { throw "User '$Username' already exists, but is deleted!" }
        else { throw "User '$username' already exists!" }
    }
    
    [string[]]$RoleNames = Get-GCPSecurityRole -DnsHos $DnsHost -Token $Token

    [xml]$xmlObject = @"
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

    $xmlObject.user.username = $Username
    if($email) { $xmlObject.user.email = $Email }
    if($comment) { $xmlObject.user.comment = $Comment }
    if($NotApproved) { $xmlObject.user.isApproved = "false" }
    if($Locked) { $xmlObject.user.isLockedOut = "true" }
    if($Applications) { $xmlObject.user.allowedApplications = (($Applications | Select-Object -Unique) -join ";") }
    if($Roles) {
        foreach($r in $Roles | Select-Object -Unique) {
            $rName = $RoleNames -eq $r
            if($rName) {
                newXmlElement -xmlObject $xmlObject -Name role -attributes (newXmlAttribute -xmlObject $xmlObject -Name name -Value $rName) -Parent $xmlObject.user.Item("roles") | Out-Null
            }
        }
    }

    try { Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users" -Method Post -Body $xmlObject.InnerXml | Out-Null }
    catch {
        Write-Verbose $xmlObject.InnerXml
        throw "Failed to create the user! >> $_"
    }

    try { Invoke-GCPApi -DnsHost $DnsHost -Token $Token -Api "core/security/users/$username/password" -Method Put -Body $password | Out-Null }
    catch { throw "Failed to set the password of $username! >> $_" }
}

Export-ModuleMember -Function New-GCPSecurityUser