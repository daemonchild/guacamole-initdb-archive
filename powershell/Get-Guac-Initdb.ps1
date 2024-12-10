

#      _                                       _     _ _     _ 
#   __| | __ _  ___ _ __ ___   ___  _ __   ___| |__ (_) | __| |
#  / _` |/ _` |/ _ \ '_ ` _ \ / _ \| '_ \ / __| '_ \| | |/ _` |
# | (_| | (_| |  __/ | | | | | (_) | | | | (__| | | | | | (_| |
#  \__,_|\__,_|\___|_| |_| |_|\___/|_| |_|\___|_| |_|_|_|\__,_|
#                                                           

# Collects initial SQL Database files for Apache Guacamole
# Releases: https://guacamole.apache.org/releases/

# Update when a new version is released
# (I should really automate this...)

$GuacVersions = ("1.5.0", "1.5.1", "1.5.2", "1.5.3", "1.5.4", "1.5.5")
$Latest = $GuacVersions[-1]

# Function to check whether docker is available
Function Test-DockerInPath() {

    Return ($null -ne (Get-Command "docker" -ErrorAction SilentlyContinue))    
}

# Generate initdb files for a single version
Function Get-GuacSQL () {

    param (
        [Parameter(Mandatory=$True)]
        [String] $Version,
        [Parameter(Mandatory=$False)]
        [Switch] $DeleteImage
    )

    # Create Path Variables
    $TemplateFilename   = "guacamole-initdb-DBMS-vVER.sql.txt"
    $BasePath = "archive\"
    $MySQLPath      = $BasePath + "mysql\"+$TemplateFilename.Replace("DBMS","mysql").Replace("VER",$Version)
    $PostgresqlPath   = $BasePath + "postgresql\"+$TemplateFilename.Replace("DBMS","postgres").Replace("VER",$Version)

    # No docker in the command path, no point continuing!
    If (Test-DockerInPath) {
        
        Write-Host 
        Write-Host "Working: " -NoNewline -ForegroundColor Blue
        Write-Host "Fetching Offical guacamole/guacamole:$Version docker image. Please wait." -ForegroundColor Yellow

        # Collect Guacamole Client, generate SQL using built in script
        (docker pull guacamole/guacamole:$Version) *> $null

        # Version 1.5.1 and below use the parameter "postgres", while afterwards it is "postgresql"
        If ($Version -lt "1.5.2") {
            $psqlParam = "postgres"
        } Else {
            $psqlParam = "postgresql"
        }
        (docker run --rm guacamole/guacamole:$Version /opt/guacamole/bin/initdb.sh --$psqlParam | Set-Content -Path $PostgresqlPath) 
        (docker run --rm guacamole/guacamole:$Version /opt/guacamole/bin/initdb.sh --mysql | Set-Content -Path $MySQLPath) 

        # If successful, write Sha256 Hashes 
        # MySQL
        If (Test-Path $MySQLPath) {
            Write-Host "OK: " -NoNewline -ForegroundColor White
            Write-Host "MySQL :)" -ForegroundColor Green

            (Get-FileHash -Path $MySQLPath -Algorithm SHA256).Hash | Set-Content -Path "$MySQLPath.sha256.txt"
            Write-Host "  Created: $MySQLPath"
            Write-Host "  SHA256:" (Get-FileHash -Path $MySQLPath -Algorithm SHA256).Hash -ForegroundColor DarkCyan

        } Else {
            Write-Host "FAIL: " -NoNewline -ForegroundColor White
            Write-Host "MySQL :(" -ForegroundColor Red
        }

        # Postgresql
        If (Test-Path $PostgresqlPath) {
            Write-Host "OK: " -NoNewline -ForegroundColor White
            Write-Host "Postgres :)" -ForegroundColor Green
            (Get-FileHash -Path $PostgresqlPath -Algorithm SHA256).Hash | Set-Content -Path "$PostgresqlPath.sha256.txt"
            Write-Host "  Created: $PostgresqlPath"
            Write-Host "  SHA256:" (Get-FileHash -Path $PostgresqlPath -Algorithm SHA256).Hash -ForegroundColor DarkCyan
         
        } Else {
            Write-Host "FAIL: " -NoNewline -ForegroundColor White
            Write-Host "Postgresql :(" -ForegroundColor Red
        }

        If ($Version -eq $Latest) {

            Write-Host "Working: " -NoNewline -ForegroundColor Blue
            Write-Host "This is the latest version, creating 'latest' file version" -ForegroundColor Yellow
            $LatestMySQLPath = $MySQLPath.Replace("v$Version", "latest")
            $LatestPostgresqlPath = $PostgresqlPath.Replace("v$Version", "latest")
            Copy-Item $MySQLPath $LatestMySQLPath
            Copy-Item $PostgresqlPath $LatestPostgresqlPath
            (Get-FileHash -Path $LatestMySQLPath -Algorithm SHA256).Hash | Set-Content -Path "$LatestMySQLPath.sha256"
            (Get-FileHash -Path $LatestPostgresqlPath -Algorithm SHA256).Hash | Set-Content -Path "$LatestPostgresqlPath.sha256"
            
        }

        # Delete The Image
        If ($DeleteImage) {
            Write-Host "Working: " -NoNewline -ForegroundColor Blue
            Write-Host "Deleting local guacamole/guacamole:$Version docker image." -ForegroundColor Yellow
            (docker image rm guacamole/guacamole:$Version) *> $null
        }   

    } else {
        Write-Host "FAIL! " -NoNewline -ForegroundColor White
        Write-Host "Could not find 'docker' in the command path. Is it installed?" -ForegroundColor Red
    }

}



# Get All in a List
Function Get-GuacSQL-All () {

    param (
        [Parameter(Mandatory=$True)]
        [array] $Versions,
        [Parameter(Mandatory=$False)]
        [Switch] $DeleteImage
    )

    Foreach ($Version in $Versions) {
        If ($DeleteImage) {
            Get-GuacSQL -Version $Version -DeleteImage
        } Else {
            Get-GuacSQL -Version $Version 
        }
    }

    # Set last generated file for reference
    (Get-Date) | Set-Content -Path "archive\__archive_last_regenerated_date__.txt"
}


# Welcome Note
Write-Host "Guacamole InitDB Archive Generator" -ForegroundColor Blue
Write-Host "Known Good Versions: " -NoNewline -ForegroundColor Green
Write-Host $GuacVersions -ForegroundColor White
Write-Host
Write-Host "Usage: " -ForegroundColor Green
Write-Host "   Get-GuacSQL-All -Versions `$GuacVersions [-DeleteImage]" -ForegroundColor White
Write-Host "   Get-GuacSQL     -Version  [some version] [-DeleteImage]" -ForegroundColor White
Write-Host
    

