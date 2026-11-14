function filename = ConfigPath(UserData)
% Full path of the modal config workbook for this user-data file.
% The workbook is stored under Examples/ParticipationAnalysis at the repo
% root. This file lives in +Modal, so the root is three folders up.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
name = char(UserData);
name = strrep(name, '.xlsm', '');
name = strrep(name, '.xlsx', '');
name = strrep(name, '.xls', '');
filename = fullfile(root, 'Examples', 'ParticipationAnalysis', ...
    ['ModalConfig_' name '.xlsx']);
end
