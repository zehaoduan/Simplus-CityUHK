function OpenConfig(filename)
% Open the modal config JSON on an interactive desktop.
% A batch session, and a Linux session with no display, prints the path.

if exist('batchStartupOptionUsed', 'builtin') && batchStartupOptionUsed
    fprintf('Modal config written to:\n%s\n', filename);
    return
end

try
    if ispc
        winopen(filename);
    elseif ismac
        status = system(sprintf('open "%s"', filename));
        if status ~= 0
            warning('Could not open %s.', filename);
        end
    else
        if isempty(getenv('DISPLAY')) && isempty(getenv('WAYLAND_DISPLAY'))
            fprintf('No display. Modal config written to:\n%s\n', filename);
            return
        end
        status = system(sprintf('xdg-open "%s" >/dev/null 2>&1 &', filename));
        if status ~= 0
            warning('Could not open %s.', filename);
        end
    end
catch ME
    warning('SimplusGT:OpenConfig', '%s', sprintf('Could not open %s: %s', filename, ME.message));
end
end
