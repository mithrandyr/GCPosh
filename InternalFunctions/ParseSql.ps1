function ParseSql {
    param([Parameter(ValueFromPipeline, Mandatory)][AllowEmptyString()][string[]]$data)
    
    begin {
        [string]$tempSql = ""
    }

    process {
        foreach($s in ($data | ForEach-Object { $_.split([System.Environment]::NewLine) })) {
            if($s.TrimEnd() -eq "go") {
                if($tempSql -and $tempSql.Trim().Length -gt 0) {
                    $tempSql.TrimEnd()
                }
                $tempSql = ""
            }
            else { $tempSql += $s + [System.Environment]::NewLine }
        }
    }

    end {
        if($tempSql -and $tempSql.Trim().Length -gt 0) {
            $tempSql.TrimEnd()
        }
    }
}