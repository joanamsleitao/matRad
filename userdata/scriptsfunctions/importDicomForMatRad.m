function [ct, cst, pln, resultGUI] = importDicomForMatRad(dicomFolder)
% IMPORTDICOMFORMATRAD - Imports DICOM files into matRad.
% 
%   Inputs:
%       dicomFolder - Path to the folder containing DICOM files.
%
%   Outputs:
%       ct        - CT structure for matRad.
%       cst       - Contour structure from RTSTRUCT.
%       pln       - Treatment plan structure.
%       resultGUI - Dose result (if RTDOSE exists, otherwise empty).
%
%   Example:
%       [ct, cst, pln, resultGUI] = importDicomForMatRad('/path/to/dicom/folder');

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
