function Set-GCPConfigDatabase {
    param(
        [Parameter()][string]$ConfigName = "current"
        , [Parameter(Mandatory)][string]$SqlServerName
        , [Parameter(Mandatory)][string]$SqlDbName
        , [Parameter(Mandatory)][string]$SqlUserName
        , [Parameter(Mandatory)][string]$SqlUserPass
        , [Parameter(Mandatory)][string]$PgServerName
        , [Parameter(Mandatory)][string]$PgDbName
        , [Parameter(Mandatory)][string]$PgUserName
        , [Parameter(Mandatory)][string]$PgUserPass
        , [Parameter()][string]$SqlTimeZone = [System.TimeZone]::CurrentTimeZone.StandardName
        , [Parameter()][hashtable]$SqlProperties = @{}
        , [Parameter()][hashtable]$PgProperties = @{"db.ConnectionEx"=";CommandTimeout=300;sslmode=prefer"}
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    [string]$filePath = Join-Path $script:GeoCallPath "Config\$ConfigName\databases.xml"
    if(-not (Test-Path $filePath)) { throw "Cannot find the file '$filePath'!" }
    if($SqlTimeZone) {
        $SqlProperties."db.GetDateSql" = "DATEADD(MINUTE,DATEPART(TZOFFSET,(GETUTCDATE() AT TIME ZONE '{0}')),GETUTCDATE())" -f $SqlTimeZone
    }

    $xmlData = [xml](Get-Content -Path $filePath -Raw)
    foreach($node in $xmlData.databaseConfigurations.databaseConfiguration) {
        Write-Verbose "Updating $($node.key)..."
        if($node.key -like "GeoCallGisDb-*") {
            #Postgresql/PostGIS node
            Write-Verbose "Node-Pg: $($node.key)"
            $node.server = $PgServerName
            $node.database = $PgDbName
            $node.user = $PgUserName
            $node.password = $PgUserPass

            foreach($key in $PgProperties.keys){
                $node.properties.property.where({$_.name -eq $key})[0].value = $PgProperties.$key
            }
        }
        else {
            #SQL Node
            Write-Verbose "Node-Sql: $($node.key)"
            $node.provider = "sqlServer4.0"
            $node.server = $SqlServerName
            $node.database = $SqlDbName
            $node.user = $SqlUserName
            $node.password = $SqlUserPass

            foreach($key in $SqlProperties.keys){
                $node.properties.property.where({$_.name -eq $key})[0].value = $SqlProperties.$key
            }
        }
    }

    $xmlData.Save($filePath)
}

Export-ModuleMember -Function Set-GCPConfigDatabase