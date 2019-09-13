function Open-GCPSqlConnection {
    param([Parameter()][ValidateSet("MSSQL","PostGres")][string]$Type = "MSSQL"
        , [Parameter()][string]$ConfigName = "Current"
        , [Parameter()][Alias("ConnectionName")][string]$CN = "default")

    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifySimplySql
    VerifyConfigName -ConfigName $ConfigName

    [string]$filePath = Join-Path $script:GeoCallPath "Config\$ConfigName\databases.xml"
    if(-not (Test-Path $filePath)) { throw "Cannot find the file '$filePath'!" }

    $xmlData = [xml](Get-Content -Path $filePath -Raw)

    if($Type -eq "MSSQL") {
        $node = $xmlData.databaseConfigurations.databaseConfiguration.where({$_.key -eq "geocallappdb"})
        Open-SqlConnection -Server $node.server -Database $node.database -Credential ([pscredential]::new($node.user, (ConvertTo-SecureString -String $node.password -AsPlainText -Force))) -ConnectionName $CN
    }
    elseif($type -eq "PostGres") {
        $node = $xmlData.databaseConfigurations.databaseConfiguration.where({$_.key -like "GeoCallGisDb-*"})
        Open-PostGreConnection -Server $node.server -Database $node.database -Credential ([pscredential]::new($node.user, (ConvertTo-SecureString -String $node.password -AsPlainText -Force))) -ConnectionName $CN
    }
    else {
        throw "Invalid type ($Type)!"
    }
}

Export-ModuleMember -Function Open-GCPSqlConnection