function VerifyGeoCallDeployed {
    $ErrorActionPreference = "Stop"
    [string]$gcHostPath = (Join-Path $script:GeoCallPath "production\current\bin\GcHost.exe")
    if(-not (Test-Path -Path $gcHostPath)) {
        throw "GeoCall is not deployed, cannot find '$gcHostPath'! (try running GCDM app upgrade)"
    }
}