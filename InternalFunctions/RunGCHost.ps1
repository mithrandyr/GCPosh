function RunGCHost {
    [cmdletBinding()]
    param([switch]$PassThru, [parameter(ValueFromRemainingArguments)]$args)
    $ErrorActionPreference = "Stop"

    VerifyGeoCallDeployed
    [string]$gcHostPath = (Join-Path $script:GeoCallPath "production\current\bin\GcHost.exe")

    &$gcHostPath $args |
        ForEach-Object {
            if($PassThru) { $_ }
            Write-Verbose $_
        }

    if($LASTEXITCODE -ne 0) { throw "Error occurred running GCHost ($args)"}
}