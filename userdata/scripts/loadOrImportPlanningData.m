function [ct, cst, doseCube] = loadOrImportPlanningData(patientName)
% loadOrImportPlanningData - Load or import planning CT and dose for a given patient
%
% Syntax:
%   [ct, cst, doseCube] = loadOrImportPlanningData(patientName)
%
% Inputs:
%   patientName - String with patient name (e.g., 'UHEI_005')
%
% Outputs:
%   ct        - matRad CT structure
%   cst       - matRad CST structure
%   doseCube  - Physical dose cube from RTDOSE (if available)
%
% Description:
%   Attempts to locate a .mat file containing planning CT and dose.
%   If not found, imports the data from the DICOM directory and saves it.
%
% Other m-files required: matRadJoana_importDicom, parseStructureFile
% Subfunctions: none
% MAT-files required: *PlanningCTandRTDose*.mat
%
% See also: matRadJoana_importDicom, parseStructureFile
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

files = dir(fullfile(pwd, 'Data', [patientName, '*']));
basePath = fullfile(pwd, 'Data', files.name);

matFileName = ls(fullfile(basePath, ['*PlanningCTandRTDose*', '.mat']));

if size(matFileName,1) > 1
    error('More than one *PlanningCTandRTDose* file detected. Please load manually');
end

matFile = fullfile(basePath, matFileName);

if isfile(matFile)
    fprintf('Loading existing .mat file for patient %s...\n', patientName);
    load(matFileName, 'ct', 'cst', 'resultGUI');
else
    dicomPath = fullfile(basePath, 'Planning CT and RT Dose');
    fprintf('Importing DICOM data for patient %s...\n', patientName);
    matRadFileName = matRadJoana_importDicom(dicomPath);
    load(matRadFileName, 'ct', 'cst', 'resultGUI');
    movefile(matRadFileName, matFileName);  % save renamed version
end
doseCube = resultGUI.physicalDose;
VOINames = parseStructureFile('VOINames.txt');
end
