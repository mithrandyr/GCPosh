<#
.Parameter Force
    Use this parameter if you want to overlay the configuration and not preserve
    any existing configuration settings stored in
        databases.xml
        host-config.json
        maps.xml
        security-tokens.txt
        mapstyle\xxx\web.map

.Parameter UseGCDM
    Use this parameter if you want to pull configuration through GCDM, otherwise
    configuration will be pulled from Azure Storage Blob (per GC Posh variables)

.Parameter ProcessCustomData
    calls Update-GCPSqlDbCustom after configuration has been processed.
#>
function Install-GCPConfiguration {
    [cmdletBinding(DefaultParameterSetName="azure")]
    Param(
        [Parameter(Mandatory, ParameterSetName="gcdm")][string]$SourceConfigName
        , [Parameter()][string]$DestConfigName = "current"
        , [Parameter()][switch]$Force
        , [Parameter(ParameterSetName="gcdm")][switch]$UseGCDM
        , [Parameter(ParameterSetName="azure")][version]$VersionNumber
        , [Parameter(ParameterSetName="azure")][string]$AzToken
        , [Parameter(Mandatory, ParameterSetName="path")][string]$ArtifactPath
        , [switch]$ProcessCustomData
        , [switch]$AllowRollback
    )
    $ErrorActionPreference = "Stop"
    VerifyGCPosh

    [string]$rootConfigPath = Join-Path $script:GeoCallPath "\Config\"
    if(Test-Path $rootConfigPath) {
        Write-Verbose "Backing up existing configuration elements..."
        if(-not $Force) {
            [string]$archivePath = Backup-GCPConfiguration -ConfigName $DestConfigName
            [hashtable]$mapsHt = Get-GCPConfigMap -ConfigName $DestConfigName
        }
        Remove-Item $rootConfigPath -Recurse -Force
    }

    if($UseGCDM) { 
        RunGCDM config init
        VerifyConfigName -ConfigName $SourceConfigName
        if($SourceConfigName -ne $DestConfigName) {
            if(Test-Path (Join-Path $rootConfigPath $DestConfigName)) { Remove-Item (Join-Path $rootConfigPath $DestConfigName) -Recurse -Force }
            Rename-Item (Join-Path $rootConfigPath $SourceConfigName) -NewName $DestConfigName
        }
        Get-ChildItem -Path $rootConfigPath -Exclude "$DestConfigName" -Force | Remove-Item -Recurse -Force
    }
    else {
        if(-not $ArtifactPath) {
            Write-Verbose "Getting Artifact configuration from Azure Blob Storage..."
            $artifactList = @{}
            $artifactPath = Join-Path ([System.IO.Path]::GetTempPath()) "artifact.zip"
            $splat = @{
                AccountName = $script:AzureStorageAccount
                ContainerName = $script:AzureContainerDeployments
            }
            if($AzToken) { $splat.AzToken = $AzToken }
            ListAzureBlobs @splat |
                Where-Object { $_ -like "*.*.zip" } |
                ForEach-Object { try { $artifactList[[Version]($_.replace(".zip",""))] = $_ } catch {} }
            
            if($artifactList.Count -eq 0) { throw "There are no deployments!" }
                
            #grab latest VersionNumber if none have been specified
            if(-not $VersionNumber) { $VersionNumber = $artifactList.Keys | Sort-Object -Descending | Select-Object -First 1 }

            #if the specified VersionNumber doesn't exist, throw error and report nearest VersionNumbers
            if(-not $artifactList.ContainsKey($VersionNumber)) {
                $nearList = $artifactList.Keys + $VersionNumber | Sort-Object
                $loc = $nearList.IndexOf($VersionNumber)
                if($loc -eq 0) { $nearVersions = $nearList[1] }
                else { $nearVersions = $nearList[($loc-1),($loc+1)] -join " or " }
                throw "Cannot find version '$VersionNumber'; nearest version is $nearVersions!"
            }
            
            $ht = @{
                AccountName = $script:AzureStorageAccount
                ContainerName = $script:AzureContainerDeployments
                BlobName = $artifactList[$VersionNumber]
                FileName = $artifactPath
            }
            if($AzToken) { $ht.AzToken = $AzToken }

            Write-Verbose "Using Version: $VersionNumber"
            if(Test-Path $artifactPath) { Remove-Item $artifactPath -Force }
            GetAzureBlob @ht
        }
        
        Write-Verbose "Processing Artifact Configuration..."
        $configPath = Join-Path $rootConfigPath $DestConfigName
        New-Item -ItemType Directory -Path $configPath | Out-Null
        Expand-Archive -Path $artifactPath -DestinationPath $configPath
        Remove-Item $artifactPath -Force
    }
    
    New-Item -Path (Join-Path $rootConfigPath "config-$DestConfigName.txt") -ItemType File | Out-Null

    if(-not $force) {
        Write-Verbose "Restoring configuration elements from backup..."
        Restore-GCPConfiguration -ConfigName $DestConfigName -ArchivePath $archivePath
        Set-GCPConfigMap -ConfigName $DestConfigName @mapsHt
    }

    if($ProcessCustomData) {
        Write-Verbose "Processing Custom Data SQL files..."
        Open-GCPSqlConnection -ConfigName $DestConfigName -CN "SQLCustomUpdate"
        Set-SqlConnection -CommandTimeout 180 -CN "SQLCustomUpdate"
        Import-GCPUISearch -CN "SQLCustomUpdate"
        Update-GCPSqlDbCustom -CN "SQLCustomUpdate" -AllowRollback:$AllowRollback
        Close-SqlConnection -CN "SQLCustomUpdate"
    }
    Write-Verbose "DONE!"
}

Export-ModuleMember -Function Install-GCPConfiguration