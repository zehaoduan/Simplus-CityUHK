%% Before using. 
% State / Impedance participation factor analysis.
% Reference: Participation Analysis in Impedance Models: The Grey-Box Approach for Power System Stability
%  
% Author(s): Yue Zhu

%% Notes
% Before running this program, you need to config the analysis from
% ModalConfig.xlsx, which should be located in the toolbox root folder.
% Note1: apparatus numbering keeps the same as bus numbering. For example: the apparatus
% on bus7 will always be named as Apparatus7.
% Note2: The final results will be saved in MdLayer1, MdLayer2, MdLayer3,
% MdMode, MdStatePF.

%% Basic
% Config workbook. fullfile keeps the path valid on Windows, Mac, and Linux.

UserdataModal = SimplusGT.Modal.ConfigPath(UserData);

%Basic infomation acquirement.

[MdLayer1, MdLayer2, MdLayer3, MdStatePF, MdMode, MdSensResult,ZminSS]=SimplusGT.Modal.ModalAnalysisExe(UserdataModal);

