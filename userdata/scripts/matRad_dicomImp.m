function [matRadFileName, ct, cst, pln, stf, resultGUI] = matRad_dicomImp(dcmImpObj, pathToFolder)
% matRad_dicomImp - Import DICOM files into matRad structures
%
% Syntax:
%   [matRadFileName, ct, cst, pln, stf, resultGUI] = matRad_dicomImp(dcmImpObj, pathToFolder)
%
% Inputs:
%   dcmImpObj    - DICOM import object (struct)
%   pathToFolder - Path to save folder (string, optional, default: pwd)
%
% Outputs:
%   matRadFileName - Path to saved MAT file (string)
%   ct, cst, pln, stf, resultGUI - matRad structures
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 2 || isempty(pathToFolder)
    pathToFolder = pwd;
end

% Import DICOM
matRad_importDicom(dcmImpObj);

% Extract structures
ct = dcmImpObj.ct;
cst = dcmImpObj.cst;
pln = dcmImpObj.pln;
stf = dcmImpObj.stf;
resultGUI = dcmImpObj.resultGUI;

% Save to MAT file
patients = dcmImpObj.patients;
matRadFileName = fullfile(pathToFolder, ['matRadPatient', patients{1}, '.mat']);
save('-v7', matRadFileName, 'ct', 'cst', 'pln', 'stf', 'resultGUI');

fprintf('✓ DICOM imported and saved: %s\n', matRadFileName);

end