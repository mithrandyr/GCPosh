function Set-GCPConfigWeb {
    param(
        [Parameter()][string]$ConfigName = "current"
        , [Parameter(Mandatory)][string]$Title
        , [Parameter()][string]$StateAbbr = $Script:StateAbbreviation
        , [Parameter(Mandatory)][string]$DnsHost
        , [Parameter][switch]$Force
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    $filePath = Join-Path $script:GeoCallPath "Config\$configName\mapstyle\$StateAbbr\web.map"
    if($Force -or (Test-Path $filePath)) {
        Write-Verbose "File: $filePath"
        [string]$template = @"
WEB
    METADATA
        "ows_enable_request"  "*"
        "wms_title"           "$Title"
        "wms_onlineresource"  "https://$DnsHost/geocall/api/gis/ogc/$($StateAbbr)?"
        "wms_srs"             "EPSG:4326 EPSG:3857"
        "wfs_title"           "$Title"
        "wfs_onlineresource"  "https://$DnsHost/geocall/api/gis/features/$StateAbbr/wfs?"
        "wfs_srs"             "EPSG:4326"
        "wfs_namespace_uri"   "https://$DnsHost/geocall/api/gis/features/$StateAbbr/wfs"
    END
END
"@
        if(-not $Force -and (Get-Content -Path $filePath -Raw) -eq $template) { Write-Verbose "File is already up to date, no change." }
        else {
            Set-Content -Path $filePath -Value $template
            Write-Verbose "File has been updated."
        }
    }
    else { throw "Cannot find the file '$filePath'!" }
}

Export-ModuleMember -Function Set-GCPConfigWeb