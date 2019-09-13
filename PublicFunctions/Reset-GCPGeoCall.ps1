<#
.Synopsis
    Automates resetting GeoCall, restarting services, removing log files, etc
#>
function Reset-GCPGeoCall {
    [cmdletBinding()]
    param([Parameter()][int]$Version = 1)
    VerifyGCPosh
    Stop-Service GeoCallHostService -Force
    Start-Sleep -Seconds 1
    if((Get-Service GeoCallApacheInstance).Status -ne "Stopped") { Stop-Service GeoCallApacheInstance -Force }

    [scriptblock]$sb = {
        [string[]]$removeList = @(
            (Join-path $script:GeoCallPath ("Temp\{0}-log.txt" -f $env:COMPUTERNAME))
            , (Join-path $script:GeoCallPath "Temp\mapserver-debug-file.log")
            , (Join-Path $script:GeoCallPath ("MapData\{0}\map-files-processed\{0}\version-{1}\" -f $script:StateAbbreviation, $Version))
            , (Join-Path $script:GeoCallPath ("mapcache\ga\#{0}\" -f $Version))
            , (Join-Path $script:GeoCallPath ("Temp\GeoCallJob-*.log"))
        )
        foreach($item in $removeList) {
            if(Test-Path -path $Item) {
                Write-Verbose "Removing '$item' ..."
                Remove-Item -path $item -Recurse -Force
            }
            else { Write-Verbose "Not Found: $item" }
        }
    }

    try { $sb.Invoke() }
    catch {
        Write-Warning "Error trying to clean up files, waiting 5 seconds and retrying..."
        Start-Sleep -Seconds 5
        $sb.Invoke()
    }

    Start-Sleep -Seconds 1
    Start-Service GeoCallHostService
}

Export-ModuleMember -Function Reset-GCPGeoCall