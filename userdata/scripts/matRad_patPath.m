function [targetPath, patientFolder] = matRad_patPath(patientID, searchFolder, searchFile)
% matRad_patPath - Locate patient data folders/files flexibly
%
% USAGE:
%   [targetPath, patientFolder, targetName] = matRad_patPath(patientID)
%       -> finds patient folder and its RTFiles subfolder
%
%   [targetPath, patientFolder, targetName] = matRad_patPath(patientID, searchFolder)
%       -> finds patient subfolder containing 'searchFolder' in its name
%
%   [targetPath, patientFolder, targetName] = matRad_patPath(patientID, searchFolder, searchFile)
%       -> finds specific file (searchFile) inside the subfolder matching 'searchFolder'
%
%   [targetPath, patientFolder, targetName] = matRad_patPath(patientID, [], searchFile)
%       -> finds folder where a file named 'searchFile' exists directly under patientFolder
%
% INPUTS:
%   patientID    - String identifier for the patient folder (unique match expected)
%   searchFolder - (optional) String to match subfolder name (e.g. "RTFiles" or "PlanX")
%   searchFile   - (optional) String to match a specific filename inside folder
%
% OUTPUTS:
%   targetPath    - Full path to the found folder or file
%   patientFolder - Base patient folder
%   targetName    - Name of the found folder or file
%
% Notes:
%   - Always picks the *first match* if multiple exist (warns in that case).
%   - Uses recursive search (via **).
%

%% --- Find patient folder ---
matches = dir(fullfile(pwd, '**', patientID));
matches = matches([matches.isdir]); % only folders
matches(ismember({matches.name},{'.','..'})) = [];

if isempty(matches)
    error('Patient folder for "%s" not found in current directory tree.', patientID);
% elseif numel(matches) > 1
%     warning('Multiple patient folders found for "%s". Using first: %s', ...
%         patientID, fullfile(matches(1).folder, matches(1).name));
end

patientFolder = fullfile(matches(1).folder);
targetPath = [];
targetName = [];

%% --- Case 1: Only patientID ---
if nargin == 1
    rtFiles = dir(fullfile(patientFolder, '**', '*RTFiles*'));
    rtFiles = rtFiles([rtFiles.isdir]);

    if isempty(rtFiles)
        error('No RTFiles folder found for patient "%s".', patientID);
    elseif numel(rtFiles) > 1
        warning('Multiple RTFiles folders found, using first: %s', rtFiles(1).name);
    end

    targetPath = fullfile(rtFiles(1).folder, rtFiles(1).name);
    targetName = rtFiles(1).name;
    return;
end

%% --- Case 2: Patient + searchFolder (subfolder) ---
if nargin == 2 || (nargin == 3 && isempty(searchFile))
    subDirs = dir(fullfile(patientFolder, '**'));
    subDirs = subDirs([subDirs.isdir]);
    subDirs(ismember({subDirs.name},{'.','..'})) = [];

    matches = subDirs(contains({subDirs.name}, searchFolder));
    if isempty(matches)
        error('No subfolder matching "%s" found for patient "%s".', searchFolder, patientID);
    elseif numel(matches) > 1
        warning('Multiple subfolders match "%s". Using first: %s', searchFolder, matches(1).name);
    end

    targetPath = fullfile(matches(1).folder, matches(1).name);
    targetName = matches(1).name;
    return;
end

%% --- Case 3: Patient + searchFolder + searchFile ---
if nargin == 3 && ~isempty(searchFolder)
    % Search for searchFile INSIDE the folder(s) matching searchFolder
    subDirs = dir(fullfile(patientFolder, '**', ['*' searchFolder '*']));
    subDirs = subDirs([subDirs.isdir]);
    subDirs(ismember({subDirs.name},{'.','..'})) = [];

    if isempty(subDirs)
        error('No subfolder matching "%s" found for patient "%s".', searchFolder, patientID);
    end

    % Loop through subfolders to find the file
    found = false;
    for k = 1:numel(subDirs)
        candidateFolder = fullfile(subDirs(k).folder, subDirs(k).name);
        f = dir(fullfile(candidateFolder, '**', searchFile));
        if ~isempty(f)
            % Take first match if multiple found
            if numel(f) > 1
                warning('Multiple files "%s" found in "%s". Using first: %s', searchFile, candidateFolder, f(1).name);
            end
            targetPath = fullfile(f(1).folder, f(1).name);
            targetName = f(1).name;
            found = true;
            break;
        end
    end

    if ~found
        error('File "%s" not found inside any folder matching "%s".', searchFile, searchFolder);
    end
    return;
end

%% --- Case 4: Patient + [] + searchFile ---
if nargin == 3 && isempty(searchFolder)
    % Search for searchFile in the patientFolder recursively
    f = dir(fullfile(patientFolder, ['*', searchFile, '*']));
    if isempty(f)
        error('File "%s" not found under patient folder "%s".', searchFile, patientFolder);
    elseif numel(f) > 1
        warning('Multiple files "%s" found under patient folder. Using first: %s', searchFile, f(1).name);
    end

    targetPath = fullfile(f(1).folder, f(1).name);
    targetName = f(1).name;
    return;
end

end
