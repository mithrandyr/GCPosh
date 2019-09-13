#Loading logic
if(-not (Get-Module SimplySql)) { Write-Warning "Some functions require the SimplySql module, please import prior to running those functions." }

#dot source all files
Get-ChildItem (Join-Path $PSScriptRoot "InternalFunctions") -File -Filter "*.ps1" -Recurse | ForEach-Object { . $_.FullName }
Get-ChildItem (Join-Path $PSScriptRoot "PublicFunctions") -File -Filter "*.ps1" -Recurse | ForEach-Object { . $_.FullName }

#Module Variables
$script:PersistedVariablesPath = Join-Path $PSScriptRoot "variables.json"
$script:VarsAreValid = $false
if(Get-GCPVariable -Persisted) { Get-GCPVariable -Persisted | Set-GCPVariable }

Export-ModuleMember -Function RunGCDM, RunGCHost, GetAzureIMSToken, ListAzureBlobs, GetAzureBlob