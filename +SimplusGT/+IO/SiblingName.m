function out = SiblingName(UserData, suffix)
% Path next to UserData with a new suffix, e.g. '_results.json'.

[p, n, ~] = fileparts(char(UserData));
out = fullfile(p, [n suffix]);
end
