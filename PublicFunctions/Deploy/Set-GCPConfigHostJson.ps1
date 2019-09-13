function Set-GCPConfigHostJson {
    param (
        [Parameter()][string]$ConfigName = "current"
        , [Parameter(Mandatory)][string]$DnsHost
        , [Parameter(Mandatory)][string]$PrivateKeyPath
        , [Parameter(Mandatory)][string]$PublicCertPath
        , [Parameter()][string]$ChainPath
        , [Parameter()][string]$GISMap = $script:StateAbbreviation
        , [switch]$DebugModeOn
        , [switch]$EnablePortal
        , [switch]$MapRequiresAuth
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName

    [string]$filePath = Join-Path $script:GeoCallPath "Config\$ConfigName\host-config.json"
    [string]$tempPath = Join-Path $script:GeoCallPath "Temp"

    $config = Get-Content -Raw -Path $filePath | ConvertFrom-Json

    #Primary Configuration
    $config.default.config.protocol = "https"
    $config.default.config.host = $DnsHost
    $config.default.config.hostAlias = $DnsHost
    $config.default.config.isDebugMode = $DebugModeOn.IsPresent
    $config.default.config.enablePortal = $EnablePortal.IsPresent
    $config.default.config.gisUnsecured = -not $MapRequiresAuth.IsPresent
    $config.default.config.gisMap = $GISMap

    #Token Configuration
    $config.default.tokens.GEOCALL_TEMP = Join-Path $script:GeoCallPath "Temp"
    if(-not (Test-Path $tempPath)) { New-Item $tempPath -ItemType Directory | Out-Null }

    $config.default.tokens.GEOCALL_SECURE = $true
    $config.default.tokens.GEOCALL_SECURE_CERT = $PublicCertPath
    $config.default.tokens.GEOCALL_SECURE_KEY = $PrivateKeyPath

    if($ChainPath) { $config.default.tokens.GEOCALL_SECURE_CHAIN = $ChainPath }
    else { $config.default.tokens.GEOCALL_SECURE_CHAIN = "" }

    #Environment Configuration
    $config.default.environment.CURL_CA_BUNDLE = Join-Path $script:GeoCallPath "\environment\ms4w\Apache\conf\ca-bundle\cacert.pem"

    #Save config
    $config |ConvertTo-Json | Set-Content -Path $filePath
}

Export-ModuleMember -Function Set-GCPConfigHostJson