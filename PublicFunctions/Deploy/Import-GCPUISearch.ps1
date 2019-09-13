<#
.Synopsis
    Processes the 'UI-Search' folder and adds missing searches to the database.

.Description
    Processes the 'UI-Search' folder and adds missing searches to the database.
    Leverages Open-GCPSqlConnection if no ConnectionName is passed.
    Will output the results if -ShowDetails is specified.

.Parameter ConfigName
    Which configuration to use.

.Parameter CN
    Which SimplySql Connection Name to use, if not specified
    the cmdlet will automatically create one (Open-GCPSqlConnection)
    with the name 'ImportGCPUISearch'.

.Parameter ShowDetails
    This will output a result for each file Present or Added.
#>
function Import-GCPUISearch {
    Param(
        [Parameter()][string]$ConfigName = "current"
        , [Parameter()][Alias("ConnectionName")][string]$CN
        , [switch]$ShowDetails
    )
    $ErrorActionPreference = "Stop"
    [bool]$CloseConn = $false
    [bool]$hasErrors = $false
    
    VerifySimplySql
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    if(-not $CN) {
        $cn = "ImportGCPUISearch"
        Open-GCPSqlConnection -Type MSSQL -ConfigName $ConfigName -ConnectionName $cn
        $CloseConn = $true
    }

    [string]$query = "SELECT sf.FeatureId
            , sf.[Name]
            , sf.Category
            , sf.[Description]
            , sp.Code
            , sp.[Description] AS FeatureLink
        FROM SystemFeature AS sf
            INNER JOIN SystemFeaturePermission AS sfp
                On sf.FeatureId = sfp.FeatureId
            INNER JOIN SystemPermission AS sp
                ON sfp.PermissionId = sp.PermissionId
        WHERE sf.Category = 'search'
            AND sf.FeatureId > 10000000
            AND sp.Code = @security"

    [string]$insert = "DECLARE @id AS bigint
        SET @id = (SELECT MAX(PermissionId) + 1 FROM dbo.SystemPermission)
        SET @id = (SELECT CASE WHEN @id > MAX(FeatureId) + 1 THEN @id ELSE MAX(FeatureID) + 1 END FROM dbo.SystemFeature)
        IF @id < 10000001 SET @ID = 10000001
        
        INSERT INTO dbo.SystemPermission (PermissionId, Code, Category, [Description]) VALUES (@id, @Code, 'Search', @Link)
        INSERT INTO dbo.SystemFeature (FeatureId, [Name], Category, [Description]) VALUES (@id, @Link, 'Search', @Description)
        INSERT INTO dbo.systemfeaturepermission (FeatureId, PermissionId) VALUES (@id, @id)"

    [string]$UIPath = (Join-Path $script:GeoCallPath "Config\$configName\ui-search\")
    [string[]]$filePaths = Get-ChildItem $UIPath -Filter *.xml -File | Select-Object -ExpandProperty FullName
    [int]$c = 0
    $results = @()

    foreach ($f in $filePaths) {
        $c += 1
        Write-Progress -Activity "Import-GCPUISearch" -Status $f -PercentComplete ($c * 100 / $filePaths.Count)

        try {
            Start-SqlTransaction -ConnectionName $CN
            $fileData = [xml](Get-Content $f -Raw) | Select-Object -ExpandProperty search | Select-Object key, security, category, name, description
            $dbData = Invoke-SqlQuery -ConnectionName $cn -Query $query -Parameters @{security = $fileData.security} -Stream

            if($dbData) {
                if($dbData.Description -ne $fileData.description -or
                    $dbData.FeatureLink -ne ("{0} - {1}" -f $fileData.category, $fileData.name) -or
                    $dbData.Name -ne ("{0} - {1}" -f $fileData.category, $fileData.name)) {
                    $results += [PSCustomObject]@{FileName = $f; Reference = $fileData.Security; Status = "Modified"}
                }
                else { $results += [PSCustomObject]@{FileName = $f; Reference = $fileData.Security; Status = "Present"} }                
            }
            else {
                Invoke-SqlUpdate -ConnectionName $CN -Query $insert -Parameters @{
                        Code = $fileData.security
                        Link = "{0} - {1}" -f $fileData.category, $fileData.name
                        Description = $fileData.description
                    } | Out-Null
                $results += [PSCustomObject]@{FileName = $f; Reference = $fileData.Security; Status = "Added"}
            }
            Complete-SqlTransaction -ConnectionName $CN
        }
        catch {
            $hasErrors = $true
            Write-Warning "There was an issue processing the file = '$f'."
            Write-Warning "ERROR: $_"
            $results += [PSCustomObject]@{FileName = $f; Reference = $_; Status = "Error"}
            Undo-SqlTransaction -ConnectionName $CN
        }
    }

    #Update Admin (user) & Administrator (role) to have all "Search" permissions.
    Invoke-SqlUpdate -ConnectionName $cn -Query "INSERT INTO dbo.SystemRolePermission(PermissionId, RoleId)
            SELECT sp.PermissionId, sr.RoleId
            FROM dbo.SystemPermission AS sp
                CROSS JOIN dbo.SystemRole AS sr
            WHERE sp.Category = 'Search'
                AND sr.RoleName = 'Administrator'
                AND NOT EXISTS (SELECT 1 FROM dbo.SystemRolePermission AS srp
                                WHERE sp.PermissionId = srp.PermissionId
                                    AND sr.RoleId = srp.RoleId)

        INSERT INTO dbo.SystemUserPermission(PermissionId, UserId)
            SELECT sp.PermissionId, su.UserId
            FROM dbo.SystemPermission AS sp
                CROSS JOIN dbo.SystemUser AS su
            WHERE sp.Category = 'Search'
                AND su.Username = 'Admin'
                AND NOT EXISTS (SELECT 1 FROM dbo.SystemUserPermission AS sup
                                WHERE sp.PermissionId = sup.PermissionId
                                    AND su.UserId = sup.UserId)" | Out-Null

    if($ShowDetails) { $results }

    if($hasErrors) { throw "Errors in processing xml files, check warnings and/or error history." }
    
    if($CloseConn) { Close-SqlConnection -ConnectionName $cn }
}

Export-ModuleMember -Function Import-GCPUISearch