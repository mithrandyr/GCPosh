function RunGCDM {
    [cmdletBinding()]
    param([switch]$PassThru, [parameter(ValueFromRemainingArguments)]$args)
    $ErrorActionPreference = "Stop"
    Push-Location $script:GCDMPath

    &.\gcdm $args |
        ForEach-Object {
            if($PassThru) { $_ }
            Write-Verbose $_
        }

    Pop-Location
    if($LASTEXITCODE -ne 0) { throw "Error occurred running GCDM ($args)"}
}