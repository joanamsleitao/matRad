function cstFiltered = matRad_VOIfilterDoseThreshold(cst, doseCube, doseThreshold, mode, outputTxtFile)
% matRad_filterDoseThreshold - Create a CST filtered by dose threshold
%
% Syntax:
%   cstFiltered = matRad_filterDoseThreshold(cst, doseCube, doseThreshold, mode)
%   cstFiltered = matRad_filterDoseThreshold(cst, doseCube, doseThreshold, mode, outputTxtFile)
%
% Inputs:
%   cst           - matRad structure table
%   doseCube      - 3D dose matrix (Gy)
%   doseThreshold - scalar dose threshold (Gy)
%   mode          - string: 'above' or 'below'
%   outputTxtFile - (optional) path to save voxel index info (e.g. 'filtered_voxels.txt')
%
% Output:
%   cstFiltered - CST where each VOI contains only indices of voxels above/below the threshold
%
% Description:
%   For each VOI in the CST, this function checks the dose in all its voxels.
%   It then filters voxel indices depending on the chosen mode:
%      - 'above': voxels with dose >= threshold
%      - 'below': voxels with dose <= threshold
%
% Example:
%   cstFiltered = matRad_filterDoseThreshold(cst, doseCube, 10, 'above');
%
% Author:
%   Joana Leitão + GPT-5, 2025
%
% -------------------------------------------------------------------------

if nargin < 4
    error('Usage: matRad_filterDoseThreshold(cst, doseCube, doseThreshold, mode[, outputTxtFile])');
end

if ~ismember(mode, {'above', 'below'})
    error('mode must be either "above" or "below".');
end

% Initialize output CST
cstFiltered = cst;

% Optional file output
if nargin >= 5 && ~isempty(outputTxtFile)
    fid = fopen(outputTxtFile, 'w');
    fprintf(fid, 'VOI_Name\tOriginalVoxels\tFilteredVoxels\n');
else
    fid = [];
end

% Loop through VOIs
for v = 1:size(cst,1)
    voiName = cst{v,2};
    indices = cst{v,4}{1};  % linear voxel indices
    doses = doseCube(indices);
    
    switch mode
        case 'above'
            keepIdx = doses >= doseThreshold;
        case 'below'
            keepIdx = doses <= doseThreshold;
    end

    % Filter voxel indices
    filteredIndices = indices(keepIdx);

    % Update CST
    cstFiltered{v,4}{1} = filteredIndices;

    % Optionally write info
    if ~isempty(fid)
        fprintf(fid, '%s\t%d\t%d\n', voiName, numel(indices), numel(filteredIndices));
    end
end

% Close text file
if ~isempty(fid)
    fclose(fid);
    fprintf('Voxel index summary saved to: %s\n', outputTxtFile);
end

fprintf('Filtering completed: kept voxels %s %.2f Gy.\n', mode, doseThreshold);

end