% Connect to PostgreSQL database on localhost:5432
% Adjust 'DatabaseName', 'Username', and 'Password' as needed.

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

% Check connection status
if isempty(conn.Message)
    fprintf('Connected to PostgreSQL at localhost:5432 (database: %s)\n', dbname);
else
    fprintf('Connection failed: %s\n', conn.Message);
end

load("<folder_name>\SPOORTAK_25.mat");
T = Spoortakken.AllGeometry;     % table
n = height(T);
disp(n);

version = 'SPOORTAK_25';

startIndex = 1;
endIndex = n;
oldSpoortak = T(1, 3);
pts = '';
for i = startIndex:endIndex
    spoortak = T(i, 3);
    if spoortak ~= oldSpoortak;
        spoortakName = sprintf('Spoortak %d', oldSpoortak);
        pts(1) = [];  % Remove first space
        pts(end) = [];  % Remove the last comma
        wkt = sprintf('LINESTRING(%s)', pts);
        % disp(wkt);

        % Build SQL (use sprintf to insert numeric values into the WKT)
        sql = sprintf([
            'INSERT INTO spoortak_traces(spoortak_version, spoortak_name, geom) ' ...
            'VALUES (''%s'', ''%s'', ST_GeomFromText(''%s'', 4326))'], ...
            version, spoortakName, wkt);
        % disp(sql);
        
        % Execute
        curs = exec(conn, sql);
        % Check for errors on cursor
        if isprop(curs, 'Message') && ~isempty(curs.Message)
            error('SQL execution failed: %s', curs.Message);
        end
        % Close cursor
        close(curs);

        % Commit transaction (if necessary)
        % Many drivers autocommit; calling commit is safe when available.
        try
            commit(conn);
        catch
            % Some connections don't support commit (autocommit); ignore if fails
        end

        oldSpoortak = spoortak;
        pts = '';
    end
    pts = sprintf('%s %0.8f %0.8f,', pts, T(i, 1), T(i, 2) );
end
spoortakName = sprintf('Spoortak %d', oldSpoortak);
pts(1) = [];  % Remove first space
pts(end) = [];  % Remove the last comma
wkt = sprintf('LINESTRING(%s)', pts);
% disp(wkt);

% Build SQL (use sprintf to insert numeric values into the WKT)
sql = sprintf([
    'INSERT INTO spoortak_traces(spoortak_version, spoortak_name, geom) ' ...
    'VALUES (''%s'', ''%s'', ST_GeomFromText(''%s'', 4326))'], ...
    version, spoortakName, wkt);
% disp(sql);

% Execute
curs = exec(conn, sql);
% Check for errors on cursor
if isprop(curs, 'Message') && ~isempty(curs.Message)
    error('SQL execution failed: %s', curs.Message);
end
% Close cursor
close(curs);

% Commit transaction (if necessary)
% Many drivers autocommit; calling commit is safe when available.
try
    commit(conn);
catch
    % Some connections don't support commit (autocommit); ignore if fails
end

% Close connection when done
close(conn);
