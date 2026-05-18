# ABA-DB

Here are some notes about storing track measurement data from the ABA project in a PostGIS database.

## PostgreSQL/PostGIS database
Since measurements along rail tracks have an inherent geographical nature a [PostGIS](https://postgis.net/) database seems a natural choice.

PostGIS is an extension of a [PostgreSQL](https://www.postgresql.org/) database. You start with a PostgreSQL database and PostGIS software on the same system and then enable the PostGIS extensions in the PostgreSQL database environment.

At the TU Delft, it is possible to ask the IT department to set up a PostgreSQL database for you. This is best done when you have a good idea of the overall design and the estimated size of the system.

To gain this experience, it is possible to install PostgreSQL/PostGIS on a laptop directly, or using [Docker Desktop](https://www.docker.com/products/docker-desktop/) and a prebuilt image. What follows was tested using a Docker. See [here](https://postgis.net/documentation/getting_started/install_docker/) and [here](https://github.com/postgis/docker-postgis).

```bash
# download the postgresql/postgis image, only once:
docker pull postgis/postgis:18-3.6-alpine
# set up an environment variable with the postgres password:
export POSTGRES_PASSWORD=<secret_password>
```

```bash
docker run --name aba-postgres -p 5432:5432 -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD -d postgis/postgis:18-3.6-alpine
```

To access a terminal window on the PostgreSQL/PostGIS system, you can either use the Docker Desktop app, or from the command line:
```bash
docker exec -it aba-postgres bash
```

You can then use the [`psql`](https://www.postgresql.org/docs/current/app-psql.html) tool, for example, to log into and interact with the database:
```bash
-- log into the database as (default) user 'postgres'
psql -U postgres
-- psql –U postgres –d aba -- if you want to jump straight to database aba


-- create database 'aba'
CREATE database aba;

-- list databases
\l

-- connect to database 'aba'
\connect aba

-- enable postgis extensions, this is from the Windows instructions
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION postgis_sfcgal;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION address_standardizer;
CREATE EXTENSION address_standardizer_data_us;
CREATE EXTENSION postgis_tiger_geocoder;

-- list installed extensions
\dx

-- Create the table to store spoortaks
CREATE TABLE spoortak_traces (
    id SERIAL PRIMARY KEY,
    spoortak_version VARCHAR(100),
    spoortak_name VARCHAR(100),
    geom GEOMETRY(LINESTRING, 4326) -- 4326 is WGS84 (Lat/Lon)
);

-- Create the table to store data gps tracks
CREATE TABLE gps_traces (
    id SERIAL PRIMARY KEY,
    dataset VARCHAR(100),
    geom GEOMETRY(LINESTRING, 4326) -- 4326 is WGS84 (Lat/Lon)
);

-- list tables
\dt

-- quit psql
\q
```

This completes the setup. Here are a few examples of adding data and searching for data with `psql`. However, this will not usually be done by hand with `psql`, but programmatically with MATLAB or Python.
```bash
-- example of loading data into a table
INSERT INTO spoortak_traces(spoortak_version, spoortak_name, geom) VALUES ('SPOORTAK_25', 'Spoortak 001', ST_GeomFromText('LINESTRING(16.38 48.21, 16.39 48.22, 16.40 48.23)', 4326));
INSERT INTO spoortak_traces(spoortak_version, spoortak_name, geom) VALUES ('SPOORTAK_25', 'Spoortak 002', ST_GeomFromText('LINESTRING(16.48 48.21, 16.49 48.22, 16.50 48.23)', 4326));
INSERT INTO spoortak_traces(spoortak_version, spoortak_name, geom) VALUES ('SPOORTAK_25', 'Spoortak 003', ST_GeomFromText('LINESTRING(16.58 48.21, 16.59 48.22, 16.60 48.23)', 4326));	
	
-- show all entries in a table
SELECT * FROM spoortak_traces;

-- show count of entries
SELECT count(*) AS exampt_count FROM spoortak_traces;

-- you can speed up geography searches by creating an index
CREATE INDEX spoortak_geog_idx ON spoortak_traces USING GIST ((geom::geography));

-- can now see extra index
\d spoortak_traces

-- sort spoortaks on distance from CiTG
SELECT spoortak_name, ST_Distance(geom::geography, ST_MakePoint(4.3755, 51.9988)::geography) AS dist_meters
FROM spoortak_traces
WHERE ST_DWithin(
    geom::geography, 
    ST_MakePoint(4.3755, 51.9988)::geography, 
    10000 -- distance in meters
)
ORDER BY dist_meters;

-- find 10 closest spoortaks to CiTG
SELECT spoortak_name, ST_Distance(geom::geography, ST_MakePoint(4.3755, 51.9988)::geography) AS dist_meters
FROM spoortak_traces
ORDER BY dist_meters
LIMIT 10;
```

## MATLAB
Much of the work in the ABA project has been written with MATLAB, so we continue here.
MATLAB has built in functionality to connect to a PostGIS database. See the [documentation](https://nl.mathworks.com/help/database/ug/database.postgre.connection.html).

You need the "Database Toolbox" Add-On and a [JDBC driver](https://nl.mathworks.com/products/database/driver-installation.html).

> [!NOTE]
> Something very strange happens with ports if you run both WSL and GitBash on Windows. WSL PostgreSQL seems to take over port 5432 (used by PostgreSQL by default) and you need to find the process and kill it before you start working with the Docker container.
> ```bash
> netstat -ano | findstr :5432
> # to find PID and then kill it in the Task Manager/Details
> # or on WSL:
> sudo pkill postgres
> ```

## Examples
The 4 MATLAB files in this repository were created with a lot of AI assistance. They demonstrate how to load spoortak data and dataset gps data into their respective tables and how to search these two tables.
