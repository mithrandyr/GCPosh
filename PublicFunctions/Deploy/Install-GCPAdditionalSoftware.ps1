function Install-GCPAdditionalSoftware {
    param([switch]$DoDeploy)
    $ErrorActionPreference = "Stop"
    VerifyGCPosh

    [version]$gcVersion = Get-GCPVersions -Installed #this also will verify that GeoCall is Deployed

    #consider adding -Silent Parameter (no output) and defaulting the output to an object that has the GCVersion & status of each software
    $RequiredSoftware = @(
        @{
            Name = "Visual C++ 2012 Update 4 (x86) [MapServer]"
            GeoCallVersion = [version]"0.0.0.0"
            TestScript = { Test-Path 'HKLM:\SOFTWARE\Classes\Installer\Dependencies\{33d1fd90-4274-48a1-9bc1-97e33d9c2d6f}' }
            InstallScript = {
                $splat = @{
                    Uri = 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe'
                    UseBasicParsing = $true
                    OutFile = Join-Path ([system.io.path]::GetTempPath()) "vcredist_x86.exe"
                }

                Invoke-WebRequest @splat | Out-Null
                &$splat.OutFile /install /passive /norestart | Out-Null
                Start-Sleep -Milliseconds 500
                Remove-Item $splat.OutFile
            }
        }
    )


    foreach($ht in $RequiredSoftware) {
        if($ht.GeoCallVersion -le $gcVersion) {
            $isInstalled = $ht.TestScript.Invoke()
            if($isInstalled) { Write-Host ("{0} - INSTALLED" -f $ht.Name) -ForegroundColor Green }
            else {
                Write-Host ("{0} - Missing" -f $ht.Name) -ForegroundColor Yellow
                if($DoDeploy) {
                    Write-Host ("{0} - Installing..." -f $ht.Name) -ForegroundColor Yellow
                    try {
                        $ht.InstallScript.Invoke() | Out-Null
                        if($ht.TestScript.Invoke()) {
                            Write-Host ("{0} - Installed" -f $ht.Name) -ForegroundColor Green
                        } else { Write-Host ("{0} - Missing (check event logs for errors)" -f $ht.Name) -ForegroundColor Red }
                    }
                    catch { Write-Host ("{0} - Failed Install: $_" -f $ht.Name) -ForegroundColor Red }
                }
            }
        }
    }
}

Export-ModuleMember -Function Install-GCPAdditionalSoftware