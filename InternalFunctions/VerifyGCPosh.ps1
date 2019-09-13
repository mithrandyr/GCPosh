function VerifyGCPosh {
    if(-not $script:VarsAreValid) {
        Write-Error -Category InvalidOperation -Message "GCPosh Variables are not properly set." -RecommendedAction "Run Set-GCPVariable to set the variables needed by the module, use the -Persist parameter to resuse the value on subsequent module imports." -ErrorAction Stop
    }    
}