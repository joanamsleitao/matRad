function [ct, cst, pln, stf, resultGUI] = matRad_dicomImportPath(inputPath, secondPath)
% matRad_dicomImportPath - Imports DICOM data from a primary folder,
% optionally using a fallback folder if CT or RTSTRUCT are missing.
%
% USAGE:
%   [ct, cst, pln, stf, resultGUI] = matRad_dicomImportPath(inputPath)
%   [ct, cst, pln, stf, resultGUI] = matRad_dicomImportPath(inputPath, secondPath)
%
% INPUTS:
%   inputPath  - Path to folder containing DICOM dose/plan/struct/CT
%   secondPath - (optional) Path to fallback RTFiles folder (for CT + RTSTRUCT)
%
% OUTPUTS:
%   ct, cst, pln, stf, resultGUI - Standard matRad structures

ct = [];
cst = [];
pln = [];
stf = [];
resultGUI = [];

% --- Import from primary path ---
dcmImpObj = matRad_DicomImporter(inputPath);

% --- Check if CT and RTSTRUCT were found ---
hasCT = isfield(dcmImpObj.importFiles, 'ct') && ~isempty(dcmImpObj.importFiles.ct);
hasRTStruct = isfield(dcmImpObj.importFiles, 'rtss') && ~isempty(dcmImpObj.importFiles.rtss);

if ~hasCT || ~hasRTStruct
    warning('CT or RTSTRUCT missing in main DICOM folder. Need RT files.');
end

% --- If missing and fallback provided, try to recover ---
if (~hasCT || ~hasRTStruct) && nargin > 1 && ~isempty(secondPath)
    fprintf('CT or RTSTRUCT missing. Checking fallback RTFiles folder...\n');

    if ~isfolder(secondPath)
        error('Fallback folder not found: %s', secondPath);
    end

    tmpObj = matRad_DicomImporter(secondPath);

    % Merge data: keep original dose, replace CT and RTSTRUCT
    dcmImpObj.importFiles.resx = tmpObj.importFiles.resx;
    dcmImpObj.importFiles.resy = tmpObj.importFiles.resy;
    dcmImpObj.importFiles.resz = tmpObj.importFiles.resz;
    dcmImpObj.importFiles.useImportGrid = tmpObj.importFiles.useImportGrid;

    % Replace or add missing CT and RTSTRUCT
    if ~hasCT
        dcmImpObj.importFiles.ct = tmpObj.importFiles.ct;
    end
    if ~hasRTStruct
        dcmImpObj.importFiles.rtss = tmpObj.importFiles.rtss;
    end
end

matRad_importDicom(dcmImpObj);

% --- Finalize import ---
ct = dcmImpObj.ct;
cst = dcmImpObj.cst;
pln = dcmImpObj.pln;
stf = dcmImpObj.stf;
resultGUI = dcmImpObj.resultGUI;

% --- Save imported structures ---
saveName = sprintf('importedDICOM_%s.mat', datetime('now','Format',"yyyyMMdd"));
savePath = fullfile(pwd, saveName);
save('-v7', savePath, 'ct', 'cst', 'pln', 'stf', 'resultGUI');

fprintf('DICOM import completed and saved to %s\n', savePath);
end
