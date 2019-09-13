function Update-GCPSqlDbCustom {
    param(
        [Parameter()][Alias("ConnectionName")][string]$CN
        , [Parameter()][string]$ConfigName = "current"
        , [Parameter()][switch]$AllowRollback
        , [Parameter()][int]$ConfigVersion = -1
    )
    
    $ErrorActionPreference = "Stop"
    VerifySimplySql
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName
    
    [bool]$closeConnection = $false
    [scriptblock]$ProcessSqlMessages = {
        Param([string]$description, [string]$cn)
        foreach($msg in Get-SqlMessage -ConnectionName $cn) {
            $msg.Message -split "`n" |
                Where-Object { $_ } |
                Where-Object { $_.Trim().Length -gt 0 } |
                ForEach-Object{
                    Write-Warning ("[Update-GCPSqlDbCustom].[{0}].[{1:HH:mm:ss}) {2}" -f $description, $msg.Received, $_.Trim())
                }
        }
    }

    if(-not $CN) {
        $cn = "UpdateGCPSqlDbCustom"
        Open-GCPSqlConnection -Type MSSQL -ConfigName $ConfigName -ConnectionName $cn
        $closeConnection = $true
    }

    # Initialization
    Write-Progress -Activity "Sql Database Customizations" -Status "Initialization" -CurrentOperation "Verifying Schema 'custom'"
    if([bool](Invoke-SqlScalar -ConnectionName $cn -Query "SELECT CASE WHEN NOT EXISTS (SELECT * FROM sys.schemas WHERE [name] = 'custom') THEN 1 ELSE 0 END")) {
        Write-Progress -Activity "Sql Database Customizations" -Status "Initialization" -CurrentOperation "Creating Schema 'custom'..."
        Invoke-SqlUpdate -ConnectionName $cn -Query "CREATE SCHEMA custom" | Out-Null

        Write-Progress -Activity "Sql Database Customizations" -Status "Initialization" -CurrentOperation "Creating Table 'custom.VersionHistory'..."
        Invoke-SqlUpdate -ConnectionName $cn -Query "CREATE TABLE custom.VersionHistory (VersionNumber INT PRIMARY KEY, ApplyDate datetime NOT NULL, RollBackSQL VARCHAR(max) NULL)" | Out-Null
        Invoke-SqlUpdate -ConnectionName $cn -Query "INSERT INTO custom.VersionHistory(VersionNumber, ApplyDate) VALUES (0, @dt)" -Parameters @{dt=(Get-Date)} | Out-Null
    }

    # Applying Customizations
    Write-Progress -Activity "Sql Database Customizations" -Status "Selecting Updates" -CurrentOperation "Getting current version..."
    [int]$DBVersion = Invoke-SqlScalar -ConnectionName $cn -Query "SELECT TOP 1 VersionNumber FROM custom.VersionHistory ORDER BY VersionNumber DESC"
        
    # Verify that database is not farther ahead of configuration
    if($configVersion -lt 0) {
        [int]$configVersion = Get-ChildItem -Path (Join-Path $script:GeoCallPath "Config\$ConfigName\CustomData\SqlDb") -Filter "*-process.sql" -File -Recurse | 
            ForEach-Object { [int]($_.BaseName.Split("-")[0]) } |
            Sort-Object -Descending |
            Select-Object -First 1
    }
    else { 
        Write-Warning "Forcing the ConfigVersion to $configVersion."
    }

    if($configVersion -lt $DBVersion) {
        if(-not $AllowRollback) { throw "Configuration is behind the database!" }
        else { #RollBack Logic
            Write-Host "Rolling back Custom DB Versions..."
            $rollbackData = Invoke-SqlQuery -ConnectionName $cn -Query "SELECT RollBackSQL, VersionNumber FROM custom.VersionHistory WHERE VersionNumber > @vn ORDER BY VersionNumber DESC" -Parameters @{vn = $configVersion} -Stream
            
            foreach($rbd in $rollbackData) {
                $rollbackVN = $rbd.VersionNumber
                $VersionTitle = "Version #{0}" -f $rollbackVN
                if(-not $rbd.RollBackSql) { $SqlBatches = @() }
                else { $SqlBatches = $rbd.RollBackSql | ParseSql }
                Write-Progress -Activity "Sql Database Rollback" -Status $VersionTitle -CurrentOperation "Starting SQL Transaction..."   
                Start-SqlTransaction -ConnectionName $cn
                try {
                    $c = 1
                    foreach($sql in $SqlBatches) {
                        if($SqlBatches.count -eq 1) { Write-Progress -Activity "Sql Database Rollback" -Status $VersionTitle -CurrentOperation "Executing SQL..." }
                        else { Write-Progress -Activity "Sql Database Rollback" -Status $VersionTitle -CurrentOperation "Executing $c of  $($SqlBatches.Count)..." }
                        Invoke-SqlUpdate -ConnectionName $cn -Query $sql | Out-Null
                    }

                    $ProcessSqlMessages.Invoke("Rollback #$rollbackVN", $cn)

                    Invoke-SqlUpdate -ConnectionName $cn -Query "DELETE FROM custom.VersionHistory WHERE VersionNumber = @vn" -Parameters @{vn = $rollbackVN} | Out-Null
                    Complete-SqlTransaction -ConnectionName $cn
                    Write-Host "-- Rolled back #$rollbackVN"
                }
                catch {
                    $ProcessSqlMessages.Invoke("Rollback (err)", $cn)
                    Undo-SqlTransaction -ConnectionName $cn
                    Write-Warning "Failed to rollback '$VersionTitle'"
                    throw $_
                }
            }
        }
    }
    elseif($configVersion -eq 0) { Write-Verbose "No SqlDB configuration!" }
    else { # Process Logic
        Write-Host "Applying Custom DB Versions..."
        # determine the earliest version of the block to be processed (to account for skipped versions)
        $VersionNumberBlock = [math]::round(($ConfigVersion - 5) / 10, [System.MidpointRounding]::AwayFromZero) * 10
        if($VersionNumberBlock -gt $DBVersion) { $VersionNumberBlock = $DBVersion } #if DB version is before the block, start at DBVersion
        
        # Get Files to process
        Write-Progress -Activity "Sql Database Customizations" -Status "Selecting Updates" -CurrentOperation "Getting files to process..."
        $Versions = Get-ChildItem -Path (Join-Path $script:GeoCallPath "Config\$ConfigName\CustomData\SqlDb") -Filter "*-process.sql" -File -Recurse |
            ForEach-Object {
                [PSCustomObject]@{
                    Version = [int]($_.BaseName.Split("-")[0])
                    ProcessPath = $_.FullName
                    RollBackPath = $_.FullName -replace [regex]::Escape("-process.sql"), "-rollback.sql"
                }
            } |
            Where-Object { $_.Version -ge $VersionNumberBlock -and $_.Version -le $ConfigVersion} |
            Sort-Object Version
        
        # Process each File
        ForEach($v in $Versions) {
            $VersionTitle = "Version #{0}" -f $v.Version
            if($v.Version -le $DBVersion) {
                if([bool](Invoke-SqlScalar -ConnectionName $cn -Query "SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM custom.VersionHistory WHERE VersionNumber = @vn) THEN 1 ELSE 0 END" -Parameters @{vn = $v.Version})) {
                    Write-Warning "Processing Skipped $VersionTitle..."
                }
                else {
                    Write-Verbose "No need to process $VersionTitle, already exists."
                    continue #skip to next item, this one already exists!
                }
            }
            
            Write-Progress -Activity "Sql Database Customizations" -Status "Processing Updates" -CurrentOperation "$VersionTitle..."
            $SqlBatches = Get-Content -Path $v.ProcessPath | ParseSql

            Write-Progress -Activity "Sql Database Customizations" -Status $VersionTitle -CurrentOperation "Starting SQL Transaction..."
            Start-SqlTransaction -ConnectionName $cn
            try {
                $c = 1
                Invoke-SqlUpdate -ConnectionName $cn -Query "INSERT INTO custom.VersionHistory(VersionNumber, ApplyDate) VALUES (@vn, @ad)" -Parameters @{vn = $v.Version; ad = (Get-Date)} | Out-Null
                if(Test-Path $v.RollBackPath) {
                    Invoke-SqlUpdate -ConnectionName $cn -Query "UPDATE custom.VersionHistory SET RollBackSQL = @rbs WHERE VersionNumber = @vn" -Parameters @{vn = $v.Version; rbs = (Get-Content $v.RollBackPath -Raw)} | Out-Null
                }
                foreach($sql in $SqlBatches) {
                    if($SqlBatches.count -eq 1) { Write-Progress -Activity "Sql Database Customizations" -Status $VersionTitle -CurrentOperation "Executing SQL..." }
                    else { Write-Progress -Activity "Sql Database Customizations" -Status $VersionTitle -CurrentOperation "Executing $c of  $($SqlBatches.Count)..." }
                    Invoke-SqlUpdate -ConnectionName $cn -Query $sql | Out-Null
                }
                $ProcessSqlMessages.Invoke("Process #$($v.Version)", $cn)

                Complete-SqlTransaction -ConnectionName $cn
                Write-Host "-- Applied #$($v.Version)"
            }
            catch {
                $ProcessSqlMessages.Invoke("Process (err)", $cn)
                Undo-SqlTransaction -ConnectionName $cn
                Write-Warning "Failed to apply '$VersionTitle'"
                if($sql) { Write-Warning "SQL: $sql" }
                throw $_                
            }
        }
    }
    Write-Host ("Custom Database Version is {0}" -f (Invoke-SqlScalar -ConnectionName $cn -Query "SELECT MAX(VersionNumber) FROM Custom.VersionHistory"))
    Write-Progress -Activity "Sql Database Customizations" -Completed
    if($closeConnection) { Close-SqlConnection -ConnectionName $cn }
}

Export-ModuleMember -Function Update-GCPSqlDbCustom