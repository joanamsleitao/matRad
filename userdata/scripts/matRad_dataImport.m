function [ct, cst, doseCube] = matRad_dataImport(patientName, searchPath, matchPattern)
% matRad_dataImport - Load CT, CST, and doseCube from .mat or DICOM data.
%
% Syntax:
%   [ct, cst, doseCube] = matRad_dataImport(patientName, searchPath, matchPattern)
%
% Inputs:
%   patientName   - String: patient identifier (used in folder and filenames)
%   searchPath    - Path to .mat file OR base folder containing DICOM data
%   matchPattern  - (optional) Identifier for plan/dose (used to filter RTDOSE)
%
% Outputs:
%   ct        - matRad CT struct
%   cst       - matRad CST cell array
%   doseCube  - Dose cube array
%
% Notes:
%   - If searchPath is a .mat file, loads data directly.
%   - Otherwise, tries to locate a matching .mat file in the folder.
%   - If not found, imports DICOM (CT, RTSTRUCT, and RTDOSE with matchPattern).
%

% Initialize outputs
ct = [];
cst = [];
resultGUI = [];
doseCube = [];

%% Case 1: Direct .mat file given
if contains(searchPath, '.mat')
    fprintf('Loading from direct .mat file: %s\n', searchPath);

    matObj = matfile(searchPath);
    vars = who(matObj);

    % Load CT and CST
    load(searchPath, 'ct', 'cst*');
    fprintf('Loaded CT and CST from %s\n', searchPath);

    % Extract doseCube
    if ~ismember('resultGUI', vars) % no resultGUI struct
        if any(contains(vars, 'doseCube'))
            doseVars = vars(contains(vars, 'doseCube'));
            doseVars(contains(doseVars, 'doseCubePat')) = []; % exclude patient-specific versions
            if isempty(doseVars)
                warning('No doseCube found in .mat file!');
            else
                if numel(doseVars) > 1
                    warning('Multiple doseCubes found, using first: %s', doseVars{1});
                end
                tmp = load(searchPath, doseVars{1});
                doseCube = tmp.(doseVars{1});
            end
        end
    else
        load(searchPath, 'resultGUI');
        if isfield(resultGUI, 'physicalDose')
            doseCube = resultGUI.physicalDose;
        elseif isfield(resultGUI, 'RBExDose')
            doseCube = resultGUI.RBExDose;
        end
    end
    return
end

%% Case 2: Folder-based workflow
if nargin < 3
    matchPattern = [];
    fprintf('No plan ID (matchPattern) provided. Will only load CT and RTStruct.\n');
end

% Locate patient folder
[~, patientFolder] = matRad_filePatientPath(patientName);

% --- Default: CT and RTSTRUCT only ---
if isempty(matchPattern) || contains(matchPattern, 'RTFiles')
    wildcardCT = 'CTandRTStruct';
    defaultFolder = fullfile(patientFolder, ['RTFiles_' wildcardCT]);
    matFile = dir(fullfile(defaultFolder, ['*', patientName, '*', wildcardCT, '.mat']));
    matFileName = fullfile(defaultFolder, [patientName, '_', wildcardCT, '.mat' ]);

    if ~isempty(matFile)
        fprintf('Loading CT and RTStruct .mat: %s\n', matFileName);
        load(matFileName, 'ct', 'cst', 'resultGUI');
    else
        fprintf('No .mat file found, importing DICOM from %s...\n', defaultFolder);
        dcmImpObj = matRad_DicomImporter(defaultFolder);
        matFileSaved = matRad_dicomImport(dcmImpObj, defaultFolder);
        movefile(matFileSaved, matFileName);
        load(matFileName, 'ct', 'cst', 'resultGUI');
    end

else
    % --- Try to find .mat file for this plan first ---
    matFiles = dir(fullfile(searchPath, ['*', matchPattern, '*.mat']));

    if isempty(matFiles)
        % No .mat found → import from DICOM
        fprintf('No .mat found for "%s". Importing DICOM...\n', matchPattern);

        % Import all files in searchPath
        dcmImpObj = matRad_DicomImporter(searchPath);

        % Keep only CT, RTSTRUCT, and RTDOSE matching matchPattern
        fileTypes = dcmImpObj.allfiles(:,2);
        filePaths = dcmImpObj.allfiles(:,1);

        rtdose = dcmImpObj.allfiles(contains(filePaths, matchPattern), :);    
        dcmImpObj.importFiles.rtdose = rtdose;

        keepMask = matches(fileTypes, 'CT', 'IgnoreCase', true) | ...
                   matches(fileTypes, 'RTSTRUCT', 'IgnoreCase', true) | ...
                  (matches(fileTypes, 'RTDOSE', 'IgnoreCase', true) & ...
                   contains(filePaths, matchPattern));
        dataImp = dcmImpObj.allfiles(keepMask,:);

        % Ensure CT + RTSTRUCT are available
        hasCT       = any(matches(dcmImpObj.allfiles(:,2), 'CT', 'IgnoreCase', true));
        hasRTStruct = any(matches(dcmImpObj.allfiles(:,2), 'RTSTRUCT', 'IgnoreCase', true));

        if ~(hasCT && hasRTStruct)
            fprintf('CT or RTSTRUCT missing. Checking fallback RTFiles folder...\n');
            rtFilesFolder = fullfile(patientFolder, 'RTFiles_CTandRTStruct');
            if ~isfolder(rtFilesFolder)
                error('RTFiles folder not found for patient "%s".', patientName);
            end
            tmpObj = matRad_DicomImporter(rtFilesFolder);
            dcmImpObj.importFiles.resx = tmpObj.importFiles.resx;
                        dcmImpObj.importFiles.resy = tmpObj.importFiles.resy;
            dcmImpObj.importFiles.resz = tmpObj.importFiles.resz;
dcmImpObj.importFiles.useImportGrid = tmpObj.importFiles.useImportGrid;
            % Add CT and RTSTRUCT from fallback
            dataImp = [
                tmpObj.importFiles.ct; ...
                tmpObj.importFiles.rtss; ...
                rtdose];
            dcmImpObj.importFiles.ct    = tmpObj.importFiles.ct;
            dcmImpObj.importFiles.rtss  = tmpObj.importFiles.rtss;
            dcmImpObj.importFiles.rtdose = rtdose;
        end

        dcmImpObj.allfiles = dataImp;

        % Save to .mat
        newMatName = sprintf('matRadPatient%s_%s.mat', patientName, matchPattern);
        matFileSaved = matRad_dicomImport(dcmImpObj, searchPath);
        newMatPath   = fullfile(searchPath, newMatName);
        movefile(matFileSaved, newMatPath);
        fprintf('Imported and saved: %s\n', newMatPath);

        load(newMatPath, 'ct', 'cst', 'resultGUI');
    elseif numel(matFiles) == 1
        % Load existing mat file
        matFilePath = fullfile(matFiles(1).folder, matFiles(1).name);
        fprintf('Loading existing .mat: %s\n', matFilePath);
        load(matFilePath, 'ct', 'cst', 'resultGUI');
    else
        error('Multiple .mat files match "%s". Please specify more clearly.', matchPattern);
    end
end

%% Extract doseCube from resultGUI if available
if ~isempty(resultGUI)
    if isfield(resultGUI, 'physicalDose')
        doseCube = resultGUI.physicalDose;
    elseif isfield(resultGUI, 'RBExDose')
        doseCube = resultGUI.RBExDose;
    end
end

end
