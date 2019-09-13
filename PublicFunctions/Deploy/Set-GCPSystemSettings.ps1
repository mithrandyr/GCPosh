<#
.Synopsis
    Sets System Settings in Sql Database for Geocall.

.Description
    Set the System Settings in the Sql Database for GeoCall.
    Use -OverrideHT for the following values if not GA811
        general\localName
        general\localnameabbr
        app\authsalt

.Parameter OverrideHT
    Use this HT to change the defaults that will be applied.
    Key = "<category>\<name>"
    Value = <Value>
#>
function Set-GCPSystemSettings {
    param(
        [Parameter()][string]$ConfigName = "current"
        , [Parameter()][Alias("ConnectionName")][string]$CN    
        , [Parameter()][hashtable]$OverrideHT = @{}
        , [Parameter(Mandatory)][string]$DnsHostName
    )
    $ErrorActionPreference = "Stop"
    VerifySimplySql

    [bool]$closeConnection = $false
    if(-not $CN) {
        VerifyGCPosh
        VerifyConfigName -ConfigName $ConfigName

        $closeConnection = $true
        $CN = "SetGCPSystemSettings"
        Open-GCPSqlConnection -Type MSSQL -CN $CN
        Set-SqlConnection -ConnectionName $CN -CommandTimeout 180
    }
    
    [hashtable]$Changes = @{
        "app\authsalt" = (New-Password -Length 15 -NoSpecialCharacters -NoUpperCase)
        "general\localname" = "Georgia811"
        "general\localnameabbr" = "GA811"
        "schedule\interval" = "2147483647"
        "schedule\activehost" = "none"
        "token\apihost" = $DnsHostName
        "token\protocol" = "https"
        "webclient\default.state" = $script:StateAbbreviation
        "webclient\gis.map" = $script:StateAbbreviation
        "webclient\ticket.personnamestrict" = "false"
        "webclient\welcomeurl" = "/media-custom/welcome.html"
        "email\dns" = "8.8.8.8"
        "logging\level.app" = "INFO"
        "logging\level.core" = "INFO"
        "logging\level.db" = "INFO"
        "logging\level.dns" = "INFO"
        "logging\level.email" = "INFO"
        "logging\level.ftp" = "INFO"
        "logging\level.general" = "INFO"
        "logging\level.gis" = "INFO"
        "logging\level.gisogc" = "INFO"
        "logging\level.http" = "INFO"
        "logging\level.monitors" = "INFO"
        "logging\level.package" = "INFO"
        "logging\level.protusfax" = "INFO"
        "logging\level.proxy" = "INFO"
        "logging\level.queue" = "INFO"
        "logging\level.scheduler" = "INFO"
        "logging\level.security" = "INFO"
        "logging\level.ticket" = "INFO"
        "logging\level.v2bridge" = "INFO"
        "logging\level.watchers" = "INFO"
    }

    if($OverrideHT -and $OverrideHT.Count -gt 0) {
        foreach($key in $OverrideHT.Keys) { $Changes.$key = $OverrideHT.$key }
    }

    Start-SqlTransaction -ConnectionName $CN
    try {
        [string]$query = "UPDATE dbo.SystemSettings SET Value = @value WHERE Category = @category AND Name = @Name"
        foreach($key in $changes.Keys) {
            Invoke-SqlUpdate -ConnectionName $CN -Query $query -Parameters @{value = $changes.$key; category = $key.split("\")[0]; name = $key.split("\")[1]} | Out-Null
        }

        #Adding in mailkit information
        $query = @"
    UPDATE dbo.SystemService SET [SID] = 'http://services.progressivepartnering.com/geocall/2007/10/transmission/handlers/mailkitemail' WHERE ServiceName = 'EmailHandler'

    UPDATE dbo.SystemInstance SET ServiceName = 'MailKitEmailHandler' WHERE InstanceName = 'Email'
    INSERT INTO dbo.SystemInstance (ServiceName, InstanceName, Host, [Path], LoadPriority, IsActive) VALUES  ('MailKitEmailHandler', 'MailKit', '*', '/geocall/api/handlers/MailKit', 201, 1)

    INSERT INTO dbo.SystemInstanceProperty (InstanceName, PropertyName, PropertyValue) VALUES ('MailKit', 'dnsServer', '%(email.dns)%')
    INSERT INTO dbo.SystemInstanceProperty (InstanceName, PropertyName, PropertyValue) VALUES ('MailKit', 'helloName', '%(email.hello)%')
    INSERT INTO dbo.SystemInstanceProperty (InstanceName, PropertyName, PropertyValue) VALUES ('MailKit', 'messageDebugFolder', '%(email.messagedebugfolder)%')
    INSERT INTO dbo.SystemInstanceProperty (InstanceName, PropertyName, PropertyValue) VALUES ('MailKit', 'fromAddress', '%(email.fromaddress)%')
    INSERT INTO dbo.SystemInstanceProperty (InstanceName, PropertyName, PropertyValue) VALUES ('MailKit', 'subject', '%(email.subject)%')
"@
        Invoke-SqlUpdate -ConnectionName $CN -Query $query | Out-Null

        Complete-SqlTransaction -ConnectionName $CN
        if($closeConnection) { Close-SqlConnection -ConnectionName $CN }
    }
    catch {
        Undo-SqlTransaction -ConnectionName $CN
        throw $_
    }
}

Export-ModuleMember -Function Set-GCPSystemSettings