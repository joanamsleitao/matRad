function [ct, cst, doseCube, resultGUI] = matRad_matLoad(patientName, matchString, varargin)
% matRad_matLoad - Load CT, CST, and doseCube from .mat file
%
% Syntax:
%   [ct, cst, doseCube, resultGUI] = matRad_matLoad(patientName, matchString)
%   [ct, cst, doseCube, resultGUI] = matRad_matLoad(..., 'searchDir', dir)
%
% Description:
%   Searches for a .mat file matching the patient name and plan string.
%   Loads ct, cst, doseCube, and resultGUI if available.
%
% Inputs:
%   patientName  - Patient identifier (string)
%   matchString  - Plan identifier (string)
%
% Name-Value Pairs:
%   'searchDir' - Directory to search for .mat files (default: pwd)
%
% Outputs:
%   ct        - matRad CT struct (empty if not found)
%   cst       - matRad CST cell array (empty if not found)
%   doseCube  - Dose cube array (empty if not found)
%   resultGUI - matRad resultGUI struct (empty if not found)
%
% Example:
%   [ct, cst, doseCube, resultGUI] = matRad_matLoad('Patient01', 'PlanA');
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

%% Parse inputs
p = inputParser;
addParameter(p, 'searchDir', pwd);
parse(p, varargin{:});
opts = p.Results;

fprintf('\n=== matRad MAT File Load ===\n');
fprintf('Patient: %s\n', patientName);
fprintf('Plan: %s\n', matchString);

%% Initialize outputs
ct = [];
cst = [];
doseCube = [];
resultGUI = [];

%% Search Strategy 1: Full patient file (exact match)
fullFileName = sprintf('matRadPatient_%s_%s.mat', patientName, matchString);
fullFilePath = fullfile(opts.searchDir, fullFileName);

if isfile(fullFilePath)
    fprintf('→ Loading full patient file: %s\n', fullFileName);
    [ct, cst, doseCube, resultGUI] = loadMatFile(fullFilePath);
    return;
end

%% Search Strategy 2: Full patient file (wildcard match)
% Pattern: *patientName*matchString*.mat
searchPattern = sprintf('*%s*%s*.mat', patientName, matchString);
matFiles = dir(fullfile(opts.searchDir, searchPattern));

if ~isempty(matFiles)
    if numel(matFiles) > 1
        warning('Multiple files match pattern "%s". Using newest file.', searchPattern);
        [~, idx] = max([matFiles.datenum]);
        matFiles = matFiles(idx);
    end
    
    fullFilePath = fullfile(matFiles.folder, matFiles.name);
    fprintf('→ Loading matched file: %s\n', matFiles.name);
    [ct, cst, doseCube, resultGUI] = loadMatFile(fullFilePath);
    return;
end

%% Search Strategy 3: Separate CT/CST + doseCube files
ctCstPattern = sprintf('ct_cst_%s.mat', patientName);
ctCstFiles = dir(fullfile(opts.searchDir, ctCstPattern));

dosePattern = sprintf('doseCube_%s_%s.mat', patientName, matchString);
doseFiles = dir(fullfile(opts.searchDir, dosePattern));

% Try wildcard for doseCube if exact match fails
if isempty(doseFiles)
    dosePattern = sprintf('doseCube*%s*%s*.mat', patientName, matchString);
    doseFiles = dir(fullfile(opts.searchDir, dosePattern));
end

if ~isempty(ctCstFiles) && ~isempty(doseFiles)
    % Load CT/CST
    ctCstPath = fullfile(ctCstFiles(1).folder, ctCstFiles(1).name);
    fprintf('→ Loading CT/CST from: %s\n', ctCstFiles(1).name);
    tmp = load(ctCstPath, 'ct', 'cst');
    ct = tmp.ct;
    cst = tmp.cst;
    
    % Load doseCube
    if numel(doseFiles) > 1
        warning('Multiple dose files match. Using newest.');
        [~, idx] = max([doseFiles.datenum]);
        doseFiles = doseFiles(idx);
    end
    
    dosePath = fullfile(doseFiles(1).folder, doseFiles(1).name);
    fprintf('→ Loading doseCube from: %s\n', doseFiles(1).name);
    tmp = load(dosePath, 'doseCube');
    doseCube = tmp.doseCube;
    
    fprintf('✓ Loaded successfully.\n');
    return;
end

%% No matching file found
warning('No .mat file found for patient "%s" and plan "%s" in directory: %s', ...
        patientName, matchString, opts.searchDir);

end

%% Helper function to load variables from a MAT file
function [ct, cst, doseCube, resultGUI] = loadMatFile(filePath)
    ct = [];
    cst = [];
    doseCube = [];
    resultGUI = [];
    
    vars = who('-file', filePath);
    
    if ismember('ct', vars)
        tmp = load(filePath, 'ct');
        ct = tmp.ct;
    end
    
    if ismember('cst', vars)
        tmp = load(filePath, 'cst');
        cst = tmp.cst;
    end
    
    if ismember('resultGUI', vars)
        tmp = load(filePath, 'resultGUI');
        resultGUI = tmp.resultGUI;
    end
    
    if ismember('doseCube', vars)
        tmp = load(filePath, 'doseCube');
        doseCube = tmp.doseCube;
    else
        % Try to extract from resultGUI
        doseCube = matRad_doseCubeExtract(resultGUI);
    end
    
    fprintf('✓ Loaded successfully.\n');
end