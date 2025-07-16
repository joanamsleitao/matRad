function [ct, cst, doseCube] = loadOrImportPlanningData(patientName)
%LOADORIMPORTPLANNINGDATA Loads patient data from .mat or imports from DICOM
%
% Inputs:
%   patientName - name of the patient (e.g., 'UHEI_005')
%
% Outputs:
%   ct, cst, resultGUI - matRad data structures
%   VOINames - structure parsed from VOINames.txt

    basePath = append('C:\Users\joana\MATLAB_ALL\KIT_STAR\Data\', patientName);
    matFile = append(basePath, '\', patientName, '_PlanningCTandRTDose.mat');

    if isfile(matFile)
        fprintf('Loading existing .mat file for patient %s...\n', patientName);
        load(matFile, 'ct', 'cst', 'resultGUI');
    else
        dicomPath = fullfile(basePath, 'Planning CT and RT Dose');
        fprintf('Importing DICOM data for patient %s...\n', patientName);
        matRadFileName = matRadJoana_importDicom(dicomPath);
        load(matRadFileName, 'ct', 'cst', 'resultGUI');
        movefile(matRadFileName, matFile);  % save renamed version
    end
    doseCube = resultGUI.physicalDose;
    VOINames = parseStructureFile('VOINames.txt');
end
