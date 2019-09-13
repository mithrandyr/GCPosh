function Get-GCPVariable {
    param([switch]$Persisted)

    if($Persisted) {
        if(Test-Path $script:PersistedVariablesPath) { Get-Content -Path $script:PersistedVariablesPath | ConvertFrom-Json }
        else { Write-Warning "No variable data available, because none has been persisted." }
    }
    else {
        [PSCustomObject]@{
            StateAbbreviation = $script:StateAbbreviation
            GeoCallPath = $script:GeoCallPath
            GCDMPath = $script:GCDMPath
            AzureStorageAccount = $script:AzureStorageAccount
            AzureContainerDeployments = $script:AzureContainerDeployments
            AzureContainerTools = $script:AzureContainerTools
        }
    }
}

Export-ModuleMember -Function Get-GCPVariable