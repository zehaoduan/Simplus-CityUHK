function filename = ConfigPath(UserData)
% Full path of the modal config JSON for this user-data file.
% The file is stored under Examples/ParticipationAnalysis at the repo
% root. This file lives in +Modal, so the root is three folders up.

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
[~, name, ~] = fileparts(char(UserData));
filename = fullfile(root, 'Examples', 'ParticipationAnalysis', ...
    ['ModalConfig_' name '.json']);
end
