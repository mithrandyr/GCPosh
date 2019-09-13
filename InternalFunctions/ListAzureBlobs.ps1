function ListAzureBlobs {
    param([string]$AccountName = $script:AzureStorageAccount
        , [Parameter(Mandatory)][string]$ContainerName
        , [string]$AzToken = (GetAzureIMSToken))
    
    [hashtable]$ht = @{
        Uri = "https://{0}.blob.core.windows.net/{1}?restype=container&comp=list" -f $AccountName, $ContainerName
        Headers = @{
                Authorization = $AzToken
                "x-ms-version" = "2017-11-09"
            }
        UseBasicParsing = $true
    }
    ([xml]((Invoke-RestMethod @ht).SubString(3))).EnumerationResults.Blobs.Blob.Name    
}