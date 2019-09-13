function Initialize-GCPPostgresDb {
    param(
        [Parameter()][string]$ConfigName = "current"
        , [Parameter()][Alias("ConnectionName")][string]$CN
        , [Parameter()][switch]$IndexOnly
    )
    $ErrorActionPreference = "Stop"
    VerifySimplySql
    [bool]$closeConnection = $false

    if(-not $CN) {
        VerifyGCPosh
        VerifyConfigName -ConfigName $ConfigName

        $closeConnection = $true
        $CN = "InitializeGCPPostgresDb"
        Open-GCPSqlConnection -Type PostGres -CN $CN
    }
    
    Set-SqlConnection -ConnectionName $CN -CommandTimeout 1800
    $files = @()
    if($IndexOnly) { $files += Get-ChildItem -Path "$PSScriptRoot\..\..\PostgresFiles" -File -Filter "*index*.sql" }
    else { $files += Get-ChildItem -Path "$PSScriptRoot\..\..\PostgresFiles" -File -Filter "*.sql" }
    [string[]]$queries = @()
    [int]$c = 0
    foreach($file in $files) {
        Write-Progress -Activity "Configuring Postgres Database" -Status "Reading Script files..." -CurrentOperation $file.BaseName -PercentComplete ($c / $files.count)
        if($file.name -notlike "*-*") { $queries += Get-Content -Raw -Path $file.FullName -ErrorAction Stop }
        else { $queries += Get-Content -Path $file.FullName -ErrorAction Stop -Delimiter ";" | ForEach-Object { $_.trim() } }
        $c += 100
    }

    [int]$c = 0
    foreach($query in $queries) {
        Write-Progress -Activity "Configuring Postgres Database" -Status "Executing Scripts..." -CurrentOperation $query -PercentComplete ($c / $queries.count)
        Write-Verbose ("[{0:HH:mm:ss}] QUERY: {1}" -f (Get-Date), $(if($query.length -gt 80) { $query.Substring(0, 80) } else { $query }))
        Invoke-SqlUpdate -ConnectionName $CN -Query $query -ErrorAction Stop | Out-Null
        $c += 100
    }
    Write-Progress -Activity "Configuring Postgres Database" -Completed
    if($closeConnection) { Close-SqlConnection -ConnectionName $CN }
    Write-Verbose ("[{0:HH:mm:ss}] Finished" -f (Get-Date))
}

Export-ModuleMember -Function Initialize-GCPPostgresDb