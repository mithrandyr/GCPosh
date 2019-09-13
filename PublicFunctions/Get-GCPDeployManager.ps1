function Get-GCPDeployManager {
    param([string]$configFilePath)
    
    $ErrorActionPreference = "Stop"
    if($configFilePath) {
        if(Test-Path $configFilePath) { $gcdmConfigPath = $configFilePath }
        else { throw "Invalid Parameter (ConfigFilePath) -- '$configFilePath' does not exist."}
    }
    else {
        VerifyGCPosh
        $gcdmConfigPath = Join-Path $script:GCDMPath "gcdm.config"
    }

    $result = [PSCustomObject]@{Version = ""; GeoCallRoot = ""; BuildType = ""; StorageConnection = ""}
    $result.Version = Get-Item -Path (Join-Path $script:GCDMPath "gcdm.exe") | Select-Object -ExpandProperty VersionInfo | Select-Object -ExpandProperty FileVersion
    Get-Content $gcdmConfigPath |
        ForEach-Object {
            if($_.StartsWith("local.folder=")) { $result.GeoCallRoot = $_.SubString(13).Trim() }
            elseif($_.StartsWith("app.buildtype=")) { $result.BuildType = $_.SubString(14).Trim() }
            elseif($_.StartsWith("app.storage.connection=")) { $result.StorageConnection = $_.SubString(23).Trim()}
        }
    $result
}

Export-ModuleMember -Function Get-GCPDeployManager