% This .m file is used to prepare a JSON file for user to configure
% participation/sensitivity analysis. If the file existed, this program
% will clear the original contents. The JSON file is built based on the
% running results of the toolbox.

% Author: Yue Zhu

% Generated variables:
% UserdataModal: full path of the modal config JSON file
%%
% Set the file saving location. fullfile keeps the path valid on
% Windows, Mac, and Linux.
UserdataModal = SimplusGT.Modal.ConfigPath(UserData);

%%
% write contents in the JSON file.

% *For State PF analysis, Auto-Select will select all states at each apparatus. It will
% also select two modes lower than 100Hz, with most small damping coefficient, but not
% around 0Hz (0.1Hz tollerence) or Fbase(1Hz tollerence).
% *For Impedance PF analysis, Auto-select will select all apparatuses for
% Layer-1 analysis, d-d axis for bode plot, and apparatus-1 for Layer-3
% analysis. As well, it will select two modes with lowest damping.
% Write 1 to enable auto select.
MdAutoSel = 0;

[AutoSelResult] = SimplusGT.IO.WriteModalConfig(N_Bus, N_Apparatus,ApparatusType,ApparatusBus,...
    ApparatusStateStr,ZbusStateStr, GminSS, GsysDSS, MdAutoSel, Fbase, UserdataModal);

fprintf('%s is now ready.\nPlease open the file and select the states and apparatuses you are interested.\n',UserdataModal);
fprintf('After selection, save the JSON file and run SimplusGT.Modal.ModalAnalysis.m.\n');
if MdAutoSel == 0
    SimplusGT.Modal.OpenConfig(UserdataModal);
end
if MdAutoSel == 1 && AutoSelResult == 1
    SimplusGT.Modal.ModalAnalysis % run modal analysis
elseif AutoSelResult == 0  % do nothing
elseif MdAutoSel ==1 && AutoSelResult == 0
    error(['Error: Mode Auto-Selection failed. Please open the ModalConfig JSON file to select the mode manually.'])
else
end

%winopen(UserdataModal);