function [ct, cst, doseCube] = loadOrImportPlanningData(patientName)
%LOADORIMPORTPLANNINGDATA Loads patient data from .mat or imports from DICOM
%
% Inputs:
%   patientName - name of the patient (e.g., 'UHEI_005')
%
% Outputs:
%   ct, cst, resultGUI - matRad data structures
%   VOINames - structure parsed from VOINames.txt
%
% %%%%%

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
