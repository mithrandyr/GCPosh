function Set-GCPVariable {
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$StateAbbreviation
        , [parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$GeoCallPath
        , [parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$GCDMPath
        , [parameter(ValueFromPipelineByPropertyName)][string]$AzureStorageAccount
        , [parameter(ValueFromPipelineByPropertyName)][string]$AzureContainerDeployments
        , [parameter(ValueFromPipelineByPropertyName)][string]$AzureContainerTools
        , [switch]$Persist
    )

    [bool]$errorThrown = $false

    #StateAbbreviation
    if([string]::IsNullOrWhiteSpace($StateAbbreviation)) {
        Write-Error "No acceptable value was entered for the parameter 'StateAbbreviation'." -Category InvalidArgument
        $errorThrown = $true
    }

    #GeoCallPath
    if(-not (Test-Path -Path $GeoCallPath -PathType Container)) {
        Write-Error "No acceptable value was entered for the parameter 'GeoCallPath'." -Category InvalidArgument -CategoryReason "Folder not found at '$GeoCallPath'."
        $errorThrown = $true
    }

    #GCDMPath
    if(Test-Path -Path $GCDMPath -PathType Container) {
        if(-not (Test-Path (Join-Path $GCDMPath "gcdm.exe") -PathType Leaf)) {
            Write-Error "No acceptable value was entered for the parameter 'GCDMPath'." -Category InvalidArgument -CategoryReason "File not found at '$(join-path $GCDMPath gcdm.exe)'."
        }
    }
    else {
        Write-Error "No acceptable value was entered for the parameter 'GCDMPath'." -Category InvalidArgument -CategoryReason "Folder not found at '$GCDMPath'."
        $errorThrown = $true
    }

    if($errorThrown) {
        if($script:VarsAreValid) { Write-Warning "GCPosh variables were not properly set.  Functions will use existing variables." }
        else { Write-Warning "GCPosh variables were not properly set.  No functions can be run.  Correct errors and re-run Set-GCPVariable." }
    }
    else {
        $StateAbbreviation = $StateAbbreviation.ToUpper()
        if($Persist) {
            try {
                @{
                    StateAbbreviation = $StateAbbreviation
                    GeoCallPath = $GeoCallPath
                    GCDMPath = $GCDMPath
                    AzureStorageAccount = $AzureStorageAccount
                    AzureContainerDeployments = $AzureContainerDeployments
                    AzureContainerTools = $AzureContainerTools
                } |
                    ConvertTo-Json -ErrorAction Stop |
                    Set-Content -Path $script:PersistedVariablesPath -ErrorAction Stop -Force
            }
            catch { Write-Warning "Variables not persisted!" }
        }

        $script:StateAbbreviation = $StateAbbreviation
        $script:GeoCallPath = $GeoCallPath
        $script:GCDMPath = $GCDMPath
        
        $script:AzureStorageAccount = $AzureStorageAccount
        $script:AzureContainerDeployments = $AzureContainerDeployments
        $script:AzureContainerTools = $AzureContainerTools

        $script:VarsAreValid = $true
    }
}

Export-ModuleMember -Function Set-GCPVariable