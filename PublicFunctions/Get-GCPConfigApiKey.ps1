function Get-GCPConfigApiKey {
    param([Parameter()][string]$ConfigName = "current")
    
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    $result = Select-String -Path (Join-Path $script:GeoCallPath "config\$ConfigName\security-tokens.txt") -Pattern "geocallApiKey=" -SimpleMatch | Select-Object -First 1
    if($result) { $result.line.SubString(14) }
    else { throw "No GeoCallApiKey Found!" }
}

Export-ModuleMember -Function Get-GCPConfigApiKey