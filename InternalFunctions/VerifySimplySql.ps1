function VerifySimplySql {
    if($TestForSimplySql -and -not (Get-Module SimplySql)) {
        Write-Error -Category InvalidOperation -Message "This function requires the SimplySql module to be imported prior to running." -RecommendedAction "Run 'Import-Module SimplySql' then re-run this function." -ErrorAction Stop
    }
}