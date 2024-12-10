

#      _                                       _     _ _     _ 
#   __| | __ _  ___ _ __ ___   ___  _ __   ___| |__ (_) | __| |
#  / _` |/ _` |/ _ \ '_ ` _ \ / _ \| '_ \ / __| '_ \| | |/ _` |
# | (_| | (_| |  __/ | | | | | (_) | | | | (__| | | | | | (_| |
#  \__,_|\__,_|\___|_| |_| |_|\___/|_| |_|\___|_| |_|_|_|\__,_|
#                                                           

# Collects initial SQL Database files for Apache Guacamole
# Releases: https://guacamole.apache.org/releases/


$GuacVersions = ("1.5.0", "1.5.1", "1.5.2", "1.5.3", "1.5.4", "1.5.5")
$Latest = $GuacVersions[-1]

# Check whether docker is available
Function Test-DockerInPath() {
    Return ($null -ne (Get-Command "docker" -ErrorAction SilentlyContinue))    
}

# Generate initdb files for a single version
Function Get-GuacSQL ($Version) {

    $TemplateFilename   = "guacamole-initdb-DBMS-vVER.sql.txt"
    $MySQLPath      = "mysql\"+$TemplateFilename.Replace("DBMS","mysql").Replace("VER",$Version)
    $PostgresPath   = "postgres\"+$TemplateFilename.Replace("DBMS","postgres").Replace("VER",$Version)

    If (Test-DockerInPath) {
        
        Write-Host "Working: " -NoNewline -ForegroundColor Blue
        Write-Host "Fetching $Version docker image. Wait." -ForegroundColor Yellow

        # Collect Guacamole Client, generate SQL using built in script
        (docker pull guacamole/guacamole:$Version) *> $null

        If ($Version -lt "1.5.2") {
            (docker run --rm guacamole/guacamole:$Version /opt/guacamole/bin/initdb.sh --postgres | Set-Content -Path $PostgresPath)
        } Else {
            (docker run --rm guacamole/guacamole:$Version /opt/guacamole/bin/initdb.sh --postgresql | Set-Content -Path $PostgresPath) 
        }

        (docker run --rm guacamole/guacamole:$Version /opt/guacamole/bin/initdb.sh --mysql | Set-Content -Path $MySQLPath) 

        If (Test-Path $MySQLPath) {
            Write-Host "OK: " -NoNewline -ForegroundColor Green
            Write-Host "MySQL :)" -ForegroundColor White
            (Get-FileHash -Path $MySQLPath -Algorithm SHA256).Hash | Set-Content -Path "$MySQLPath.sha256"
            Write-Host $MySQLPath, (Get-FileHash -Path $MySQLPath -Algorithm SHA256).Hash -ForegroundColor DarkCyan
            # Create the 'latest' file
            If ($Version -eq $Latest) {
                Write-Host "-- Latest Version" -ForegroundColor Cyan
                $LatestMySQLPath = $MySQLPath.Replace("v$Version", "latest")
                Copy-Item $MySQLPath $LatestMySQLPath
                (Get-FileHash -Path $LatestMySQLPath -Algorithm SHA256).Hash | Set-Content -Path "$LatestMySQLPath.sha256"
            }

        } Else {
            Write-Host "FAIL: " -NoNewline -ForegroundColor Green
            Write-Host "MySQL :(" -ForegroundColor Red
        }

        If (Test-Path $PostgresPath) {
            Write-Host "OK: " -NoNewline -ForegroundColor Green
            Write-Host "Postgres :)" -ForegroundColor White
            (Get-FileHash -Path $PostgresPath -Algorithm SHA256).Hash | Set-Content -Path "$PostgresPath.sha256"
            # Create the 'latest' file
            If ($Version -eq $Latest) {
                $LatestPostgresPath = $PostgresPath.Replace("v$Version", "latest")
                Write-Host "-- Latest Version" -ForegroundColor Cyan
                Copy-Item $PostgresPath $LatestPostgresPath
                (Get-FileHash -Path $LatestMySQLPath -Algorithm SHA256).Hash | Set-Content -Path "$LatestPostgresPath.sha256"
            }
        } Else {
            Write-Host "FAIL: " -NoNewline -ForegroundColor Green
            Write-Host "Postgres :(" -ForegroundColor Red
        }

        # Delete The Image 
        #(docker image rm guacamole/guacamole:$Version) *> $null

    } else {
        Write-Host "Error! " -NoNewline -ForegroundColor Red
        Write-Host "Could not run 'docker'. Is it installed?" -ForegroundColor White
    }

}

# Get All in a List
Function Get-GuacSQLAll ($Versions) {

    Foreach ($Version in $Versions) {
        Get-GuacSQL -Version $Version
    }

    "Last Generated: " + (Get-Date) | Set-Content -Path Files-Last-Generated.txt
}


# Welcome Note
Write-Host "Guacamole Initial SQL" -ForegroundColor Blue
Write-Host "Known Versions: " -NoNewline -ForegroundColor Green
Write-Host $GuacVersions -ForegroundColor White
Write-Host
Write-Host "Quick start: " -NoNewline -ForegroundColor Green
Write-Host "Get-GuacSQLAll -Versions `$GuacVersions" -ForegroundColor White
    

