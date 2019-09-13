<#
.Synopsis
    Creates/Updates GeoCall Schedules (Jobs)

.Description
    Creates/Updates GeoCall Schedules (Jobs) using the native PowerShell
    Schedule Jobs functions.  Will override the existing ScheduledJob if
    it exists.
    Includes: Queue, Notice and Response processing.

    Also includes a cleanup job to remove old log files (> 30 days)

    To "uninstall", use the unregister-scheduledjob command with -force parameter

.Parameter ConfigName
    Configuration to use.

.Parameter Delay
    Number of seconds between executions
    5, 6, 10, 12, 15, 20, 30
#>
function Install-GCPJob {
    Param([Parameter()][string]$ConfigName = "current"
        , [Parameter()][ValidateSet(5,6,10,12,15,20,30)][int]$Delay = 15)
    $ErrorActionPreference = "Stop"
    VerifyGCPosh
    VerifyConfigName -ConfigName $ConfigName
    $moduleBase = Get-Module GCPosh | Select-Object -ExpandProperty ModuleBase
    $jobName = "GeoCallJob"

    $theJob = [scriptblock]::Create({
        $moduleBase = '<1>'
        $configName = '<2>'
        $delay = [int]('<3>')
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $ErrorActionPreference = "Stop"
        
        Import-Module $moduleBase
        $dnsHost = Get-GCPDnsHost -ConfigName $ConfigName
        $token = Get-GCPConfigApiKey -ConfigName $ConfigName
        $gcJobPath = Join-Path (Get-GCPVariable).GeoCallPath ("Temp\<4>-{0:yyyyMMdd}.log" -f (Get-Date))
        if(-not (Test-Path $gcJobPath)) { New-Item -Path $gcJobPath -ItemType File | Out-Null }
        
        if(Get-Service GeoCallApacheInstance, GeoCallHostService | Where-Object Status -ne Running) {
            Write-Error "GeoCall services are not running." -Category ResourceUnavailable -RecommendedAction "Start-Service GeoCallHostService"
            Add-Content -Path $gcJobPath -Value ("[{0:HH:mm:ss}] ERROR: {1} not running!" -f (Get-Date), ((Get-Service GeoCallHostService, GeoCallApacheInstance | Where-Object Status -ne Running).Name -join " & "))
            return
        }

        $iteration = 60 / $delay
        
        while ($iteration -gt 0) {
            Add-Content -Path $gcJobPath -Value ("[{0:HH:mm:ss}] #$iteration" -f (Get-Date))
            foreach ($cmd in @("Queue","Notice","Response")) {
                try {
                    $icmd = "Invoke-GCP{0}Processing" -f $cmd
                    $t = (Measure-Command { &$icmd -DnsHost $dnsHost -Token $token }).TotalMilliseconds
                    Add-Content -Path $gcJobPath -Value ("  >$cmd< SUCCESS ({0}ms)" -f $t)
                }
                catch { 
                    Write-Warning $_
                    Add-Content -Path $gcJobPath -Value "  >$cmd< - ERROR >>> $_"
                }
            }           
            
            $iteration -= 1
            if($iteration -gt 0) {
                $check = ($delay * 1000) - $sw.Elapsed.TotalMilliseconds
                if($check -gt 100) { Start-Sleep -Milliseconds $check}
                $sw.Restart()
            }
        }
        $sw.stop()
        $sw = $null
    }.ToString().Replace('<1>', $moduleBase).Replace('<2>', $ConfigName).Replace('<3>', $Delay).Replace('<4>', $jobName))


    if(Get-ScheduledJob -Name $jobName -ErrorAction Ignore) {
        Write-Warning "Overwriting '$jobName'..."
        Disable-ScheduledJob -Name $jobName
        Unregister-ScheduledJob -Name $jobName -Force
    }

    Write-Verbose "Registering the GeoCallJob"
    Register-ScheduledJob -Name $jobName -ScriptBlock $theJob -RunNow -RunEvery ([timespan]::New(0,1,0)) -ScheduledJobOption (New-ScheduledJobOption -MultipleInstancePolicy StopExisting) -Trigger (New-JobTrigger -AtLogOn)

    #Cleanup job
    
    $theJob = [scriptblock]::Create({
        $moduleBase = '<1>'
        $ErrorActionPreference = "Stop"
        
        Import-Module $moduleBase
        $gcJobFilter = Join-Path (Get-GCPVariable).GeoCallPath "Temp\<2>-*.log"
        Get-ChildItem -Path $gcJobFilter -File |
            Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30)} |
            Remove-Item -Force
        
    }.ToString().Replace('<1>', $moduleBase).Replace('<2>', $jobName))

    $jobName = "GeoCallCleanLogs"
    if(Get-ScheduledJob -Name $jobName -ErrorAction Ignore) {
        Write-Warning "Overwriting '$jobName'..."
        Disable-ScheduledJob -Name $jobName
        Unregister-ScheduledJob -Name $jobName -Force
    }
    Register-ScheduledJob -Name $jobName -ScriptBlock $theJob -ScheduledJobOption (New-ScheduledJobOption -MultipleInstancePolicy StopExisting) -Trigger (New-JobTrigger -Daily -At "01:00")

}
Export-ModuleMember -Function Install-GCPJob