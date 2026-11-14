function WriteModalResults(filename, MdLayer1, MdLayer2, MdLayer3, MdStatePF, MdMode, MdSensResult)
% Write participation-analysis results already computed by ModalAnalysisExe.

R = struct();
R.MdMode = MdMode;
R.MdLayer1 = MdLayer1;
R.MdLayer2 = MdLayer2;
R.MdLayer3 = MdLayer3;
R.MdStatePF = MdStatePF;
R.MdSensResult = MdSensResult;
SimplusGT.IO.WriteJson(filename, R);
fprintf('Modal results written to:\n%s\n', filename);
end
