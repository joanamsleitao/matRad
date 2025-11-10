function [ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImpLoad(patientName, inputPath, varargin)
% matRad_importAndLoad - Flexible import and load of patient data for matRad
% -------------------------------------------------------------------------
% High-level function to import or load patient data from .mat files or DICOM folders.
%
% Features:
%   • Supports loading single .mat files, folders of .mat files, or DICOM folders.
%   • Automatically handles missing CT or CST using fallback MAT or DICOM folders.
%   • Extracts doseCube from resultGUI if available.
%   • Verbose output with warnings for traceability.
%   • Optional saving of imported structures.
%
% Scenarios:
% CASE 1: Single MAT file
%   - Loads a .mat file containing any subset of ct, cst, pln, stf, resultGUI.
%   - Can replace missing CT/CST using fallback MAT file (fallbackMat).
%   - Warns if variables are missing.
%
% CASE 2: Folder of MAT files
%   - Searches for .mat files and optionally matches 'matchPattern'.
%   - Behavior:
%       • Single match: loads that file.
%       • Multiple matches: warns, loads newest matching file.
%       • No match: warns, loads newest available .mat file.
%   - Checks for missing CT/CST and can use fallback MAT or fallback DICOM folder.
%
% CASE 3: DICOM folder
%   - Imports CT, RTSTRUCT, and optionally RTDOSE matching 'matchPattern'.
%   - Uses fallback DICOM folder (fallbackPath) if CT/CST missing.
%   - Skips missing elements with warnings.
%
% Inputs:
%   patientName   - string: patient identifier
%   inputPath     - string: path to a .mat file, folder of .mat files, or DICOM folder
%
% Name-Value Pair Optional Inputs:
%   'matchPattern' - string: plan/dose pattern to match (default: '')
%   'fallbackPath' - string: folder path with CT+RTSTRUCT fallback (default: '')
%   'fallbackMat'  - string: path to .mat file for CT/CST fallback (default: '')
%   'saveDir'      - string: directory to save the resulting imported .mat (default: pwd)
%   'saveOption'   - logical: true = save imported data, false = skip saving (default: true)
%
% Outputs:
%   ct         - matRad CT struct (empty if not available)
%   cst        - matRad CST cell array (empty if not available)
%   pln        - matRad plan struct (empty if not available)
%   stf        - matRad stf struct (empty if not available)
%   resultGUI  - matRad resultGUI struct (empty if not available)
%   doseCube   - extracted dose cube (empty if not available)
%
% Examples:
%   % Example 1: Load a single MAT file without saving
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_importAndLoad('Patient01', 'Patient01.mat', ...
%                                   'saveOption', false);
%
%   % Example 2: Load a folder of MAT files matching a plan and save
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_importAndLoad('Patient01', 'PatientFolder', ...
%                                   'matchPattern', 'PlanA', 'saveOption', true);
%
%   % Example 3: Load a DICOM folder with fallback DICOMs
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_importAndLoad('Patient01', 'DICOM_Folder', ...
%                                   'matchPattern', 'PlanA', ...
%                                   'fallbackPath', 'RTFiles_CTandRTStruct', ...
%                                   'saveOption', true);
%
%   % Example 4: Load a MAT file but replace missing CT/CST from fallback MAT
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_importAndLoad('Patient01', 'Patient01.mat', ...
%                                   'fallbackMat', 'CTandCST_backup.mat', ...
%                                   'saveOption', true);
%
% Author: Joana Leitão + GPT-5 assistant
% -------------------------------------------------------------------------

%% Parse input arguments
p = inputParser;
addParameter(p, 'matchPattern', '');
addParameter(p, 'fallbackPath', '');
addParameter(p, 'fallbackMat', '');
addParameter(p, 'saveDir', pwd);
addParameter(p, 'saveOption', false);
timestamp = datestr(now, 'yyyy-mm-dd_HHMM');
saveNameDefault = ['importedDICOM_%s_%s.mat', patientName, timestamp];
addParameter(p, 'saveName', saveNameDefault);

parse(p, varargin{:});

opts = p.Results;
fprintf('\n=== matRad Patient Import & Load ===\nPatient: %s\n', patientName);

ct = []; cst = []; pln = []; stf = []; resultGUI = []; doseCube = [];

%% CASE 1: Single MAT file
if contains(inputPath, '.mat') % isfile(inputPath) && 
    [ct, cst, pln, stf, resultGUI] = matRad_matLoadSingle(inputPath, opts.fallbackMat);

    % Check for missing CT/CST and fallback
    if (isempty(ct) || isempty(cst))
        if isempty(opts.fallbackMat) && isempty(opts.fallbackPath)
            warning('CT and/or CST are missing in the MAT file, and no fallback MAT or DICOM folder was provided. This might be intentional.');
        else
            fprintf('→ Missing CT/CST will be attempted to be replaced using provided fallback.\n');
        end
    end
else
    %% CASE 2: Folder import (MAT or DICOM)
    if isfolder(inputPath)
        matFiles = dir(fullfile(inputPath, '*.mat'));

        if ~isempty(matFiles)
            % Folder contains MAT files
            [ct, cst, pln, stf, resultGUI] = matRad_loadFolderMat(inputPath, matFiles, opts.matchPattern, opts.fallbackMat, opts.fallbackPath);

            % Check for missing CT/CST and fallback
            if (isempty(ct) || isempty(cst))
                if isempty(opts.fallbackMat) && isempty(opts.fallbackPath)
                    warning('CT and/or CST are missing in the selected MAT file, and no fallback MAT or DICOM folder was provided. This might be intentional.');
                else
                    fprintf('→ Missing CT/CST will be attempted to be replaced using provided fallback.\n');
                end
            end
        else
            % Folder contains DICOMs
            [ct, cst, pln, stf, resultGUI] = matRad_loadFolderDICOM(inputPath, opts.matchPattern, opts.fallbackPath);
        end

    end
end

%% Extract doseCube
doseCube = matRad_doseCubeExtract(resultGUI);

%% Optional saves
if opts.saveOption
    matRad_savePatientMat(patientName, ct, cst, pln, stf, resultGUI, opts.saveDir, opts.saveName);
    fprintf('✓ Data import and save complete.\n\n');
end
