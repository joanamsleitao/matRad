function voxelMask = matRad_VOIDoseThrMask(cst, doseCube, voiSelection, doseThreshold)
% matRad_VOIDoseThresholdMask - Find voxels above a dose threshold within VOIs
%
% Syntax:
%   voxelMask = matRad_VOIDoseThresholdMask(cst, doseCube, voiSelection, doseThreshold)
%
% Inputs:
%   cst            - matRad CST structure
%   doseCube       - 3D dose distribution (Gy)
%   voiSelection   - cell array of VOI names to check
%   doseThreshold  - scalar dose threshold (Gy)
%
% Output:
%   voxelMask      - 3D logical mask, true where dose > threshold inside selected VOIs
%
% Example:
%   mask = matRad_filterDoseThreshold(cst, doseCube, {'L Lung','R lung'}, 10);
%
% Author: Joana Leitão + GPT-5, 2025
% -------------------------------------------------------------------------
if nargin < 5 || isempty(verbose), verbose = false; end

voxelMask = false(size(doseCube));

for i = 1:size(cst,1)
    voiName = cst{i,2};
    if ~ismember(voiName, voiSelection)
        continue;
    end

    indices = cst{i,4}{1};
    aboveThreshold = doseCube(indices) > doseThreshold;
    voxelMask(indices(aboveThreshold)) = true;
end

if verbose  
    fprintf('Identified %d voxels above %.1f Gy in selected VOIs.\n', nnz(voxelMask), doseThreshold);  
end
end
