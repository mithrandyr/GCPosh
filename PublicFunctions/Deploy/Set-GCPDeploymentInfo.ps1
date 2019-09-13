<#
.Synopsis
    Sets the Deployment Information in the specified file.

.Description
    Sets the EnvironmentName, Deployment Date and version information for
    GeoCall, Configuration, and Database in a XML compatible file.  If not
    specified, will look up the EnvironmentName, Geocall Version, Database
    Version and set the DeploymentDate to now.

.Parameter Path
    Path to xml file, if relative, assumes from root of configuration folder.

#>
function Set-GCPDeploymentInfo {
    param(
        [Parameter()][string]$Path = "web\media-custom\welcome.html"
        , [Parameter()][string]$EnvName = ((Get-GCPDnsHost) -split "://")[1].Split(".")[0].ToUpper()
        , [Parameter()][string]$VersionGeoCall = (Get-GCPVersions -Installed)
        , [Parameter()][string]$VersionConfiguration = "??? (local development)"
        , [Parameter()][string]$VersionDatabase
        , [Parameter()][string]$DeploymentDate = (Get-Date)
        , [Parameter()][string]$IdForEnvName = "environment"
        , [Parameter()][string]$IdForVersionGeoCall = "gc-version"
        , [Parameter()][string]$IdForVersionConfiguration = "config-version"
        , [Parameter()][string]$IdForVersionDatabase = "db-version"
        , [Parameter()][string]$IdForDeploymentDate = "last-deploy"
        , [Parameter()][string]$ConfigName = "current"
    )
    $ErrorActionPreference = "Stop"
    try {
        #getting file
        if(-not [System.IO.Path]::IsPathRooted($Path)) {
            $Path = (Get-GCPVariable).GeoCallPath |
                Join-Path -ChildPath "Config\$ConfigName" |
                Join-Path -ChildPath $Path
        }
        $xml = [xml](Get-Content -Path $path -Raw)
        
        $configVersionPath = Join-Path (Get-GCPVariable).GeoCallPath -ChildPath "Config\$ConfigName\version.dat"
        if(Test-Path -Path $configVersionPath) { $VersionConfiguration = Get-Content -Path $configVersionPath -Raw }
        
        if(-not $VersionDatabase) {
            VerifySimplySql
            $cn = "Set-GCPVersionInfo"
            Open-GCPSqlConnection -Type MSSQL -ConfigName $ConfigName -CN $cn
            $VersionDatabase = Invoke-SqlScalar -ConnectionName $cn -Query "SELECT MAX(VersionNumber) FROM custom.VersionHistory"
            Close-SqlConnection -ConnectionName $cn
        }

        #setting values
        $val = Select-Xml -Xml $xml -XPath "//*[@id='$idForEnvName']"
        if($val) { $val[0].Node.InnerText = $EnvName }
        
        $val = Select-Xml -Xml $xml -XPath "//*[@id='$IdForVersionGeoCall']"
        if($val) { $val[0].Node.InnerText = $VersionGeoCall }

        $val = Select-Xml -Xml $xml -XPath "//*[@id='$IdForVersionConfiguration']"
        if($val) { $val[0].Node.InnerText = $VersionConfiguration }

        $val = Select-Xml -Xml $xml -XPath "//*[@id='$IdForVersionDatabase']"
        if($val) { $val[0].Node.InnerText = $VersionDatabase }

        $val = Select-Xml -Xml $xml -XPath "//*[@id='$IdForDeploymentDate']"
        if($val) { $val[0].Node.InnerText = $DeploymentDate }

        #saving file
        $xml.Save($path) | Out-Null
    }
    catch {
        Write-Warning "Error while attempting to run 'Set-GCPDeploymentInfo'..."
        Write-Warning "Message: $_"
    }
}

Export-ModuleMember -Function Set-GCPDeploymentInfo