<#
.Synopsis
    GCHost ResetPassword & ResetAdminPerms

.Description
    Allows resetting the password for the admin account and resetting
    the permissions for the admin account to everything.

.Parameter AdminPW
    The password you want to set the 'admin' account to.

.Parameter ResetPermissions
    Resets the 'admin' account to have all permissions.
#>
function Set-GCPAdmin {
    [cmdletBinding()]
    param([parameter()][ValidateNotNull()][string]$AdminPW
        , [switch]$ResetPermissions
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyGeoCallDeployed

    if($AdminPW) { RunGCHost /rm:command /c:resetpassword /rpu:admin /rpp:$AdminPW }
    if($ResetPermissions) { RunGCHost /rm:command /c:resetadminperms }
}

Export-ModuleMember -Function Set-GCPAdmin