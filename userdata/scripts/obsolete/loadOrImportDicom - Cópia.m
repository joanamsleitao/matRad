function [ct, cst, doseCube] = loadOrImportDicom(patientName, wildcard)
% LOADORIMPORTDICOM - Load patient CT, CST, and dose data from .mat or DICOM
%
% Syntax:
%   [ct, cst, resultGUI] = loadOrImportDicom(patientName)
%   [ct, cst, resultGUI] = loadOrImportDicom(patientName, wildcard)
%
% Inputs:
%   patientName - string, patient identifier (e.g., 'UHEI_005')
%   wildcard    - optional string wildcard to specify DICOM/mat file selection
%                 (e.g., '*PlanningCTandRTDose*'). If empty or missing,
%                 defaults to loading CT and RTStruct only.
%
% Outputs:
%   ct         - CT structure loaded or imported
%   cst        - Contour structure loaded or imported
%   resultGUI  - Dose and other results structure loaded or imported
%
% Other m-files required: matRad_DicomImporter.m, matRadJoana_importDicom.m
% Subfunctions: none
% MAT-files required: CtandRTStruct.mat or wildcard-specified .mat files (if present)
%
% See also: matRad_DicomImporter, matRadJoana_importDicom
%

% Initialize outputs in case of failure
ct = [];
cst = [];
resultGUI = [];

if nargin < 2
    wildcard = '';
    fprintf('Wildcard not provided. Loading only CT and RTStruct data.\n');
end

% Find patient folder under ./Data/
patientFolderList = dir(fullfile(pwd, 'Data', ['*', patientName, '*']));
if isempty(patientFolderList)
    error('Patient folder for %s not found in ./Data.', patientName);
end
patientFolder = fullfile(pwd, 'Data', patientFolderList(1).name);

if isempty(wildcard) && (contains(wildcard, 'RTFiles') || contains(wildcard, 'CTandStruct'))
    % === Case 1: No wildcard or loading RTFiles_CTandRTStruct ===
    wildcardFolderName = 'RTFiles_CTandRTStruct';
    wildcardFolder = fullfile(patientFolder, wildcardFolderName);

    matFileName = fullfile(wildcardFolder, 'CtandRTStruct.mat');

    if isfile(matFileName)
        fprintf('Loading existing CT and RTStruct mat file for patient %s...\n', patientName);
        load(matFileName, 'ct', 'cst', 'resultGUI');
    else
        % Import DICOM from folder and save mat file
        fprintf('No mat file found. Importing DICOM from %s for patient %s...\n', 	wildcardFolderName, patientName);
        dcmImpObj = matRad_DicomImporter(wildcardFolder);
        matFileSaved = matRadJoana_importDicom(dcmImpObj, wildcardFolder);
        movefile(matFileSaved, matFileName);
        load(matFileName, 'ct', 'cst', 'resultGUI');
    end

    % elseif contains(wildcard, 'CTandStruct'))
    %     % === Case 2: ===
    %     wildcardParts = split(wildcard, '_');
    %     wildcardFolderName = ['*', wildcardParts{1}];
    %     wildcardFolderList = dir(fullfile(patientFolder, [wildcardFolderName, '*']));
    %     if isempty(wildcardFolderList)
    %         error('No folder found matching wildcardFolderName %s in patient folder.', wildcardFolderName);
    %     end
    %     wildcardFolder = fullfile(patientFolder, wildcardFolderList(1).name);
    %
    %     wildcardParts{2}
    %     matFileName = fullfile(wildcardFolder, 'CtandRTStruct.mat');
    %
    %     if isfile(matFileName)
    %         fprintf('Loading existing CT and RTStruct mat file for patient %s...\n', patientName);
    %         load(matFileName, 'ct', 'cst', 'resultGUI');
    %     else
    %         % Import DICOM from folder and save mat file
    %         fprintf('No mat file found. Importing DICOM from %s for patient %s...\n', wildcardFolderName, patientName);
    %         dcmImpObj = matRad_DicomImporter(wildcardFolder);
    %         matFileSaved = matRadJoana_importDicom(dcmImpObj, wildcardFolder);
    %         movefile(matFileSaved, matFileName);
    %         load(matFileName, 'ct', 'cst', 'resultGUI');
    %     end
else
    % === Case 2: wildcard specified, try loading mat file or import DICOM with dose ===
    wildcardParts = split(wildcard, '_');
    wildcardFolderName = ['*', wildcardParts{1}];
    wildcardFolderList = dir(fullfile(patientFolder, [wildcardFolderName, '*']));
    if isempty(wildcardFolderList)
        error('No folder found matching wildcardFolderName %s in patient folder.', wildcardFolderName);
    end
    wildcardFolder = fullfile(patientFolder, wildcardFolderList(1).name);

    % Form .mat file wildcard pattern (with leading '*')
    matWildcard = ['*', wildcard, '.mat'];
    matFiles = dir(fullfile(wildcardFolder, matWildcard));

    % Check if it is in subfolder
    if isempty(dir(fullfile(wildcardFolder, matWildcard)))
        matWildcard = ['*', wildcardParts{2}, '.mat'];
        wildcardFolder = fullfile(wildcardFolder, wildcardParts{2});
        matFiles = dir(fullfile(wildcardFolder, matWildcard));
    end


    if isempty(matFiles)
        % No mat file found: import DICOM and save
        fprintf(['No matching .mat file found.']);

        % Check if we have .dcm in this folder or need to go to another
        if isempty(dir(fullfile(wildcardFolder, '*.dcm')))
            wildcardFolder = fullfile(wildcardFolder, wildcardParts{2});
            % Check again
            if isempty(dir(fullfile(wildcardFolder, '*.dcm')))
                error('Something is wrong');
            end
        end

        fprintf([' Importing DICOM from %s for patient %s...\n'], wildcardFolder, patientName);

        dcmImpObj = matRad_DicomImporter(wildcardFolder);

        % Handle possible missing CT import (like original)
        if isempty(dcmImpObj.importFiles.ct)
            dcmImpObj_CTStruct = matRad_DicomImporter(fullfile(patientFolder, 'RTFiles_CtandRTStruct'));
            doseNumber = find(contains(dcmImpObj_CTStruct.allfiles(:,2), 'RTDOSE'));
            if isempty(doseNumber)
                warning('There are dose files found in the RTFiles_CTandRTFlash folder.')
            end

            col1 = dcmImpObj.allfiles(:,1);
            rowNumber = find(contains(col1, replace(wildcard, '*', '') + ".dcm"));

            % Copy rtdose importFiles entries
            dcmImpObj_CTStruct.importFiles.rtdose = dcmImpObj.importFiles.rtdose(rowNumber, :);

            s = size(dcmImpObj_CTStruct.allfiles, 1);
            dcmImpObj_CTStruct.allfiles(s+1, :) = dcmImpObj.allfiles(rowNumber, :);


            dcmImpObj = dcmImpObj_CTStruct;
        end

        doseNumber = find(contains(dcmImpObj.allfiles(:,2), 'RTDOSE'));

        if ~isempty(doseNumber)
            if sum(contains(dcmImpObj.allfiles(:,2), 'RTDOSE')) > 1
                warning('More than one dose found. Please review');
            end

            strings = split(dcmImpObj.allfiles(doseNumber(end), 1), '\');
            n = find(contains(strings, '.dcm'));
            doseName = strings{n};

            fprintf('Importing DICOM dose from %s...\n', doseName);

                    newMatName = sprintf('matRadPatient%s_%s.mat', patientName, replace(doseName, '.dcm', ''));
        else
                    newMatName = sprintf('matRadPatient%s_%s.mat', patientName, wildcardParts{2});
        end

        matFileSaved = matRadJoana_importDicom(dcmImpObj, wildcardFolder);
        % Rename imported mat file to meaningful name
        [~, dicomName, ~] = fileparts(matFileSaved);
        newMatPath = fullfile(wildcardFolder, newMatName);
        movefile(matFileSaved, newMatPath);
        load(newMatPath, 'ct', 'cst', 'resultGUI');

    elseif length(matFiles) > 1
        error('More than one .mat file matches the wildcard. Please be more specific.');
    else
        % Load the existing mat file
        matFilePath = fullfile(wildcardFolder, matFiles(1).name);
        fprintf('Loading existing .mat file %s for patient %s...\n', matFiles(1).name, patientName);
        load(matFilePath, 'ct', 'cst', 'resultGUI');
    end
end

% Extract doseCube if available
doseCube = [];
if isfield(resultGUI, 'physicalDose')
    doseCube = resultGUI.physicalDose;
elseif isfield(resultGUI, 'RBExDose')
    doseCube = resultGUI.RBExDose;
end

end
