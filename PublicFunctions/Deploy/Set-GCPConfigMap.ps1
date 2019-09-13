function Set-GCPConfigMap {
    param([Parameter()][string]$ConfigName = "current"
        , [Parameter()][string]$StateAbbr = $Script:StateAbbreviation
        , [Parameter()][string]$MapDataPath = (Join-Path $script:GeoCallPath "MapData\$script:StateAbbreviation\")
        , [Parameter()][string]$MapCachePath = (Join-Path $script:GeoCallPath "mapcache")
        , [Parameter()][switch]$IsDebug
        , [Parameter()][switch]$CreateFolders
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    [string]$filePath = Join-Path $script:GeoCallPath "Config\$ConfigName\maps.xml"
    if(-not (Test-Path $filePath)) { throw "Cannot find the file '$filePath'!" }

    $xmlData = [xml](Get-Content -Path $filePath -Raw)
    [string]$mapCacheStatePath = Join-Path $MapCachePath $script:StateAbbreviation

    #create paths for the folders
    $MapDataPath, $MapCachePath, $mapCacheStatePath |
        Where-Object { -not (Test-Path $_) } |
        ForEach-Object { 
                if($CreateFolders) { New-Item -Path $_ -ItemType Directory -Force }
                else { Write-Warning "Folder does not exist at '$_'" }
            } |
        Out-Null

    $xmlData.gis.map.name = $StateAbbr
    $xmlData.gis.map.debug = $IsDebug.IsPresent.ToString().ToLower()
    $xmlData.gis.map.mapoutputfolder = $MapDataPath
    $xmlData.gis.map.settings.cache.property.where({$_.name -eq "cacheLocation"})[0].value = $MapCachePath

    $xmlData.Save($filePath)
}

Export-ModuleMember -Function Set-GCPConfigMap