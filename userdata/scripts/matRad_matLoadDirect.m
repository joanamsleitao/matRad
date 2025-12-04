function [ct, cst, pln, stf, resultGUI] = matRad_matLoadDirect(filePath)
% matRad_matLoadDirect - Load available matRad variables from a MAT file by path
%
% Syntax:
%   [ct, cst, pln, stf, resultGUI] = matRad_matLoadDirect(filePath)
%
% Description:
%   Safely loads standard matRad variables from a MAT file. Only variables
%   that exist in the file are loaded; missing ones are returned empty.
%
% Inputs:
%   filePath - Full path to .mat file (string)
%
% Outputs:
%   ct        - matRad CT struct (empty if not found)
%   cst       - matRad CST cell array (empty if not found)
%   pln       - matRad plan struct (empty if not found)
%   stf       - matRad steering file struct (empty if not found)
%   resultGUI - matRad resultGUI struct (empty if not found)
%
% Example:
%   [ct, cst, pln, stf, resultGUI] = matRad_matLoadDirect('C:\Data\myFile.mat');
%
% -------------------------------------------------------------------------
% Author: Joana Leitão 
% -------------------------------------------------------------------------

ct = [];
cst = [];
pln = [];
stf = [];
resultGUI = [];

if ~isfile(filePath)
    warning('matRad_matLoadDirect:FileNotFound', ...
            'MAT file not found: %s', filePath);
    return;
end

vars = who('-file', filePath);

if isempty(vars)
    warning('matRad_matLoadDirect:EmptyFile', ...
            'No variables found in MAT file: %s', filePath);
    return;
end

fprintf('Loading variables from MAT file: %s\n', filePath);

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

fprintf('✓ matRad_matLoadDirect: Loaded available data successfully.\n');

end