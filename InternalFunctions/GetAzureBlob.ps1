function GetAzureBlob {
    param([string]$AccountName = $script:AzureStorageAccount
        , [Parameter(Mandatory)][string]$ContainerName
        , [Parameter(Mandatory)][string]$BlobName
        , [string]$FileName
        , [string]$AzToken = (GetAzureIMSToken))
    
    [hashtable]$ht = @{
        Uri = "https://{0}.blob.core.windows.net/{1}/{2}" -f $AccountName, $ContainerName, $BlobName
        Headers = @{
                Authorization = $AzToken
                "x-ms-version" = "2017-11-09"
            }
        UseBasicParsing = $true
    }
    if([string]::IsNullOrWhiteSpace($FileName)) { $FileName = $BlobName}
    Invoke-WebRequest @ht -OutFile $FileName
}