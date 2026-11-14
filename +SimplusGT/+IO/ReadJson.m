function S = ReadJson(filename)
% Read a JSON file with jsondecode.

if ~isfile(filename)
    error('JSON file not found: %s', filename);
end
txt = fileread(filename);
S = jsondecode(txt);
end
