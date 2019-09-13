function GetAzureIMSToken {
    if(Get-Command -Verb Get -Noun AzureToken) {
        Get-AzureToken -ResourceName Storage -AsToken
    }
    else {
        [hashtable]$ht = @{
            Uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/"
            ContentType = "application/json"
            Method = "Get"
            Headers = @{Metadata = $true}
        }
        "Bearer {0}" -f (Invoke-RestMethod @ht | Select-Object -ExpandProperty access_token)
    }
}