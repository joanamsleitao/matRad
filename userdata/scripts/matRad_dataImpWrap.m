function [ct, cst, doseCube, resultGUI] = matRad_dataImpWrap(patientName, inputPath, matchString, varargin)
% matRad_dataImpWrap - Wrapper to load from MAT or import from DICOM
%
% Syntax:
%   [ct, cst, doseCube, resultGUI] = matRad_dataImpWrap(patientName, inputPath, matchString)
%   [ct, cst, doseCube, resultGUI] = matRad_dataImpWrap(..., 'fallbackPath', path, 'saveDir', dir)
%
% Description:
%   Unified access:
%     • If inputPath is a MAT file → load from MAT (ignores DICOM).
%     • If inputPath is a folder:
%         - Try to load MAT from saveDir by patient+plan
%         - If no MAT exists → import DICOM from inputPath and save MATs
%   For multiple plans, call matRad_dicomImpDose directly and then
%   load per plan with matRad_matLoad.
%
% Inputs:
%   patientName - Patient identifier (string)
%   inputPath   - Path to DICOM folder or MAT file (string)
%   matchString - Plan identifier (string or cell array)
%
% Name-Value Pairs:
%   'fallbackPath' - Fallback DICOM folder for CT/RTSTRUCT (default: '')
%   'saveDir'      - Directory to save/search MAT files (default: pwd)
%
% Outputs:
%   ct, cst, doseCube, resultGUI
%
% -------------------------------------------------------------------------
% Author: Joana Leitão 
% -------------------------------------------------------------------------

%% Parse inputs
p = inputParser;
addParameter(p, 'fallbackPath', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'saveDir', pwd, @(x) ischar(x) || isstring(x));
parse(p, varargin{:});
opts = p.Results;
dirpwc = opts.saveDir;
opts.saveDir = fullfile(dirpwc, 'Data', patientName);

patientName = char(patientName);
inputPath   = char(inputPath);

fprintf('\n=== matRad Data Import Wrapper ===\n');
fprintf('Patient: %s\n', patientName);
fprintf('Input :  %s\n', inputPath);

ct = []; cst = []; doseCube = []; resultGUI = [];

%% Case 1: Direct MAT file
if isfile(inputPath) && contains(lower(inputPath), '.mat')
    fprintf('→ Detected MAT file. Loading directly.\n');
    [ct, cst, doseCube, resultGUI] = matRad_matLoad(patientName, matchString, ...
                                                    'searchDir', fileparts(inputPath));
    return;
end

%% Case 2: Multiple plans requested → only DICOM import, no direct outputs
if iscell(matchString)
    fprintf('→ Multiple plans requested. Importing from DICOM only.\n');
    matRad_dicomImpDose(patientName, inputPath, matchString, ...
                        'fallbackPath', opts.fallbackPath, ...
                        'saveDir', opts.saveDir);
    fprintf('  You can now load each plan with matRad_matLoad.\n');
    return;
end

matchString = char(matchString);

%% Case 3: Folder input, single plan
if isfolder(inputPath)
    % Try to load from existing MAT (in saveDir)
    fprintf('→ Checking for existing MAT in: %s\n', inputPath);
    [ct, cst, doseCube, resultGUI] = matRad_matLoad(patientName, matchString, ...
                                                    'searchDir', inputPath);
    if ~isempty(ct) || ~isempty(doseCube)
        fprintf('✓ Loaded from existing MAT file.\n');
        return;
    end
    
    % No MAT found → import from DICOM then load
    fprintf('→ No MAT found. Importing from DICOM folder: %s\n', inputPath);
    matRad_dicomImpDose(patientName, inputPath, matchString, ...
                        'fallbackPath', opts.fallbackPath, ...
                        'saveDir', opts.saveDir);
    
    [ct, cst, doseCube, resultGUI] = matRad_matLoad(patientName, matchString, ...
                                                    'searchDir', opts.saveDir);
    return;
end

error('Input path is neither a valid MAT file nor a folder: %s', inputPath);

end