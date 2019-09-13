function Backup-GCPConfiguration {
    Param(
        [Parameter()][string]$ConfigName = "current"
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    [string]$archiveFolder = Join-Path ([System.IO.Path]::GetTempPath()) "GeoCall-$ConfigName-Backup"
    [string]$archivePath = Join-Path ([System.IO.Path]::GetTempPath()) "GeoCall-$ConfigName-Backup.zip"
    [string]$configFolder = Join-Path $script:GeoCallPath "\config\$ConfigName\"
    [string[]]$filesToArchive = @(
        "databases.xml"
        "host-config.json"
        #"maps.xml" #use Get-GCPConfigMap and Set-GCPConfigMap to persist environment settings between pushes
        "security-tokens.txt"
        "mapstyle\$script:StateAbbreviation\web.map"
    )

    if(Test-Path $archiveFolder) { Remove-Item $archiveFolder -Recurse -Force }
    New-Item -Path $archiveFolder -ItemType Directory | Out-Null
    foreach($file in $filesToArchive) {
        $destPath = (Join-Path $archiveFolder $file)
        $destParentPath = Split-Path $destPath -Parent
        if(-not (Test-Path $destParentPath)) { New-Item $destParentPath -ItemType Directory | Out-Null }
        if(Test-Path (Join-Path $configFolder $file)) {
            Copy-Item -Path (Join-Path $configFolder $file) -Destination $destPath -Force | Out-Null
        } else { Write-Warning "Can't find the file $(Join-Path $configFolder $file)." }
    }

    if(Test-Path $archivePath) { Remove-Item $archivePath -Force }
    Get-ChildItem $archiveFolder | Compress-Archive -DestinationPath $archivePath
    Remove-Item $ArchiveFolder -Recurse -Force
    $archivePath
}

Export-ModuleMember -Function Backup-GCPConfiguration