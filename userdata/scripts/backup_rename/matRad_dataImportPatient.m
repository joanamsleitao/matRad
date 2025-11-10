function [ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportPatient(patientName, inputPath, varargin)
% matRad_dataImportPatient - Unified patient data import for matRad
% -------------------------------------------------------------------------
% High-level function to import patient data from .mat files or DICOM folders.
%
% This function provides a flexible and robust workflow for importing patient
% data for matRad, including CT, RTSTRUCT (CST), plans, stf, and resultGUI.
%
% It handles multiple scenarios:
%
% CASE 1: Single MAT file
%   - Loads a .mat file containing any subset of ct, cst, pln, stf, resultGUI.
%   - Automatically checks for missing CT or CST.
%   - Can use a fallback .mat file (fallbackMat) to replace missing CT/CST.
%   - Issues warnings for missing elements.
%
% CASE 2: Folder of MAT files
%   - Searches for .mat files in the folder.
%   - Optionally matches a plan/dose pattern using 'matchPattern'.
%   - Behavior based on matches:
%       • Single match: loads that file.
%       • Multiple matches: warns and loads the **newest** matching file.
%       • No matches: warns and loads the **newest** available .mat file.
%   - Checks for missing CT/CST and can use fallbackMat or fallbackPath (DICOM folder) if needed.
%
% CASE 3: DICOM folder
%   - Imports CT, RTSTRUCT, and optionally RTDOSE matching 'matchPattern'.
%   - Checks for missing CT or RTSTRUCT.
%   - Can use fallbackPath (secondary DICOM folder) for missing data.
%   - Skips missing elements with warnings.
%
% Notes:
%   - Extracts a doseCube from resultGUI if available.
%   - Saves imported structures as 'matRadPatient_<PatientName>_<datetime>.mat' in saveDir.
%   - Provides verbose output and warnings for traceability.
%
% Inputs:
%   patientName   - string: patient identifier
%   inputPath     - string: path to a .mat file, folder of .mat files, or DICOM folder
%
% Name-Value Pair Optional Inputs:
%   'matchPattern' - string: plan/dose pattern to match (default: '')
%   'fallbackPath' - string: folder path containing CT+RTSTRUCT fallback DICOMs (default: '')
%   'fallbackMat'  - string: path to .mat file for CT/CST fallback (default: '')
%   'saveDir'      - string: directory to save the resulting imported .mat file (default: pwd)
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
%   % Example 1: Load a single MAT file
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportPatient('Patient01', 'Patient01.mat');
%
%   % Example 2: Load a folder of MAT files matching a plan
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportPatient('Patient01', 'PatientFolder', ...
%                                      'matchPattern', 'PlanA');
%
%   % Example 3: Load a DICOM folder with fallback DICOMs
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportPatient('Patient01', 'DICOM_Folder', ...
%                                      'matchPattern', 'PlanA', ...
%                                      'fallbackPath', 'RTFiles_CTandRTStruct');
%
%   % Example 4: Load a MAT file but replace missing CT/CST from a fallback MAT
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportPatient('Patient01', 'Patient01.mat', ...
%                                      'fallbackMat', 'CTandCST_backup.mat');
%
%   % Example 5: Load a folder of MAT files without an exact match
%   [ct, cst, pln, stf, resultGUI, doseCube] = matRad_dataImportPatient('Patient01', 'PatientFolder', ...
%                                      'matchPattern', 'NonexistentPlan', ...
%                                      'fallbackMat', 'CTandCST_backup.mat');
%
% Author: Joana Leitão + GPT-5 assistant
% -------------------------------------------------------------------------

%% Parse input arguments
p = inputParser;
addParameter(p, 'matchPattern', '');
addParameter(p, 'fallbackPath', '');
addParameter(p, 'fallbackMat', '');
addParameter(p, 'saveDir', pwd);
parse(p, varargin{:});

opts = p.Results;
fprintf('\n=== matRad Patient Data Import ===\nPatient: %s\n', patientName);

ct = []; cst = []; pln = []; stf = []; resultGUI = []; doseCube = [];

%% CASE 1: Single MAT file
if isfile(inputPath) && contains(inputPath, '.mat')
    [ct, cst, pln, stf, resultGUI] = matRad_matLoadSingle(inputPath, opts.fallbackMat);
    
else
    %% CASE 2: Folder import (MAT or DICOM)
    if isfolder(inputPath)
        matFiles = dir(fullfile(inputPath, '*.mat'));
        
        if ~isempty(matFiles)
            % Folder contains MAT files
            [ct, cst, pln, stf, resultGUI] = matRad_loadFolderMat(inputPath, matFiles, opts.matchPattern, opts.fallbackMat, opts.fallbackPath);
        else
            % Folder contains DICOMs
            [ct, cst, pln, stf, resultGUI] = matRad_loadFolderDICOM(inputPath, opts.matchPattern, opts.fallbackPath);
        end
    else
        error('Input path is not valid: %s', inputPath);
    end
end

%% Extract doseCube
doseCube = matRad_doseCubeExtract(resultGUI);

%% Save imported structures
matRad_savePatientMat(patientName, ct, cst, pln, stf, resultGUI, opts.saveDir);
fprintf('✓ Data import and save complete.\n\n');

end
