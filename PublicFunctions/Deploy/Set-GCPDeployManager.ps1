function Set-GCPDeployManager {
    param(
        [string]$GeoCallRoot
        , [Parameter()][ValidateSet("Production","Beta","Internal")][string]$BuildType
        , [string]$StorageConnection
        , [string]$configFilePath
    )
    $ErrorActionPreference = "Stop"
    if($configFilePath) { $gcdmConfigPath = $configFilePath }
    else {
        VerifyGCPosh
        $gcdmConfigPath = Join-Path $script:GCDMPath "gcdm.config"
    }

    if($BuildType) { $BuildType = $BuildType.Substring(0,1).ToUpper() + $BuildType.Substring(1).ToLower() }
    if($PSBoundParameters.Count -gt 0) {
        if(-not (Test-Path $gcdmConfigPath)) { Set-Content -Path $gcdmConfigPath -Value @("local.folder=$script:GeoCallPath","app.buildtype=Production","app.storage.connection=") }
        
        $data = Get-Content $gcdmConfigPath
        $flags = @{GeoCallRoot = $false; BuildType = $false; StorageConnection = $false}
        
        foreach($i in (0..($data.count -1))) {
            if($GeoCallRoot -and $data[$i].StartsWith("local.folder=")) {
                $data[$i] = "local.folder=$GeoCallRoot"
                $flags.GeoCallRoot = $true
            }
            if($BuildType -and $data[$i].StartsWith("app.buildtype=")) {
                $data[$i] = "app.buildtype=$BuildType"
                $flags.BuildType = $true
            }
            if($StorageConnection -and $data[$i].StartsWith("app.storage.connection=")) {
                $data[$i] = "app.storage.connection=$StorageConnection"
                $flags.StorageConnection = $true
            }
        }

        if($StorageConnection -and -not $flags.StorageConnection) { $data += "app.storage.connection=$StorageConnection" }
        if($BuildType -and -not $flags.BuildType) { $data += "app.buildtype=$BuildType" }
        if($GeoCallRoot -and -not $flags.GeoCallRoot) { $data += "local.folder=$GeoCallRoot" }

        Set-Content -Path $gcdmConfigPath -Value $data
    }
}

Export-ModuleMember -Function Set-GCPDeployManager