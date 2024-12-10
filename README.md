
# guacamole-initdb-archive
## Apache Guacamole Initial SQL Database Archive

 This is an archive of the Apache Guacamole "InitDB.SQL" files from version 1.5.0 of Guacamole onwards. When you use an external database, it needs to be initialised with the database schema for Guacamole to utilise.

As Apache put it themselves:

![Apache's Note](https://github.com/daemonchild/guacamole-initdb-archive/blob/main/docs/apache-important-note.png)
 
The latest version included is: **1.5.5**

It is simple to generate these files, but it is an additional step that needs to be considered when building using infrastructure as code, such as Terraform or ARM templates.

This archive simply saves you from generating them for your project; you can just pull the relevant file directly from this repository as a raw file.

A PowerShell script is included in case you wish to make your own. You will need docker available. The script pulls each of the official Apache Guacamole docker images in turn, uses this to create both the postgresql and mysql database files.

### Links to Guacamole documentation, how to generate these files:
- [Installing Guacamole with Docker — MySQL Authentication](https://guacamole.apache.org/doc/gug/guacamole-docker.html#mysql-authentication)
- [Installing Guacamole with Docker — Postgresql Authentication](https://guacamole.apache.org/doc/gug/guacamole-docker.html#postgresql-authentication)

**Note:**
While the links mention using the database for authentication, an external DB can also used for storing user-to-desktop connection information even if you intend to use SAML for user auth.





## Quick Links - Latest Version

**MySQL**

https://raw.githubusercontent.com/daemonchild/guacamole-initdb-archive/main/mysql/guacamole-initdb-mysql-latest.sql


**Postgresql**

https://raw.githubusercontent.com/daemonchild/guacamole-initdb-archive/main/postgresql/guacamole-initdb-postgres-latest.sql

 

## How to use the these files

If you set up a postgresql container something like this:

```
docker volume create guac-postgresql-data
docker run -d --restart=always --name guac-postgres -p 5432:5432 \
	-v guac-postgresql-data:/var/lib/postgresql/data \
	-e POSTGRES_DB="guacamole_db" -e POSTGRES_PASSWORD="blahblahblah" \
	postgres:latest
```

You could pull and inject the latest Guacamole initial database straight from the archive like this:
```
curl https://raw.githubusercontent.com/daemonchild/guacamole-initdb-archive/main/postgresql/guacamole-initdb-postgres-latest.sql | docker exec -i guac-postgresql \ 
	psql --username=postgres guacamole_db
```

You also need to set up a dedicated user to allow Guacamole to access this database once initialised. For reference, this is the SQL needed to set up this Guacamole user and allow remote access:
```
CREATE USER guac_db_user WITH PASSWORD 'reallynotagreatpassword';
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO guac_user;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO guac_db_user;
```
Please, please change the username and password in the above examples before you use this code anywhere!


## How to use the PowerShell Script
Should you wish to run the PowerShell script yourself, this is how to import the module. It tries to be helpful, mainly to remind me how to use it as it's pretty far between version releases!

```
PS> import-Module .\powershell\Get-Guac-Initdb.ps1

Guacamole InitDB Archive Generator
Known Good Versions: 1.5.0 1.5.1 1.5.2 1.5.3 1.5.4 1.5.5

Usage: 
   Get-GuacSQL-All -Versions $GuacVersions [-DeleteImage]
   Get-GuacSQL     -Version [some version]  [-DeleteImage]
```
You can generate a single version, including older ones from the releases archive, or recreate the entire archive:
```
PS> Get-GuacSQL-All -Versions $GuacVersions -DeleteImage

Working: Fetching Offical guacamole/guacamole:1.5.0 docker image. Please wait.
OK: MySQL :)
  Created: archive\mysql\guacamole-initdb-mysql-v1.5.0.sql.txt
  SHA256: C4BB03F2FD0B84CCCC6A1395AE306C256E3B8D3C29DEC427EECDC7C581E10C27
OK: Postgres :)
  Created: archive\postgresql\guacamole-initdb-postgres-v1.5.0.sql.txt
  SHA256: A3D376EA48C58EEC9543B606BEC91717601C55879F9310F1D517C8A151CA68F4
Working: Deleting local guacamole/guacamole:1.5.0 docker image.

[.. output snipped for brevity ..]

Working: Fetching Offical guacamole/guacamole:1.5.5 docker image. Please wait.
OK: MySQL :)
  Created: archive\mysql\guacamole-initdb-mysql-v1.5.5.sql.txt
  SHA256: C4BB03F2FD0B84CCCC6A1395AE306C256E3B8D3C29DEC427EECDC7C581E10C27
OK: Postgres :)
  Created: archive\postgresql\guacamole-initdb-postgres-v1.5.5.sql.txt
  SHA256: A3D376EA48C58EEC9543B606BEC91717601C55879F9310F1D517C8A151CA68F4
Working: This is the latest version, creating 'latest' file version
Working: Deleting local guacamole/guacamole:1.5.5 docker image.   

```



## Licensing
The output generated and stored in the archive is under license from the Apache Foundation; I claim no ownership of the output SQL files. They are provided as a service to the Internet to ease Guacamole deployments. 

(Apache Guacamole Releases: [Apache Guacamole™: Release Archives](https://guacamole.apache.org/releases/))