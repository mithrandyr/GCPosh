function Restore-GCPConfiguration {
    Param(
        [Parameter()][string]$ConfigName = "current"
        , [Parameter(Mandatory)][string]$ArchivePath
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    [string]$configFolder = Join-Path $script:GeoCallPath "\config\$ConfigName\"
    if(-not (Test-Path $ArchivePath)) { throw "Can't find the archive at '$ArchivePath'!" }
    Expand-Archive -Path $ArchivePath -DestinationPath $configFolder -Force
}

Export-ModuleMember -Function Restore-GCPConfiguration