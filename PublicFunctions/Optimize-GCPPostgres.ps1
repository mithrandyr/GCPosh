<#
.Synopsis
    Optimizes the PostGres tables.

.Description
    Optimizes the PostGres tables.
    Performs necessary Vacuum/Analyze/etc commands.

.Parameter SchemaTableName
    follow the format of {Schema}.{Table}

.Parameter ConfigName
    Which configuration to search for db connection, defaults to 'Current'

.Parameter CN
    Which already open SQL Connection to use
#>
function Optimize-GCPPostgres {
    param([Parameter(ParameterSetName="config")]
            [Parameter(ParameterSetName="conn")]
            [ValidateSet("All","County","Places","Railroads","Water","Surfacewater","Streets","Parcel","Mapnote")][string[]]$Tables = "All"
        , [Parameter(ParameterSetName="config")][string]$ConfigName = "Current"
        , [Parameter(Mandatory, ParameterSetName="conn")][Alias("ConnectionName")][string]$CN)
    
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifySimplySql
    
    if($PSCmdlet.ParameterSetName -eq "config") {
        VerifyConfigName -ConfigName $ConfigName
        $cn = "OptimizeGCPPostgres"
        Open-GCPSqlConnection -Type PostGres -ConfigName $ConfigName -ConnectionName $CN
        Set-SqlConnection -ConnectionName $CN -CommandTimeout 600
    }
    
    $items = [ordered]@{
        county = @{Cluster = "six_county"; Schema = "gcverbase00001"}
        places = @{Cluster = "six_places"; Schema = "gcverbase00001"}
        railroads = @{Cluster = "six_railroads"; Schema = "gcverbase00001"}
        water = @{Cluster = "six_water"; Schema = "gcverbase00001"}
        surfacewater = @{Cluster = "six_surfacewater"; Schema = "gcverbase00001"}
        streets = @{Cluster = "six_streets"; Schema = "gcverbase00001"}
        parcel = @{Cluster = ""; Schema = "gcverbase00001"}
        mapnote = @{Cluster = "six_mapnote"; Schema = "gcdefault"}
        servicearea = @{Cluster = "six_servicearea"; Schema = "gcversa00001"}
    }         
    
    [string[]]$tasks = $items.Keys.foreach({
            if($_ -in $tables -or $tables -contains "All") {
                $i = $items[$_]
                $s = $i.schema
                if($i.Cluster) { 
                    "CLUSTER $s.$_ USING {0};" -f $i.Cluster
                    "ANALYZE $s.$_;"
                }
                else { "VACUUM ANALYZE $s.$_;" }
            }
        })
    
    $i = 1
    foreach ($t in $tasks) {
        try {
            Write-Progress -Activity "Optimizing GeoCall PostGres" -Status "Processing Task $i of $($tasks.Count)..." -CurrentOperation "$t" -PercentComplete (($i-1) * 100 / $tasks.count)
            Write-Verbose "QUERY: $t"
            Invoke-SqlUpdate -ConnectionName $CN -Query $t | Out-Null
        }
        catch {
            Write-Warning "ERROR: $t -- $_"
            if((Get-SqlConnection -ConnectionName $CN).State -ne "Open") { (Get-SqlConnection -ConnectionName $CN).Open() }
        }
        $i += 1
    }
    Write-Progress -Activity "Optimizing GeoCall Postgres" -Completed
    
    if($PSCmdlet.ParameterSetName -eq "config") {
        if(Test-SqlConnection -ConnectionName $CN) { Close-SqlConnection -ConnectionName $CN }
    }
}

Export-ModuleMember -Function Optimize-GCPPostgres