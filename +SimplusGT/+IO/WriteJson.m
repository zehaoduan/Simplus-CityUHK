function WriteJson(filename, S)
% Write a MATLAB value as pretty-printed JSON.

folder = fileparts(filename);
if ~isempty(folder) && ~exist(folder, 'dir')
    mkdir(folder);
end

S = SimplusGT.IO.ToJsonValue(S);
txt = jsonencode(S, 'PrettyPrint', true);

fid = fopen(filename, 'w', 'n', 'UTF-8');
if fid < 0
    error('Could not write %s.', filename);
end
cleaner = onCleanup(@() fclose(fid));
fwrite(fid, txt, 'char');
end
