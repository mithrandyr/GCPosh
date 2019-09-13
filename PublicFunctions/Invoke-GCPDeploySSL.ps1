function Invoke-GCPDeploySSL {
    Param(
        [Parameter()][string]$AccountName
        , [Parameter()][string]$ContainerName
        , [Parameter()][string]$BlobName = "ssl.zip"
        , [Parameter()][string]$RootPath
        , [Parameter()][string]$AzToken = (Get-AzureToken -ResourceName Storage -AsToken)
        , [Parameter(ParameterSetName="download")][switch]$DownloadOnly
        , [Parameter(ParameterSetName="download")][string]$DownloadPath = ".\"
        , [switch]$Force
    )

    #pull automatic values from GCVariables
    if($script:VarsAreValid) {
        if(-not $RootPath -or (-not(Test-Path $RootPath))) {
            $RootPath = Get-GCPVariable | Select-Object -ExpandProperty GeoCallPath | Split-Path -Parent
        }
        else { throw "Invalid path '$rootpath' specified for -RootPath!" }

        if(-not $AccountName) { $AccountName = Get-GCPVariable | Select-Object -ExpandProperty AzureStorageAccount }
        if(-not $ContainerName) { $ContainerName = Get-GCPVariable | Select-Object -ExpandProperty AzureContainerTools }
    }

    if(-not (Test-Path $RootPath)) { throw "Invalied path '$rootpath' (-RootPath)!" }
    if(-not $AccountName) { throw "Missing -AccountName!" }
    if(-not $ContainerName) { throw "Missing -AccountName!" }

    if($DownloadOnly) { $destFile = Join-Path $DownloadPath $BlobName}
    else { $destFile = Join-Path $RootPath $BlobName }
    $splat = @{AccountName = $AccountName; ContainerName = $ContainerName; BlobName = $BlobName; FileName = $destfile}
    
    if($AzToken) { $splat.AzToken = $AzToken }
    GetAzureBlob @splat
    if(-not $DownloadOnly) {
        Expand-Archive -Path $destFile -DestinationPath (Join-Path $RootPath "GeoCall") -Force:$Force
        Remove-Item -Path $destFile
    }
}

Export-ModuleMember -Function Invoke-GCPDeploySSL