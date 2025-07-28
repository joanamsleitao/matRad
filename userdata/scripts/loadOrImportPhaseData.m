function [ct, cst, refFileName] = loadOrImportPhaseData(patientFolderPath, phaseName)
%LOADORIMPORTPHASEDATA Loads CT & CST from .mat or imports from DICOM
%
% Inputs:
%   patientFolderPath - path to the patient folder (e.g., '...\UHEI_005')
%   phaseName         - folder name or short name (e.g., 'CT 7 phase 211 90% linear' or 'Phase7')
%
% Outputs:
%   ct, cst           - matRad-compatible CT and CST structures

    % --- Extract phase number and percentage ---
    phaseTokens = regexp(phaseName, '(\d+)', 'tokens');
    percentTokens = regexp(phaseName, '(\d+)%', 'tokens');

    if ~isempty(phaseTokens)
        phaseNum = str2double(phaseTokens{1}{1});
    else
        error('Could not extract phase number from input: %s', phaseName);
    end

    if ~isempty(percentTokens)
        percentVal = str2double(percentTokens{1}{1});
    else
        % Try to infer percent from folder name by assuming e.g., 90 is the last number
        if length(phaseTokens) >= 2
            percentVal = str2double(phaseTokens{2}{1});
        else
            error('Could not extract percent from input: %s', phaseName);
        end
    end

    % Build filenames and paths
    refFileName = sprintf('Phase%d_%d.mat', phaseNum, percentVal);
    savePath = fullfile(patientFolderPath, 'CT_&_Structs', refFileName);
    dicomPath = fullfile(patientFolderPath, 'CT_&_Structs', phaseName);

    % Load or import
    if isfile(savePath)
        fprintf('Loading existing .mat for %s...\n', refFileName);
        load(savePath, 'ct', 'cst');
    else
        fprintf('Importing DICOM from folder: %s\n', dicomPath);
        importedFile = matRadJoana_importDicom(dicomPath);
        load(importedFile, 'ct', 'cst');
        movefile(importedFile, savePath);
        fprintf('Saved imported phase as %s\n', refFileName);
    end
end