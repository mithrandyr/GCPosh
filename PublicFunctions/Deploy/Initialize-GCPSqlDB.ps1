function Initialize-GCPSqlDb {
    [cmdletBinding(DefaultParameterSetName="default")]
    param(
        [Parameter()][string]$ConfigName = "current"
        , [Parameter()][Alias("ConnectionName")][string]$CN
        , [Parameter()][string]$TimeZone = [System.TimeZone]::CurrentTimeZone.StandardName
        , [Parameter(ParameterSetName="default")][switch]$SkipInitScripts
        , [Parameter(Mandatory, ParameterSetName="dateonly")][switch]$UpdateDateFieldDefaultsOnly
    )
    $ErrorActionPreference = "Stop"
    VerifySimplySql
    [bool]$closeConnection = $false

    if(-not $CN) {
        VerifyGCPosh
        VerifyConfigName -ConfigName $ConfigName

        $closeConnection = $true
        $CN = "InitializeGCPGeoCallSqlDb"
        Open-GCPSqlConnection -Type MSSQL -CN $CN
        Set-SqlConnection -ConnectionName $CN -CommandTimeout 180
    }

    if(-not $UpdateDateFieldDefaultsOnly) {
        if(-not $SkipInitScripts) {
            [string]$verifyEmptyDb = "SELECT 1 FROM sys.tables WHERE schema_id = schema_id('dbo')"
            if(Invoke-SqlScalar -ConnectionName $CN -Query $verifyEmptyDb) { throw "Database must be empty (no tables in dbo schema) to run!"}

            [string[]]$sqlFileList =  @(
                "geocall-v3-app-init.sql"
                ,"geocall-v3-coresystem-init.sql"
                ,"geocall-v3-log-init.sql"
                ,"geocall-v3-media.sql"
                ,"geocall-v3-permissions.sql"
                ,"geocall-v3-suspsendedrecord.sql"
                ,"geocall-v3-tx-init.sql"
            )
            $files = Get-ChildItem (Join-Path $script:GeoCallPath "production\current\support\dbscripts\mssql\init\*") -Include $sqlFileList
            [int]$c = 0
            foreach($file in $files) {
                [string]$fileData = Get-Content -Raw -Path $file.FullName
                
                #adding fix for geocall-v3-suspendedrecord.sql file
                if($file.name -eq "geocall-v3-suspsendedrecord.sql") { $filedata = $fileData.Replace('${sqltokenbigint}','BIGINT') }

                Write-Progress -Activity "Configuring Sql Database" -Status "Running Init Scripts" -CurrentOperation $file -PercentComplete ($c / $files.count)
                Invoke-SqlUpdate -Query $fileData -ConnectionName $cn -ErrorAction Stop | Out-Null
                $c += 100
            }
        }

        #Convert TEXT to varchar(max)
        #https://progressivepartnering.atlassian.net/wiki/spaces/GEOC/pages/57609254/Convert+text+Database+Type+To+varchar+max
        [string]$query = "SELECT OBJECT_SCHEMA_NAME([object_id]) AS SchemaName
                , OBJECT_NAME([object_id]) AS TableName
                , [name] AS ColumnName
            FROM sys.columns
            WHERE system_type_id = 35 AND object_schema_name(object_id) = 'dbo'"
        $data = Invoke-SqlQuery -Query $query -ConnectionName $CN -Stream
        [int]$c = 0
        foreach($d in $data) {
            $query = "ALTER TABLE [{0}].[{1}] ALTER COLUMN [{2}] varchar(max)" -f $d.SchemaName, $d.TableName, $d.ColumnName
            Write-Progress -Activity "Configuring Sql Database" -Status "Changing TEXT columns to VARCHAR(max)" -CurrentOperation $query -PercentComplete ($c / $data.count)
            Invoke-SqlUpdate -ConnectionName $CN -Query $query -ErrorAction Stop | Out-Null
            $c += 100
        }

        <#
        #https://progressivepartnering.atlassian.net/wiki/spaces/GEOC/pages/32473092/Time+Zones+Databases.xml+and+Sequence+Numbers
        dbo.ticket_GetNextSequence_Serial -- create/replace/etc
        Lets use the SQL SERVER Sequence object instead!!!!
            https://docs.microsoft.com/en-us/sql/t-sql/statements/create-sequence-transact-sql
        #>
        Write-Progress -Activity "Configuring Sql Database" -Status "Configuring Ticket Numbers" -CurrentOperation "Creating Sequence (if not exist)..."
        [string]$query = "IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE [name] = 'seq_TicketSequence' AND schema_id = schema_id('dbo')) CREATE SEQUENCE dbo.seq_TicketSequence AS BIGINT START WITH 1000000000 INCREMENT BY 1 MINVALUE 10000000 MAXVALUE 9999999999 NO CYCLE CACHE 5"
        Invoke-SqlUpdate -ConnectionName $CN -ErrorAction Stop -Query $query | Out-Null

        Write-Progress -Activity "Configuring Sql Database" -Status "Configuring Ticket Numbers" -CurrentOperation "Creating Stored Procedure (if not exist)..."
        [string]$query = "SELECT 1 FROM sys.procedures WHERE [name] = 'Ticket_GetNextSequence_Serial' AND schema_id = schema_id('dbo')"
        if(-not (Invoke-SqlScalar -ConnectionName $CN -Query $query -ErrorAction STOP)) {
            [string]$query = "CREATE PROCEDURE [dbo].[Ticket_GetNextSequence_Serial] (@SeqNo bigint output, @Julian bigint output) AS SET @SeqNo = NEXT VALUE FOR dbo.seq_TicketSequence; SET @Julian = 0"
            Invoke-SqlUpdate -ConnectionName $CN -ErrorAction Stop -Query $query | Out-Null
        }
    }

    #update default fields
    #https://progressivepartnering.atlassian.net/wiki/spaces/GEOC/pages/60653570/SQL+Azure+Database+Transition+Steps
    [string]$query = "SELECT OBJECT_SCHEMA_NAME(c.[object_id]) AS SchemaName
            , OBJECT_NAME(c.[object_id]) AS TableName
            , c.[name] AS ColumnName
            , dc.[name] AS ConstraintName
        FROM sys.default_constraints AS dc
            INNER JOIN sys.columns AS c
                ON dc.parent_object_id = c.[object_id]
                    AND dc.parent_column_id = c.column_id
        WHERE [type] = 'D'
            AND c.system_type_id = 61
            AND OBJECT_SCHEMA_NAME(c.[object_id]) = 'dbo'"
    $data = Invoke-SqlQuery -Query $query -ConnectionName $CN -Stream
    if(-not (Invoke-SqlScalar -ConnectionName $CN -Query "SELECT 1 FROM sys.time_zone_info WHERE [name] = @n" -Parameters @{n=$TimeZone} -ErrorAction Stop)) {
        throw "Invalid TimeZone specified '$TimeZone'!"
    }
    [string]$constraintDefinition = "DATEADD(MINUTE,DATEPART(TZOFFSET,(GETUTCDATE() AT TIME ZONE '{0}')),GETUTCDATE())" -f $TimeZone
    [int]$c = 0
    foreach($d in $data) {
        $query = "ALTER TABLE [{0}].[{1}] DROP CONSTRAINT [{2}]" -f $d.SchemaName, $d.TableName, $d.ConstraintName
        Write-Progress -Activity "Configuring Sql Database" -Status "Updating DateTime column default SQL to TZ specific SQL" -CurrentOperation $query -PercentComplete ($c / ($data.count * 2))
        Invoke-SqlUpdate -ConnectionName $CN -Query $query -ErrorAction Stop | Out-Null
        $c += 100

        $query = "ALTER TABLE [{0}].[{1}] ADD CONSTRAINT [{2}] DEFAULT ({3}) FOR [{4}]" -f $d.SchemaName, $d.TableName, $d.ConstraintName, $constraintDefinition, $d.ColumnName
        Write-Progress -Activity "Configuring Sql Database" -Status "Updating DateTime column default SQL to TZ specific SQL" -CurrentOperation $query -PercentComplete ($c / ($data.count * 2))
        Invoke-SqlUpdate -ConnectionName $CN -Query $query -ErrorAction Stop | Out-Null

        $c += 100
    }

    Write-Progress -Activity "Configuring Sql Database" -Completed
    if($closeConnection) { Close-SqlConnection -ConnectionName $CN }
}

Export-ModuleMember -Function Initialize-GCPSqlDb