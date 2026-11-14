function WriteSheet(filename, data, sheet, range)
% Write one cell block into an xlsx sheet without Excel COM.
% Argument order matches xlswrite: filename, data, sheet, range.
writecell(data, filename, 'Sheet', sheet, 'Range', range, 'UseExcel', false);
end
