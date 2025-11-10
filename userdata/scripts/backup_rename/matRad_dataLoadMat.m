function [ct, cst, pln, stf, resultGUI] = matRad_dataLoadMat(filePath)
% matRad_dataLoadMat
% -------------------------------------------------------------------------
% Safely loads patient data from a MAT file.
% Only loads variables that exist in the file.
%
% Inputs:
%   filePath - path to .mat file
%
% Outputs:
%   ct, cst, pln, stf, resultGUI - standard matRad structures (empty if missing)
%
% Example:
%   [ct, cst, pln, stf, resultGUI] = matRad_dataLoadMat('Patient01_PlanA.mat');
%
% Author: GPT-5 Assistant
% -------------------------------------------------------------------------

% Initialize empty defaults
ct = [];
cst = [];
pln = [];
stf = [];
resultGUI = [];

% Check variables available in MAT file
vars = who('-file', filePath);

if isempty(vars)
    warning('No variables found in MAT file: %s', filePath);
    return;
end

fprintf('Loading variables from MAT file: %s\n', filePath);

% Use selective loading for each field
matObj = matfile(filePath);

if any(strcmp(vars, 'ct'))
    ct = matObj.ct;
else
    fprintf('  ⚠ No "ct" found.\n');
end

if any(strcmp(vars, 'cst'))
    cst = matObj.cst;
else
    fprintf('  ⚠ No "cst" found.\n');
end

if any(strcmp(vars, 'pln'))
    pln = matObj.pln;
else
    fprintf('  ⚠ No "pln" found.\n');
end

if any(strcmp(vars, 'stf'))
    stf = matObj.stf;
else
    fprintf('  ⚠ No "stf" found.\n');
end

if any(strcmp(vars, 'resultGUI'))
    resultGUI = matObj.resultGUI;
else
    fprintf('  ⚠ No "resultGUI" found.\n');
end

fprintf('✓ Loaded available data successfully.\n');

end
