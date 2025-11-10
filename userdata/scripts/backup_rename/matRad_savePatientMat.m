function matRad_savePatientMat(patientName, ct, cst, pln, stf, resultGUI, saveDir, saveName)
% Save imported patient structures to standardized .mat

if nargin < 7 || isempty(saveDir)
    saveDir = pwd;
end

savePath = fullfile(saveDir, saveName);

save('-v7', savePath, 'ct', 'cst', 'pln', 'stf', 'resultGUI');
fprintf('→ Saved patient data to %s\n', savePath);
end
