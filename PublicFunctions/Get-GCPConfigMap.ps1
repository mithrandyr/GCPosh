function Get-GCPConfigMap {
    param([Parameter()][string]$ConfigName = "current")
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName
    [string]$filePath = Join-Path $script:GeoCallPath "Config\$ConfigName\maps.xml"
    if(-not (Test-Path $filePath)) { throw "Cannot find the file '$filePath'!" }

    $xmlData = [xml](Get-Content -Path $filePath -Raw)

    @{
        StateAbbr = $xmlData.gis.map.name
        MapDataPath = $xmlData.gis.map.mapoutputfolder
        MapCachePath = $xmlData.gis.map.settings.cache.property.where({$_.name -eq "cacheLocation"})[0].value
        IsDebug = [bool]::Parse($xmlData.gis.map.debug)
    }
}
Export-ModuleMember -Function Get-GCPConfigMap