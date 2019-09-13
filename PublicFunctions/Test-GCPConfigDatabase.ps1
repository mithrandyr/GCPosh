function Test-GCPConfigDatabase {
    param([Parameter()][string]$ConfigName = "current")
    
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifySimplySql
    VerifyConfigName -ConfigName $ConfigName

    [string]$filePath = Join-Path $script:GeoCallPath "Config\$ConfigName\databases.xml"
    if(-not (Test-Path $filePath)) { throw "Cannot find the file '$filePath'!" }

    [string]$cn = "VerifyGCPConfigDatabase"
    $xmlData = [xml](Get-Content -Path $filePath -Raw)
    foreach($node in $xmlData.databaseConfigurations.databaseConfiguration) {
        Write-Host "Verifying $($node.key)..." -NoNewline
        if($node.key -like "GeoCallGisDb-*") {
            #Postgresql/PostGIS node
            try {
                Open-PostGreConnection -ConnectionName $cn -Server $node.server -Database $node.database -UserName $node.user -Password $node.password -WarningAction SilentlyContinue
                Write-Host "Success (Postgres)!" -ForegroundColor Green
            }
            catch {
                Write-Host "Failure (Postgres)!" -ForegroundColor Red
                Write-Host $_
            }
            if(Test-SqlConnection -ConnectionName $cn) { Close-SqlConnection -ConnectionName $cn }
        }
        else {
            #SQL Node
            try {
                Open-SqlConnection -ConnectionName $cn -Server $node.server -Database $node.database -UserName $node.user -Password $node.password -WarningAction SilentlyContinue
                Write-Host "Success (SqlServer)!" -ForegroundColor Green
            }
            catch {
                Write-Host "Failure (SqlServer)!" -ForegroundColor Red
                Write-Host $_
            }
            if(Test-SqlConnection -ConnectionName $cn) { Close-SqlConnection -ConnectionName $cn }
        }
    }
}

Export-ModuleMember -Function Test-GCPConfigDatabase