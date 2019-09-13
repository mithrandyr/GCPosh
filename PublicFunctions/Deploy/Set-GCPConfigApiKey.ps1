function Set-GCPConfigApiKey {
    param([Parameter()][string]$ConfigName = "current"
        , [Parameter()][string]$apiKey
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    if(-not $apiKey) { $apiKey = [guid]::NewGuid().tostring().replace("-","") }
    $securityTokensPath = Join-Path $script:GeoCallPath "config\$ConfigName\security-tokens.txt"

    $data = Get-Content $securityTokensPath
    [int]$i = 0
    foreach($i in (0..($data.Length-1))) {
        if($data[$i].StartsWith("geocallApiKey=")) { $data[$i] = "geocallApiKey=$apiKey" }
    }

    $data | Set-Content $securityTokensPath
}

Export-ModuleMember -Function Set-GCPConfigApiKey