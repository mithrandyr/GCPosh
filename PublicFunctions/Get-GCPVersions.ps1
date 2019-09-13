function Get-GCPVersions {
    param([switch]$Installed, [switch]$Latest)
    $ErrorActionPreference = "Stop"
    VerifyGCPosh

    if($Installed) {
        VerifyGeoCallDeployed
        (Get-Item (Join-Path $script:GeoCallPath "production\current\bin\GcHost.exe") -ErrorAction Stop).VersionInfo.FileVersion
    }
    else {
        $results = RunGCDM app versions -PassThru |
            Select-Object -Skip 5 |
            Where-Object {$_} |
            ForEach-Object {
                    $split = $_.IndexOf(" ")
                    [string[]]$tags = ($_.Substring($split).Split("/").foreach({$_.Trim()}))
                    [PSCustomObject] @{
                        Version = [version]$_.Substring(0, $split).Trim()
                        IsInstalled = "Installed" -in $tags
                        IsProduction = "Production" -in $tags
                        IsBeta = "Beta" -in $tags
                        IsInternal = "Internal" -in $tags
                    }
                }
        if($Latest) {
            [bool]$keep = $false
            $results = $results.foreach({
                    $keep = $keep -or $_.IsProduction -or $_.IsBeta -or $_.IsInternal
                    if($keep) { $_ }
                })
        }

        $results | Sort-Object -Property Version -Descending
    }
}

Export-ModuleMember -Function Get-GCPVersions