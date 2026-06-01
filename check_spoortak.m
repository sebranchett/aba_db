% Connect to PostgreSQL database

dbname = 'aba';
tablename = 'spoortak_traces';
username = 'postgres';
password = 'password';
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

% Check the number of unique versions
sql = sprintf([ ...
  'SELECT COUNT(DISTINCT spoortak_version) AS total_unique_versions ', ...
  'FROM spoortak_traces']);

disp(sql);
response = fetch(conn, sql);
disp('Number of unique spoortak versions:')
disp(response);

sql = sprintf([ ...
    'SELECT DISTINCT spoortak_version  ', ...
    'FROM spoortak_traces  ', ...
    'ORDER BY spoortak_version']);

% List the unique versions
disp(sql);
response = fetch(conn, sql);
disp('Unique spoortak versions:')
disp(response);

% List the number of spoortakken for each version
sql = sprintf([ ...
    'SELECT spoortak_version, COUNT(*) AS record_count ', ...
    'FROM spoortak_traces ', ...
    'GROUP BY spoortak_version ', ...
    'ORDER BY record_count DESC']);

disp(sql);
response = fetch(conn, sql);
disp('Spoortakken per spoortak version:')
disp(response);

% Close connection when done
close(conn);
