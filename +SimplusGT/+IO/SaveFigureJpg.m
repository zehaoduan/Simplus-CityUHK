function SaveFigureJpg(fig, filename)
% Save fig as a high-definition JPEG, replacing any file already at filename.
%
% The JPEG is rendered from the paper size: 10 inches on the long side at
% 300 dpi, which is 3000 pixels. exportgraphics follows the on-screen size,
% so a small figure, or one larger than the virtual screen, is not that
% wide. Paper settings are restored on exit.

filename = char(filename);
if isfile(filename)
    delete(filename);
end

drawnow;

state.Units = fig.Units;
state.Position = fig.Position;
state.PaperUnits = fig.PaperUnits;
state.PaperPosition = fig.PaperPosition;
state.PaperPositionMode = fig.PaperPositionMode;
state.PaperSize = fig.PaperSize;
state.InvertHardcopy = fig.InvertHardcopy;
restoreState = onCleanup(@() restoreFigure(fig, state)); %#ok<NASGU>

fig.Units = 'pixels';
pos = fig.Position;
longPx = max(pos(3), pos(4));
shortPx = min(pos(3), pos(4));
if longPx <= 0
    longPx = 1;
    shortPx = 1;
end
longIn = 10;
shortIn = longIn * (shortPx / longPx);
if pos(3) >= pos(4)
    widthIn = longIn;
    heightIn = shortIn;
else
    widthIn = shortIn;
    heightIn = longIn;
end

fig.InvertHardcopy = 'on';
fig.PaperUnits = 'inches';
fig.PaperPositionMode = 'manual';
fig.PaperSize = [widthIn heightIn];
fig.PaperPosition = [0 0 widthIn heightIn];
print(fig, filename, '-djpeg', '-r300');

fprintf('Figure written to:\n%s\n', filename);
end

function restoreFigure(fig, state)
if ~isgraphics(fig)
    return;
end
fig.Units = state.Units;
fig.Position = state.Position;
fig.PaperUnits = state.PaperUnits;
fig.PaperPositionMode = state.PaperPositionMode;
fig.PaperPosition = state.PaperPosition;
fig.PaperSize = state.PaperSize;
fig.InvertHardcopy = state.InvertHardcopy;
end
