function [ct, cst, resultGUI] = matRad_loadOrImportDicom(wildcard, wildcardParts, baseFolder)
% matRad_loadOrImportDicom - Loads existing matRad patient data or imports from DICOM
%
% Syntax:  [ct, cst, resultGUI] = matRad_loadOrImportDicom(wildcard, wildcardParts, baseFolder)
%
% Inputs:
%   wildcard       - String with main folder or partial identifier
%   wildcardParts  - Cell array with separated wildcard parts
%   baseFolder     - Root path containing patient folders
%
% Outputs:
%   ct        - matRad CT structure
%   cst       - matRad constraint structure table
%   resultGUI - matRad result structure

% -------------------------------------------------------------------------
% 1. Identify target folder
% -------------------------------------------------------------------------
if nargin < 3
    error('Not enough input arguments. Need wildcard, wildcardParts, baseFolder.');
end

folderMatches = dir(fullfile(baseFolder, ['*', wildcard, '*']));
if isempty(folderMatches)
    error('No folder matching "%s" found in %s', wildcard, baseFolder);
elseif numel(folderMatches) > 1
    error('Multiple folders match "%s". Please refine wildcard.', wildcard);
end

targetFolder = fullfile(folderMatches(1).folder, folderMatches(1).name);

% -------------------------------------------------------------------------
% 2. Detect subfolder if wildcardParts{2} is given
% -------------------------------------------------------------------------
if numel(wildcardParts) > 1 && ~isempty(wildcardParts{2})
    subfolderCandidate = fullfile(targetFolder, wildcardParts{2});
    if exist(subfolderCandidate, 'dir')
        targetFolder = subfolderCandidate;
    end
end

% -------------------------------------------------------------------------
% 3. Determine if this is CT-only or contains dose
% -------------------------------------------------------------------------
isCTonly = isempty(wildcard) || contains(wildcard, 'RTFiles', 'IgnoreCase', true) ...
                              || contains(wildcard, 'CTandStruct', 'IgnoreCase', true);

% -------------------------------------------------------------------------
% 4. MAT file search helper (nested function)
% -------------------------------------------------------------------------
    function matFiles = smartMatSearch()
        % First try sub-part in filename if given
        if numel(wildcardParts) > 1 && ~isempty(wildcardParts{2})
            matFiles = dir(fullfile(targetFolder, ['*', wildcardParts{2}, '*.mat']));
        else
            matFiles = [];
        end
        % If not found, try main wildcard
        if isempty(matFiles) && ~isempty(wildcard)
            matFiles = dir(fullfile(targetFolder, ['*', wildcard, '*.mat']));
        end
        % Fallback: any mat file
        if isempty(matFiles)
            matFiles = dir(fullfile(targetFolder, '*.mat'));
        end
    end

% -------------------------------------------------------------------------
% 5. Helper to handle multiple matches with a nice warning
% -------------------------------------------------------------------------
    function errorWithMatches(searchTerm, matches)
        fprintf('Multiple .mat files match "%s":\n', searchTerm);
        for i = 1:numel(matches)
            fprintf(' - %s\n', matches(i).name);
        end
        error('Please refine your wildcard.');
    end

% -------------------------------------------------------------------------
% 6. CT-only branch
% -------------------------------------------------------------------------
if isCTonly
    matFiles = smartMatSearch();

    if isempty(matFiles)
        fprintf('No mat file found. Importing DICOM from %s...\n', targetFolder);
        dcmImpObj = matRad_DicomImporter(targetFolder);
        matFileSaved = matRadJoana_importDicom(dcmImpObj, targetFolder);
        movefile(matFileSaved, fullfile(targetFolder, 'CtandRTStruct.mat'));
        load(fullfile(targetFolder, 'CtandRTStruct.mat'), 'ct', 'cst', 'resultGUI');
    elseif numel(matFiles) > 1
        if numel(wildcardParts) > 1 && ~isempty(wildcardParts{2})
            errorWithMatches(wildcardParts{2}, matFiles);
        else
            errorWithMatches(wildcard, matFiles);
        end
    else
        load(fullfile(targetFolder, matFiles(1).name), 'ct', 'cst', 'resultGUI');
    end

% -------------------------------------------------------------------------
% 7. Dose-containing branch
% -------------------------------------------------------------------------
else
    matFiles = smartMatSearch();

    if isempty(matFiles)
        fprintf('No matching .mat file found. Importing DICOM from %s...\n', targetFolder);
        dcmImpObj = matRad_DicomImporter(targetFolder);
        matFileSaved = matRadJoana_importDicom(dcmImpObj, targetFolder);
        movefile(matFileSaved, fullfile(targetFolder, 'CtandRTStructAndDose.mat'));
        load(fullfile(targetFolder, 'CtandRTStructAndDose.mat'), 'ct', 'cst', 'resultGUI');
    elseif numel(matFiles) > 1
        if numel(wildcardParts) > 1 && ~isempty(wildcardParts{2})
            errorWithMatches(wildcardParts{2}, matFiles);
        else
            errorWithMatches(wildcard, matFiles);
        end
    else
        load(fullfile(targetFolder, matFiles(1).name), 'ct', 'cst', 'resultGUI');
    end
end

end
