class GeoCallLog {
    [string]$LogType = $this.GetType().Name
    [int]$LogId
    [datetime]$EventDateTime
    [string]$EventLevel
    [string]$Component
    [string]$Message
    [string]$Exception

    GeoCallLog() {
        if($this.GetType().Name -eq "GeoCallLog") { throw [System.InvalidOperationException]::new("GeoCallLog must be inherited! Use GeoCallLogFile, GeoCallLogSystem or GeoCallLogClient.") }
    }    
}

class GeoCallLogFile:GeoCallLog {
    [string]$ThreadId
    [string]$HostName
    
    GeoCallLogFile([string]$data, [int]$id) {
        $this.LogId = $id
        
        #EventDateTime
        $temp, $data = $data -split " \["
        try { $this.EventDateTime = [datetime]::ParseExact($temp, "yyyyMMdd HH:mm:ss,FFF", $null) }
        catch { Write-Warning "Cannot process '$temp' properly!"; throw $_ }

        #ThreadId
        $this.ThreadId, $data = $data -split "\] "

        #EventLevel
        $this.EventLevel, $data = $data -split " "
        
        #Component
        $this.Component, $data = $data -split " - "
        $this.Component = $this.Component.Trim()

        #Message & Exception
        $this.Message, $this.Exception = $data -split [System.Environment]::NewLine
        
        $this.HostName = $env:COMPUTERNAME
    }
}

class GeoCallLogSystem:GeoCallLog {
    [string]$ThreadId
    [string]$HostName
    [string]$ApplicationName
    
    GeoCallLogSystem([System.Data.DataRow]$data) {
        $this.LogId = $data.LogId
        $this.EventDateTime = $data.EventDateTime
        $this.EventLevel = $data.EventLevel
        $this.Component = $data.Component
        $this.Message = $data.Message

        $this.ThreadId = $data.ThreadId
        $this.HostName = $data.HostName
        $this.ApplicationName = $data.ApplicationName
        $this.Exception = $data.Exception
    }
}

class GeoCallLogClient:GeoCallLog {
    [string]$ApplicationName
    [string]$UserName
    [string]$ClientOS
    [string]$ClientBrowser
    [string]$ClientAddress
    [string]$ClientUserAgent
    [string]$RequestUri
    [int]$Status
    [string]$StatusMessage
    
    GeoCallLogClient([System.Data.DataRow]$data) {
        $this.LogId = $data.LogId
        $this.EventDateTime = $data.EventDateTime
        $this.EventLevel = $data.EventLevel
        $this.Component = $data.Component
        $this.Message = $data.Message
        
        $this.ApplicationName = $data.ApplicationName
        $this.UserName = $data.UserName
        $this.ClientOS = $data.ClientOS
        $this.ClientBrowser = $data.ClientBrowser
        $this.ClientAddress = $data.ClientAddress
        $this.ClientUserAgent = $data.ClientUserAgent
        $this.RequestUri = $data.RequestUri
        $this.Status = $data.Status
        $this.StatusMessage = $data.StatusMessage
        $this.Exception = $data.Exception
    }
}

<#
.Synopsis
    Get GeoCall logs in object format.

.Description
    Get GeoCall logs in object format.
    Supports accessing filesystem and database logs.

.Parameter Newest
    Shows latest log records, up to 250.

.Parameter ConfigName
    Which configuration to use, defaults to 'Current'
#>
function Get-GCPLog {
    Param(
        [Parameter()][ValidateSet("File","System","Client", "All")][String[]]$LogType = "File"
        , [Parameter()][ValidateRange(1,250)][int]$Newest
        , [string]$ConfigName = "current"
    )
    VerifyGCPosh

    if($LogType -contains "File" -or $LogType -contains "All") {
        $filePath = (Join-Path $Script:GeoCallPath "Temp") | Join-Path -ChildPath ("{0}-log.txt" -f $env:COMPUTERNAME)
        if(-not (Test-Path $filePath)) { throw "Cannot find the log file '$filePath'!" }
        
        [int]$id = 0
        [string]$LogMessage = ""
        $Results = @()
        (Get-Content -Path $filePath).where({$_}).foreach({
            if($_.Substring(0,8) -ge "20000101" -and $_.Substring(0,8) -lt "30001010") {
                if($LogMessage) {
                    if($Newest -eq 0) { [GeoCallLogFile]::new($LogMessage, $id) }
                    else { $results += [GeoCallLogFile]::new($LogMessage, $id) }
                    $LogMessage = $null
                } 
                $id += 1
                $LogMessage = $_
            }
            else { $LogMessage += [System.Environment]::NewLine + $_ }
        })
        #Handle any hanging items
        if($LogMessage) {
            if($Newest -eq 0) { [GeoCallLogFile]::new($LogMessage, $id) }
            else { $results += [GeoCallLogFile]::new($LogMessage, $id) }
            $LogMessage = $null
        }

        if($Newest -gt 0) {
            $Results |
                Sort-Object -Descending -Property LogId |
                Select-Object -First $Newest
        }
    }
    
    if($LogType -contains "System" -or $LogType -contains "All"){
        VerifyConfigName -ConfigName $ConfigName
        
        if($Newest) { $query = "SELECT TOP {0} * FROM dbo.Systemlog ORDER BY LogId DESC" -f $Newest }
        else { $query = "SELECT * FROM dbo.Systemlog" }
        
        Open-GCPSqlConnection -cn "GetGCPLog"
        try { (Invoke-SqlQuery -cn "GetGCPLog" -Query $query).foreach({[GeoCallLogSystem]::new($_)}) }
        finally { Close-SqlConnection -cn "GetGCPLog" }
    }
    
    if($LogType -contains "Client" -or $LogType -contains "All"){
        VerifyConfigName -ConfigName $ConfigName
        
        if($Newest) { $query = "SELECT TOP {0} * FROM dbo.ClientLog ORDER BY LogId DESC" -f $Newest }
        else { $query = "SELECT * FROM dbo.Clientlog" }
        
        Open-GCPSqlConnection -cn "GetGCPLog"
        try { (Invoke-SqlQuery -cn "GetGCPLog" -Query $query).foreach({[GeoCallLogClient]::new($_)}) }
        finally { Close-SqlConnection -cn "GetGCPLog" }
    }
}

Export-ModuleMember -Function Get-GCPLog