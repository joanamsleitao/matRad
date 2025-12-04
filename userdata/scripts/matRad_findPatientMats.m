function matFiles = matRad_findPatientMats(patientName, varargin)
% matRad_findPatientMats - Find all MAT files for a patient, optionally filtered
%
% Syntax:
%   matFiles = matRad_findPatientMats(patientName)
%   matFiles = matRad_findPatientMats(patientName, matchString)
%   matFiles = matRad_findPatientMats(..., 'searchDir', dir)
%
% Description:
%   Recursively searches for MAT files related to a patient.
%   If matchString is provided, only files containing that string are returned.
%   Otherwise, returns all MAT files containing the patient name.
%
% Inputs:
%   patientName  - Patient identifier (string)
%   matchString  - (optional) Plan/beam identifier to filter results (string)
%
% Name-Value Pairs:
%   'searchDir'  - Root directory to search (default: pwd)
%
% Outputs:
%   matFiles - Struct array with fields: name, folder, date, bytes, datenum
%              (same format as dir() output)
%
% Examples:
%   % Find all MAT files for patient SP03
%   allMats = matRad_findPatientMats('SP03');
%
%   % Find only files matching 'PassivePlusArc'
%   arcMats = matRad_findPatientMats('SP03', 'PassivePlusArc');
%
%   % Search in specific directory
%   mats = matRad_findPatientMats('SP03', 'IMPT', 'searchDir', 'C:\Data');
%
% -------------------------------------------------------------------------
% Author: Joana Leitão 
% -------------------------------------------------------------------------

%% Parse inputs
p = inputParser;
addOptional(p, 'matchString', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'searchDir', pwd, @(x) ischar(x) || isstring(x));
parse(p, varargin{:});

matchString = char(p.Results.matchString);
searchDir   = char(p.Results.searchDir);
patientName = char(patientName);

fprintf('\n=== matRad Find Patient MAT Files ===\n');
fprintf('Patient:    %s\n', patientName);
fprintf('Search dir: %s\n', searchDir);

%% Step 1: Find patient folder (if it exists as a subfolder)
patientFolders = dir(fullfile(searchDir, '**', patientName));
patientFolders = patientFolders([patientFolders.isdir]);
patientFolders(ismember({patientFolders.name}, {'.', '..'})) = [];

if ~isempty(patientFolders)
    % Patient has a dedicated folder - search inside it
    searchRoot = fullfile(patientFolders(1).folder, patientFolders(1).name);
    fprintf('→ Found patient folder: %s\n', searchRoot);
else
    % No dedicated folder - search entire searchDir
    searchRoot = searchDir;
    fprintf('→ No dedicated patient folder found. Searching entire directory.\n');
end

%% Step 2: Build search pattern
if isempty(matchString)
    % Find all MAT files containing patient name
    searchPattern = sprintf('*%s*.mat', patientName);
    fprintf('→ Searching for all MAT files matching: %s\n', searchPattern);
else
    % Find MAT files containing both patient name and match string
    searchPattern = sprintf('*%s*%s*.mat', patientName, matchString);
    fprintf('→ Searching for MAT files matching: %s\n', searchPattern);
end

%% Step 3: Recursive search
matFiles = dir(fullfile(searchRoot, '**', searchPattern));

% Filter out directories (shouldn't happen with .mat, but just in case)
matFiles = matFiles(~[matFiles.isdir]);

%% Step 4: Report results
if isempty(matFiles)
    if isempty(matchString)
        warning('No MAT files found for patient "%s" in:\n  %s', ...
                patientName, searchRoot);
    else
        warning('No MAT files found for patient "%s" matching "%s" in:\n  %s', ...
                patientName, matchString, searchRoot);
    end
    return;
end

fprintf('✓ Found %d MAT file(s):\n', numel(matFiles));
for i = 1:numel(matFiles)
    fprintf('  [%d] %s\n', i, fullfile(matFiles(i).folder, matFiles(i).name));
end

end