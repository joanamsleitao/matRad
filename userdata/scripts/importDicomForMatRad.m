function [ct, cst, pln, resultGUI] = importDicomForMatRad(dicomFolder)
% IMPORTDICOMFORMATRAD - Imports DICOM files into matRad structures
%
% Syntax:  [ct, cst, pln, resultGUI] = importDicomForMatRad(dicomFolder)
%
% Inputs:
%   dicomFolder - Path to folder containing DICOM files (string)
%
% Outputs:
%   ct         - CT structure for matRad (struct)
%   cst        - Contour structure from RTSTRUCT (cell array)
%   pln        - Treatment plan structure (struct)
%   resultGUI  - Dose result structure (empty if no RTDOSE present) (struct)
%
% Other m-files required: matRad_importDicom.m
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_importDicom
%
% Example:
%   [ct, cst, pln, resultGUI] = importDicomForMatRad('/path/to/dicom/folder');
    if nargin < 1
        error('Please specify a folder containing DICOM files.');
    end

    % Import DICOM data into matRad
    fprintf('Importing DICOM files from: %s\n', dicomFolder);
    [ct, cst, pln, resultGUI] = matRad_importDicom(dicomFolder);
    
    % Verify data import
    if isempty(ct) || isempty(cst) || isempty(pln)
        error('DICOM import failed: Check the folder for valid RT DICOM files.');
    end

    % Print whether dose information is available
    if isempty(resultGUI)
        fprintf('No RTDOSE data found. Skipping dose processing.\n');
    else
        fprintf('RTDOSE detected. Dose information successfully imported.\n');
    end

    % Print confirmation
    fprintf('DICOM import complete.\n');
end
