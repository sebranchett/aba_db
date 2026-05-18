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

% Search for spoortakken near a point
lon = 4.3755; lat = 51.9986; n = 10;
sql = sprintf([ ...
  'SELECT ', ...
  '  spoortak_name, ', ...
  '  ST_Distance(geom::geography, ST_MakePoint(%f, %f)::geography)  ', ...
  '  AS dist_meters ', ...
  'FROM spoortak_traces ', ...
  'ORDER BY dist_meters ', ...
  'LIMIT %d'], lon, lat, n);
disp(sql);
response = fetch(conn, sql);
disp(response);

% Close connection when done
close(conn);
