% ci_server.m – persistent TOML decoding server for toml-test
%
% Started once by ci.bash and kept alive between tests.
% Communicates via files whose paths are passed through environment variables.

addpath(getenv('GITHUB_WORKSPACE'));
if exist('OCTAVE_VERSION', 'builtin') > 0
    addpath(fullfile(getenv('GITHUB_WORKSPACE'), '+toml', 'private'));
end

in_file    = getenv('TOML_IN');
out_file   = getenv('TOML_OUT');
ready_file = getenv('TOML_READY');
done_file  = getenv('TOML_DONE');
error_file = getenv('TOML_ERROR');
init_file  = getenv('TOML_INIT');

% Signal to ci.bash that the server is initialised and ready
fid = fopen(init_file, 'wt'); fclose(fid);

while true
    % Wait for ci.bash to deposit a new TOML file
    while ~exist(ready_file, 'file')
        pause(0.005);
    end
    delete(ready_file);

    ok = 1;
    try
        opts_file = [in_file '.opts'];
        use_dict = exist(opts_file, 'file') && strcmp(strtrim(fileread(opts_file)), '1');
        decoded = toml.read(in_file, 'UseDictionary', use_dict);
        result  = toml.testing.jsonify(decoded);
        fid = fopen(out_file, 'wt');
        fprintf(fid, '%s\n', result);
        fclose(fid);
    catch
        ok = 0;
        fid = fopen(out_file, 'wt'); fclose(fid);
    end

    if ok
        fid = fopen(done_file,  'wt'); fclose(fid);
    else
        fid = fopen(error_file, 'wt'); fclose(fid);
    end
end
