% Connect to PostgreSQL database

dbname = 'aba';
tablename = 'spoortak_traces';
username = 'postgres';
password = '<password>';
driver = 'org.postgresql.Driver';
url = 'jdbc:postgresql://localhost:5432/';
classpath = '<path_to_driver>\postgresql-42.7.10.jar';
% e.g. '/usr/share/java/postgresql.jar' or full path to the JDBC jar

% Add JDBC driver to Java classpath for this session if not already present
if ~any(strcmpi(javaclasspath('-dynamic'), classpath))
    javaaddpath(classpath);
end

% Create database connection
conn = database(dbname, username, password, driver, url);
disp(conn.Message)

% Check connection status
if isempty(conn.Message)
    fprintf('Connected to PostgreSQL at localhost:5432 (database: %s)\n', dbname);
else
    fprintf('Connection failed: %s\n', conn.Message);
end

tolerance_meters = .2;

sql = sprintf([ ...
  'SELECT ', ...
  '  v25.spoortak_name AS name_25, ', ...
  '  v24.spoortak_name AS name_24, ', ...
  '  ST_Distance(v25.geom::geography, v24.geom::geography) AS dist_meters ', ...
  'FROM spoortak_traces v25 ', ...
  'INNER JOIN spoortak_traces v24 ', ...
  '  ON ST_DWithin(v25.geom::geography, v24.geom::geography, %f) ', ...
  'WHERE v25.spoortak_version = ''SPOORTAK_25'' ', ...
  '  AND v24.spoortak_version = ''SPOORTAK_24'''], tolerance_meters);

disp(sql);
response = fetch(conn, sql);
disp('Same spoortak from different versions:')
disp(response);

% Close connection when done
close(conn);
