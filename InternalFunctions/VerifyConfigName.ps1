function VerifyConfigName {
    param([parameter(Mandatory)][string]$ConfigName)
    $ErrorActionPreference = "Stop"

    [string]$configPath = (Join-Path $script:GeoCallPath "Config\$configName")
    if(-not (Test-Path -Path $configPath -PathType Container)) {
        throw "There is no config named '$ConfigName' at '$configPath'!"
    }
}