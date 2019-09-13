function Get-GCPDnsHost {
    param([Parameter()][string]$ConfigName = "current")
    
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    $data = Get-Content (Join-Path $script:GeoCallPath "Config\$ConfigName\host-config.json") | ConvertFrom-Json

    "{0}://{1}" -f $data.default.config.protocol, $data.default.config.host
}

Export-ModuleMember -Function Get-GCPDnsHost