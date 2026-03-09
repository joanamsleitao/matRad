function [ct, cst, pln, resultGUI] = matRad_dicomImpDose(patientName, dicomPath, matchStrings, varargin)
% matRad_dicomImpDose - Import DICOM CT, RTSTRUCT, and one/multiple RTDOSE
%
% Syntax:
%   matRad_dicomImpDose(patientName, dicomPath, matchStrings)
%   matRad_dicomImpDose(..., 'fallbackPath', path, 'saveDir', dir)
%
% Description:
%   Imports CT and RTSTRUCT once, then imports one or multiple RTDOSE
%   series matching the provided strings. Saves as:
%
%   • Single dose:
%       matRadPatient_<patientName>_<planName>.mat
%       (ct, cst, resultGUI, doseCube)
%
%   • Multiple doses:
%       ct_cst_<patientName>.mat            (ct, cst)
%       doseCube_<patientName>_<plan>.mat   (doseCube only, per plan)
%
% Inputs:
%   patientName   - Patient identifier (string)
%   dicomPath     - Path to DICOM folder (string)
%   matchStrings  - String or cell array of plan identifiers
%
% Name-Value Pairs:
%   'fallbackPath' - Fallback DICOM folder for CT/RTSTRUCT (default: '')
%   'saveDir'      - Directory to save files (default: pwd)
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

patientName = char(patientName);
dicomPath   = char(dicomPath);

if nargin < 3
    matchStrings = '*';
end

if ischar(matchStrings) || isstring(matchStrings)
    matchStrings = {char(matchStrings)};
end

if isempty(opts.fallbackPath)
    opts.fallbackPath = dicomPath;
end

ct = [];
cst = [];
pln = [];
resultGUI = [];

fprintf('\n=== matRad DICOM Import (CT/RTSTRUCT/RTDOSE) ===\n');
fprintf('Patient:    %s\n', patientName);
fprintf('DICOM path: %s\n', dicomPath);
fprintf('Plans:      %s\n', strjoin(matchStrings, ', '));

%% Step 1: Import CT and RTSTRUCT once
fprintf('→ Scanning DICOM folder...\n');
dcmImpObj = matRad_DicomImporter(dicomPath);

hasCT       = isfield(dcmImpObj.importFiles, 'ct')   && ~isempty(dcmImpObj.importFiles.ct);
hasRTStruct = isfield(dcmImpObj.importFiles, 'rtss') && ~isempty(dcmImpObj.importFiles.rtss);

if (~hasCT || ~hasRTStruct) 
    fprintf('→ Using fallback for CT/RTSTRUCT: %s\n', opts.fallbackPath);
    tmpObj = matRad_DicomImporter(char(opts.fallbackPath));
    
    if ~hasCT
        dcmImpObj.importFiles.ct = tmpObj.importFiles.ct;
    end
    if ~hasRTStruct
        dcmImpObj.importFiles.rtss = tmpObj.importFiles.rtss;
    end
    
    dcmImpObj.importFiles.resx = tmpObj.importFiles.resx;
    dcmImpObj.importFiles.resy = tmpObj.importFiles.resy;
    dcmImpObj.importFiles.resz = tmpObj.importFiles.resz;
    dcmImpObj.importFiles.useImportGrid = tmpObj.importFiles.useImportGrid;
end

% Import only CT + RTSTRUCT
dcmImpObj.importFiles.rtdose = {};
matRad_importDicom(dcmImpObj);

ct  = dcmImpObj.ct;
cst = dcmImpObj.cst;

fprintf('✓ CT and RTSTRUCT imported.\n');

%% Step 2: Save CT/CST if multiple doses
if numel(matchStrings) > 1 || isequal(matchStrings, {char('*')})
    ctCstName = sprintf('ct_cst_%s.mat', patientName);
    ctCstPath = fullfile(opts.saveDir, ctCstName);
    save(ctCstPath, 'ct', 'cst', '-v7');
    fprintf('✓ Saved CT/CST: %s\n', ctCstName);
end

%% Step 3: For each plan, import RTDOSE and save
allFiles = dcmImpObj.allfiles;

for i = 1:numel(matchStrings)
    planName = matchStrings{i};
    fprintf('\n→ Processing plan: %s\n', planName);
    
    rtdoseMask = strcmpi(allFiles(:,2), 'RTDOSE') & contains(allFiles(:,1), planName);
    
    if ~any(rtdoseMask)
        warning('No RTDOSE found for plan "%s". Skipping.', planName);
        continue;
    end
    
    tmpImpObj = dcmImpObj;
    tmpImpObj.importFiles.rtdose = allFiles(rtdoseMask, :);
    
    matRad_importDicom(tmpImpObj);
    resultGUI = tmpImpObj.resultGUI;
    [doseCube, type]  = matRad_doseCubeExtract(resultGUI);
    
    % if numel(matchStrings) == 1
    %     % Single dose: full patient file
    %     saveName = sprintf('matRadPatient_%s_%s.mat', patientName, planName);
    %     savePath = fullfile(opts.saveDir, saveName);
    %     save(savePath, 'ct', 'cst', 'resultGUI', 'doseCube', '-v7');
    %     fprintf('✓ Saved patient file: %s\n', saveName);
    % else
    %     % Multiple doses: only doseCube
    %     saveName = sprintf('doseCube_%s_%s_%s.mat', ...
    %         patientName, type, planName);
    %     savePath = fullfile(opts.saveDir, saveName);
    %     save(savePath, 'doseCube', '-v7');
    %     fprintf('✓ Saved doseCube file: %s\n', saveName);
    % end
end

fprintf('\n✓ DICOM import complete. %d plan(s) processed.\n', numel(matchStrings));

end