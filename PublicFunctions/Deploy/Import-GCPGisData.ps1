<#
.Synopsis
    Loads Spatial data into PostGIS from another database or directory.

.Description
    Loads Spatial data into PostGIS from another database or directory.

    If loading from a directory, the name of the file determines the table to load:
        i.e. gcdefault.dbversion.dat --> gcdefault.dbversion
    
    If loading from another database, this is the table list used:
    Table List
        gcdefault.dbversion
        gcdefault.mapnote
        gcdefault.mapnotecategory
        gcdefault.version
        gcdefault.versionhistory
        gcverbase00001.county
        gcverbase00001.parcel
        gcverbase00001.places
        gcverbase00001.railroads
        gcverbase00001.streets
        gcverbase00001.surfacewater
        gcverbase00001.water        
        gcversa00001.servicearea

.Parameter SrcCN
    SimplySQL Connection Name for Source.

.Parameter DestCN
    SimplySQL Connection Name for Destinatino.

.Parameter TableList
    List of Tables (schemaName.tableName) to pull from source connection.

.Parameter workingDir
    Path to directly with files (schemaName.tableName.dat) to be loaded.

.Parameter DropIndex
    Drop Indexes prior to data loading.
#>
function Import-GCPGisData {
    [cmdletBinding(DefaultParameterSetName="fromdb")]
    param(
        [Parameter(Mandatory, ParameterSetName="fromdb")][Alias("SourceConnectionName")][string]$SrcCN
        , [Parameter()][Alias("DestConnectionName")][string]$DestCN
        , [Parameter(ParameterSetName="fromdb")][string[]]$TableList = @()
        , [Parameter(Mandatory, ParameterSetName="fromdir")][string]$workingDir
        , [Parameter()][switch]$DropIndex
    )

    $ErrorActionPreference = "Stop"
    VerifySimplySql
    [bool]$UseDb = $false
    #Open Destination Connection
    [bool]$closeConnectionDest = $false
    if(-not $DestCN) {
        Write-Verbose "Opening Destination PostGre using GeoCall databases.xml (Open-GCPSqlConnection)."
        $closeConnectionDest = $true
        $DestCN = "ImportGCPGisDataDestination"
        Open-GCPSqlConnection -Type PostGres -CN $DestCN
        Set-SqlConnection -ConnectionName $DestCN -CommandTimeout 900
    }

    if($PSCmdlet.ParameterSetName -eq "fromdb") {
        if($TableList.count -eq 0) {
            [string[]]$TableList = @(
                "gcdefault.dbversion"
                "gcdefault.mapnote"
                "gcdefault.mapnotecategory"
                "gcdefault.version"
                "gcdefault.versionhistory"
                "gcverbase00001.county"
                "gcverbase00001.parcel"
                "gcverbase00001.places"
                "gcverbase00001.railroads"
                "gcverbase00001.streets"
                "gcverbase00001.surfacewater"
                "gcverbase00001.water"            
                "gcversa00001.servicearea"
                "gcversa00001.serviceareatype"
            )
        }
        Write-Verbose "Starting data transfer from source db..."
        $UseDb = $true
    }
    else {
        $TableList = Get-ChildItem -Path $workingDir -File -Filter *.dat | ForEach-Object FullName
        Write-Verbose "Starting data transfer from flat files..."
    }

    #Setting up Hash for index drops
    if($DropIndex) {
    [hashtable]$IndexDrop = @{}
    Invoke-SqlQuery -ConnectionName $DestCN -Query "SELECT schemaname, tablename, indexname FROM pg_indexes WHERE schemaname LIKE 'gc%' and indexname NOT LIKE '%_pkey' AND indexname NOT LIKE 'pk_%'" -Stream |
        ForEach-Object {
            $key = "{0}.{1}" -f $_.schemaname, $_.tablename
            $val = "{0}.{1}" -f $_.schemaname, $_.indexname
            if($IndexDrop.ContainsKey($key)) { $IndexDrop[$key] += ", $val" }
            else { $IndexDrop[$key] = "DROP INDEX $val" }
        }    
    }

    $c = 0
    foreach ($tbl in $TableList ) {
        Write-Progress -Activity "Import-GCPGisData" -PercentComplete (($c + .1) * 100 / $TableList.Count) -Status "$tbl >> Verifying Connections"
        if((Get-SqlConnection -ConnectionName $DestCN).State -ne "Open") {
            Write-Verbose "[$tbl] Re-Opennng Destination '$DestCN'"
            (Get-SqlConnection -ConnectionName $DestCN).Open()
        }
        if($UseDb) {            
            if((Get-SqlConnection -ConnectionName $SrcCN).State -ne "Open") {
                Write-Verbose "[$tbl] Re-Opennng Source '$SrcCN'"
                (Get-SqlConnection -ConnectionName $SrcCN).Open()
            }
        }
        else {
            $fileName, $tbl = $tbl, ((Split-Path -Leaf $tbl) -replace "\.dat")
            [int]$estimate = (Get-Item -Path $fileName).Length
        }
        
        Write-Progress -Activity "Import-GCPGisData" -PercentComplete (($c + .2) * 100 / $TableList.Count) -Status "$tbl >> Clearing Data"
        Write-Verbose ("[$tbl] [{0:HH:mm:ss}] Clearing Table..." -f (Get-Date))
        
        if($DropIndex -and $IndexDrop[$tbl]) { 
            Write-Verbose ("[$tbl] [{0:HH:mm:ss}] Dropping Indexes: {1}" -f (Get-Date), $IndexDrop[$tbl])
            Invoke-SqlUpdate -ConnectionName $DestCN -Query $IndexDrop[$tbl] | Out-Null
        }
        
        try { Invoke-SqlUpdate -Query "TRUNCATE TABLE $tbl" -ConnectionName $DestCN | Out-Null }
        catch { Invoke-SqlUpdate -Query "DELETE FROM $tbl" -ConnectionName $DestCN | Out-Null }

        Write-Progress -Activity "Import-GCPGisData" -PercentComplete (($c + .3) * 100 / $TableList.Count) -Status "$tbl >> Preparing Data Load"
        Write-Verbose ("[$tbl] [{0:HH:mm:ss}] Preparing Data Load..." -f (Get-Date))
        try {
            if($UseDb) { [int]$estimate = Invoke-SqlScalar "SELECT pg_table_size('$tbl')" -ConnectionName $SrcCN }
            [int]$totalSize = 0
            [int]$accumulator = 0
            [int]$accumulatorSize = $estimate / 50
            if($accumulatorSize -lt 1mb) { $accumulatorSize = 1mb }
            if($accumulatorSize -gt 25mb) { $accumulatorSize = 25mb }

            if($UseDb) { [Npgsql.NpgsqlRawCopyStream]$pgSrc = (Get-SqlConnection -ConnectionName $SrcCN).BeginRawBinaryCopy("COPY (SELECT * FROM $tbl) TO STDOUT (FORMAT BINARY)") }
            else { [System.IO.FileStream]$pgSrc = [System.IO.File]::OpenRead($fileName) }
            [Npgsql.NpgsqlRawCopyStream]$pgDest = (Get-SqlConnection -ConnectionName $DestCN).BeginRawBinaryCopy("COPY $tbl FROM STDIN (FORMAT BINARY)")

            $data = New-Object -TypeName 'Byte[]' -ArgumentList 1mb
            Write-Progress -Activity "Import-GCPGisData" -PercentComplete (($c + .3) * 100 / $TableList.Count) -Status "$tbl >> Data Loading"
            Write-Verbose ("[$tbl] [{0:HH:mm:ss}] Loading Data..." -f (Get-Date))
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while($pgSrc.CanRead) {
                $len = $pgSrc.Read($data, 0, $data.Length)
                if($len -eq 0) { break }
                $pgDest.Write($data, 0, $len)
                $totalSize += $len                
                if([math]::Truncate($totalSize / $accumulatorSize) -ge $accumulator) {
                    $accumulator += 1
                    if($totalSize -gt $estimate) { $estimate = $totalSize }
                    $pgDest.Flush()
                    Write-Progress -Activity "Raw Binary Copy" -Status ("{0:#.##}MB out of {1:#.##}MB" -f ($totalSize / 1mb), ($estimate / 1mb)) -PercentComplete ($totalSize * 100 / $estimate) -ParentId 0 -Id 1                    
                }
            }
            Write-Progress -Activity "RawBinaryCopy" -ParentId 0 -Completed -Id 1
            $sw.Stop()
            Write-Verbose ("[$tbl] [{0:HH:mm:ss}] Finished Loading ({1:#.##}MB @ {2:#.##} MB/s)" -f (Get-Date), ($totalSize / 1mb), (($totalSize / 1mb)/$sw.Elapsed.TotalSeconds))
            $sw = $null
        }
        catch { 
            if($closeConnectionDest) { Close-SqlConnection -ConnectionName $DestCN }
            throw $_
        }
        finally {
            if($pgSrc) { $pgSrc.Dispose() }
            if($pgDest) { $pgDest.Dispose() }
        }

        Write-Verbose ("[$tbl] [{0:HH:mm:ss}] Finished" -f (Get-Date))
        $c += 1
    }
    Write-Verbose "Finished data transfer!"
    if($DropIndex) { Write-Warning "Indexes were dropped, run Initialize-GCPPostGresDB to recreate." }
    Write-Progress -Activity "Import-GCPGisData" -Completed

    if($closeConnectionDest) { Close-SqlConnection -ConnectionName $DestCN }
}

Export-ModuleMember -Function Import-GCPGisData