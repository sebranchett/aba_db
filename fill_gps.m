% Connect to PostgreSQL database on localhost:5432
% Adjust 'DatabaseName', 'Username', and 'Password' as needed.

dbname = 'aba';
tablename = 'gps_traces';
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

startIndex = 1;
endIndex = 1;
% loop over all files of the format _*_gps_*.DAT in a folder
folder = "<folder_name>";  % folder to search (string or char)
pattern = "_*_gps_*.DAT";                    % filename pattern
files = dir(fullfile(folder, pattern));      % returns struct array

if isempty(files)
    warning("No files match pattern %s in %s", pattern, folder);
end

% Format: skip 1st and 2nd fields, read 3rd and 4th as doubles, skip rest
fmt = '%*s %*f %*f %f %f %*[^\n]';   % fields separated by whitespace/tabs

for k = 1:numel(files)
    dat_file = fullfile(files(k).folder, files(k).name);
    fprintf("Processing %s\n", dat_file);
    fid = fopen(dat_file, "r");
    if fid < 0
        error("Cannot open file: %s", filename);
    end
    C = textscan(fid, fmt, 'Delimiter', '\t', 'CollectOutput', true, 'ReturnOnError', false);
    fclose(fid);
    cols = C{1};        % Nx2 numeric array: cols(:,1) = first %f, cols(:,2) = second %f
    col4 = cols(:,1);   % corresponds to the first %f in fmt
    col5 = cols(:,2);   % corresponds to the second %f in fmt
    % Remove rows where both col5 and col4 equal 0 or NaN in either column
    mask = ~(col5 == 0 & col4 == 0);
    mask = mask & ~isnan(col4) & ~isnan(col5);
    col5 = col5(mask);
    col4 = col4(mask);

    n = height(col5);
    disp(n);
    pts = '';
    for row = 1:n
        pts = sprintf('%s %0.8f %0.8f,', pts, col5(row), col4(row));
    end
    pts(1) = [];  % Remove first space
    pts(end) = [];  % Remove the last comma
    wkt = sprintf('LINESTRING(%s)', pts);
    % disp(wkt);

    % Build SQL (use sprintf to insert numeric values into the WKT)
    sql = sprintf([
        'INSERT INTO gps_traces(dataset, geom) ' ...
        'VALUES (''%s'', ST_GeomFromText(''%s'', 4326))'], ...
        files(k).name, wkt);
    disp(sql);

    % Execute
    curs = exec(conn, sql);
    % Check for errors on cursor
    if isprop(curs, 'Message') && ~isempty(curs.Message)
        error('SQL execution failed: %s', curs.Message);
    end
    % Close cursor
    close(curs);
end

% Commit transaction (if necessary)
% Many drivers autocommit; calling commit is safe when available.
try
    commit(conn);
catch
    % Some connections don't support commit (autocommit); ignore if fails
end

% Close connection when done
close(conn);
