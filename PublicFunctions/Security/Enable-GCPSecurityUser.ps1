<#
.Synopsis
    Enables a deleted GeoCall Security User.

.Description
    Enables a deleted GeoCall Security User, by changing the flag
    'IsDeleted' to 0.

.Parameter Username
    The username to enable.

.Parameter CN
    The SimplySql connection to use, if not specified, the connection is created automatically.

.Parameter ConfigName
    The configuration to use if "CN" is not specified.

#>
function Enable-GCPSecurityUser {
    [cmdletBinding(DefaultParameterSetName="config")]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)][string]$Username
        , [Parameter(Mandatory, ParameterSetName="existing")][Alias("ConnectionName")][string]$CN
        , [Parameter(ParameterSetName="config")][string]$ConfigName = "current"
    )

    begin {
        VerifyConfigName -ConfigName $ConfigName

        [bool]$closeConnection = $false
        if(-not $CN) {
            $cn = "EnableGCPSecurityUser"
            $closeConnection = $true
            Open-GCPSqlConnection -ConfigName $ConfigName -ConnectionName $CN
        }

        [string]$query = "UPDATE dbo.SystemUser SET IsDeleted = 0 WHERE Username = @u"
    }

    process {
        if((Invoke-SqlUpdate -Query $query -Parameters @{u = $UserName}) -eq 0) {
            Write-Error "There is no user '$Username' to undelete!"
        }
    }

    end {
        if($closeConnection) { Close-SqlConnection -ConnectionName $CN }
    }
}

Export-ModuleMember -Function Enable-GCPSecurityUser