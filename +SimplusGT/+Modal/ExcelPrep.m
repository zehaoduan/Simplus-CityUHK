function ExcelPrep(FileModal)
% Clear any previous modal-config workbook so ExcelWrite can create a new
% one. Sheets are created by ExcelWrite, in this order: State-PF,
% Impedance-PF, Enabling. The file is written later without Excel COM, so
% the same steps work on Windows, Mac, and Linux.
% Author: Yue Zhu

folder = fileparts(FileModal);
if ~exist(folder, 'dir')
    mkdir(folder);
end
if exist(FileModal, 'file')
    delete(FileModal);
    if exist(FileModal, 'file')
        error('Could not replace %s. Close the workbook if it is open.', FileModal);
    end
end
end
