<#
.Synopsis
    GeoCall deployment: install and configuration.

.Description
    GeoCall deployment: install and configuration.
    This will call all the necessary cmdlets in the order required to properly
    install and configure GeoCall on a system.

    Logic Overview
        Download Files
            MapData
            GCDM
            SSL
        Configure
            GCPosh
            GCDM
        Update System
            GeoCall (Update-GCPGeoCall - gets latest binaries)
            Software requirements (Install-GCPAdditionalSoftware)
        Prepare System
            Configuration deployment (Install-GCPConfiguration)
            host-config.json
            maps.xml
            web.map
            security-tokens.txt (apikey)
            databases.xml
        Prepare Databases
            postgres (Initialize-GCPPostgresDb)
            sql server (Initialize-GCPSqlDb)
            initial settings (Set-GCPSystemSettings)
        App Install
            GeoCall (Install-GCPGeoCall)
            Admin Perms (Set-GCPAdmin)
            Service start (Start-Service & restart if it dies.)
            Stop Service
        Custom Config
            UISearch (Import-GCPUISearch)
            Custom DB Config (Update-GCPSqlDbCustom)
            Start Service
#>
function Invoke-GCPDeployment {
    Param([parameter(Mandatory)][string]$RootPath
        , [parameter(Mandatory)][string]$StateAbbreviation
        , [parameter(Mandatory)][string]$StateTitle
        , [parameter(Mandatory)][string]$AzStorageAccount
        , [parameter(Mandatory)][string]$AzContainerGeoCallConfiguration
        , [parameter(Mandatory)][string]$AzContainerGeoCallTools
        , [parameter(Mandatory)][string]$SqlServerName
        , [parameter(Mandatory)][string]$SqlDatabaseName
        , [parameter(Mandatory)][string]$SqlUserName
        , [parameter(Mandatory)][string]$SqlPass
        , [parameter(Mandatory)][string]$PgServerName
        , [parameter(Mandatory)][string]$PgDatabaseName
        , [parameter(Mandatory)][string]$PgUserName
        , [parameter(Mandatory)][string]$PgPass
        , [parameter(Mandatory)][string]$DnsHostName
        , [parameter()][version]$GeoCallVersion
        , [parameter()][string]$SqlTimeZone = [System.TimeZone]::CurrentTimeZone.StandardName
        , [parameter()][string]$AzToken
        , [parameter()][ValidateSet("Beta","Internal","Production")][string]$BuildType = "Production"
        , [parameter()][int]$StartAtStep = 1
        , [switch]$UseLocalSSL
        , [switch]$Silent
    )
    $ErrorActionPreference = "Stop"
    $logicSteps = @(
        @{ #Creating Folders
            Step = "Creating Required Folders"
            Expression = {
                "GeoCall" |
                    ForEach-Object {
                        $testPath = Join-Path $RootPath $_
                        if(Test-Path $testPath) { Write-Warning "$testPath already exists!" }
                        else { New-Item -ItemType Directory -Path $testPath | Out-Null }
                    }
            }
        },
        @{ #Download GCDM
            Step = "Installing GCDM"
            Expression = { 
                $destFile = Join-Path $RootPath "gcdm.zip"
                $splat = @{AccountName = $AzStorageAccount; ContainerName = $AzContainerGeoCallTools; BlobName = "gcdm.zip"; FileName = $destfile}
                if($AzToken) { $splat.AzToken = $AzToken }
                GetAzureBlob @splat
                Expand-Archive -Path $destFile -DestinationPath $RootPath
                Remove-Item -Path $destFile
            }
        },
        @{ #Download SSL
            Step = "Installing SSL Certificates"
            Expression = {
                $splat = @{AccountName = $AzStorageAccount; ContainerName = $AzContainerGeoCallTools; RootPath = $RootPath}
                if($UseLocalSSL) { $splat.BlobName = "ssl-localhost.zip" }
                if($AzToken) { $splat.AzToken = $AzToken }

                Invoke-GCPDeploySSL @splat -Force
            }
        },
        @{ #Download MapData
            Step = "Installing MapData"
            Expression = {
                $destFile = Join-Path $RootPath "mapdata.zip"
                $splat = @{AccountName = $AzStorageAccount; ContainerName = $AzContainerGeoCallTools; BlobName = "mapdata.zip"; FileName = $destfile}
                if($AzToken) { $splat.AzToken = $AzToken }
                GetAzureBlob @splat
                Expand-Archive -Path $destFile -DestinationPath (Join-Path $RootPath "GeoCall")
                Remove-Item -Path $destFile
            }
        },
        @{ #Configure GCPosh
            Step = "Configuring GCPosh"
            Expression = {
                $splat = @{
                    StateAbbreviation = $StateAbbreviation
                    GeoCallPath = (Join-Path $RootPath "GeoCall")
                    GCDMPath = (Join-Path $RootPath "GeoCall\Manager")
                    AzureStorageAccount = $AzStorageAccount
                    AzureContainerDeployments = $AzContainerGeoCallConfiguration
                    AzureContainerTools = $AzContainerGeoCallTools
                }
                Set-GCPVariable @Splat -Persist
            }
        },
        @{ #Configure GCDM
            Step = "Configuring GCDM"
            Expression = {
                Set-GCPDeployManager -GeoCallRoot (Join-Path $RootPath "GeoCall") -BuildType $BuildType
            }
        },
        @{ #Download GeoCall
            Step = "Downloading GeoCall"
            Expression = {
                if(-not $GeoCallVersion) { Update-GCPGeoCall }
                else { Update-GCPGeoCall -versionNumber $GeoCallVersion }
            }
        },
        @{ #Install Additional Software
            Step = "Installing Required Software"
            Expression = {
                Install-GCPAdditionalSoftware -DoDeploy
            }
        },
        @{ #Install Configuration
            Step = "Installing Configuration"
            Expression = {
                if(-not $AzToken) { Install-GCPConfiguration -Force }
                else { Install-GCPConfiguration -Force -AzToken $AzToken }
            }
        },
        @{ #Configure host-config.json
            Step = "Configuring host-config"
            Expression = {
                $splat = @{
                    ConfigName = "Current"
                    DnsHost = $DnsHostName
                    PrivateKeyPath = (Join-Path $RootPath "GeoCall\ssl\cert.key")
                    PublicCertPath = (Join-Path $RootPath "GeoCall\ssl\cert.cer")
                }

                if(Test-Path (Join-Path $RootPath "GeoCall\ssl\chain.cer")) { $splat.ChainPath = (Join-Path $RootPath "GeoCall\ssl\chain.cer") }
                Set-GCPConfigHostJson @splat
            }
        },
        @{ #Configure maps.xml
            Step = "Configuring maps"
            Expression = {
                Set-GCPConfigMap -ConfigName "Current" -CreateFolders
            }
        },
        @{ #Configure web.map
            Step = "Configuring web"
            Expression = {
                Set-GCPConfigWeb -ConfigName "Current" -Title $StateTitle -DnsHost $DnsHostName
            }
        },
        @{ #Configure security-tokes.txt (apikey)
            Step = "Configuring apikey"
            Expression = {
                Set-GCPConfigApiKey -ConfigName "Current"
            }
        },
        @{ #Configure databases.xml
            Step = "Configuring databases"
            Expression = {
                $splat = @{
                    ConfigName = "Current"
                    SqlServerName = $SqlServerName
                    SqlDbName = $SqlDatabaseName
                    SqlUserName = $SqlUserName
                    SqlUserPass = $SqlPass
                    PgServerName = $PgServerName
                    PgDbName = $PgDatabaseName
                    PgUserName = $PgUserName
                    PgUserPass = $PgPass
                    SqlTimeZone = $SqlTimeZone
                }
                Set-GCPConfigDatabase @splat
            }
        },
        @{ #Setup PostGresDb
            Step = "Setting Up PostGres"
            Expression = {
                Initialize-GCPPostgresDb
            }
        },
        @{ #Setup MsSqlDb
            Step = "Setting Up MSSQL"
            Expression = {
                Initialize-GCPSqlDb -TimeZone $SqlTimeZone
            }
        },
        @{ #Configure System Settings
            Step = "Configuring System Settings"
            Expression = {
                if($DnsHostName -notlike "*.*") {
                    $envName = $DnsHostName.ToUpper()
                    $emailDomain = "noreply-$DnsHostName@$DnsHostName.local" 
                }
                else {
                    $envName, $emailDomain = $DnsHostName -split "\."
                    $envName = $envName.ToLower()
                    $emailDomain = $emailDomain -join "."
                    $emailDomain = "noreply-$envName@$emailDomain"
                    $envName = $envName.ToUpper()
                }
                                
                [hashtable]$AdditionalSettings = @{
                    "app\autocreateuser.admin.from" = $emailDomain
                    "app\autocreateuser.user.from" = $emailDomain
                    "app\resetpassword.user.from" = $emailDomain
                    "app\ticket.sendto.fromaddress" = $emailDomain
                    "email\fromaddress" = $emailDomain
                    "queue\format.auditfrom" = "GA811 $envName"
                    "queue\format.messagefrom" = "GA811 $envName"
                    "queue\format.ticketfrom" = "GA811 $envName"
                }
                Set-GCPSystemSettings -DnsHostName $DnsHostName -OverrideHT $AdditionalSettings
            }
        },
        @{ #Configure GeoCall
            Step = "Installing GeoCall"
            Expression = {
                Install-GCPGeoCall
            }
        },
        @{ #Configure Admin Permissions
            Step = "Configuring Admin Permissions"
            Expression = {
                Set-GCPAdmin -AdminPW "admin" -ResetPermissions
            }
        },
        @{ #Upgrade Database
            Step = "Upgrading Database"
            Expression = {
                try { Start-Service -Name "GeoCallHostService" -ErrorAction "stop" }
                catch {
                    Start-Service -Name "GeoCallHostService" -ErrorAction "stop"
                }
                Stop-Service -Name "GeoCallHostService" -Force
            }
        },
        @{ #Configure UISearch
            Step = "Configuring UISearch"
            Expression = {
                Import-GCPUISearch
            }
        },
        @{ #Upgrade DB-Custom
            Step = "Upgrading Database Custom Schema"
            Expression = {
                Update-GCPSqlDbCustom
            }
        },
        @{ #Start Service
            Step = "Starting GeoCall"
            Expression = {
                Start-Service  -Name "GeoCallHostService"
            }
        }
    )

    [double]$c = $StartAtStep - 1
    if(-not $Silent) { Write-Host ("[{0:HH:mm:ss}] Deployment Starting at Step {1}" -f (Get-Date), $StartAtStep) }

    foreach ($ls in $logicSteps[$c..$logicSteps.Count]) {
        if(-not $Silent) { Write-Host ("[{0:HH:mm:ss}] STEP {1} >> {2}" -f (Get-Date), [int]($c + 1), $ls.Step) }
        Write-Progress -Activity "Invoke-GCPDeployment" -Status $ls.Step -PercentComplete (($c + .51) * 100 / $logicSteps.Count)
        $ls.Expression.Invoke()
        $c += 1
    }

    if(-not $Silent) { Write-Host ("[{0:HH:mm:ss}] Deployment completed" -f (Get-Date)) }
    Write-Progress -Activity "Invoke-GCPDeployment" -Completed
}
Export-ModuleMember -Function Invoke-GCPDeployment