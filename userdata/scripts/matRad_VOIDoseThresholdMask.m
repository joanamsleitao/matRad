function voxelMask = matRad_VOIDoseThresholdMask(cst, doseCube, voiSelection, doseThreshold, excludeTargets)
% matRad_VOIDoseThresholdMask - Find voxels > threshold in selected VOIs
%
% Syntax:
%   voxelMask = matRad_VOIDoseThresholdMask(cst, doseCube, voiSelection, doseThreshold, excludeTargets)
%
% Inputs:
%   cst             - matRad CST
%   doseCube        - 3D dose distribution
%   voiSelection    - cell array or numeric indices of VOIs
%   doseThreshold   - scalar dose threshold (Gy)
%   excludeTargets  - logical (default=true); if true, overlapping target voxels excluded
%
% Output:
%   voxelMask       - logical 3D mask
%
% Author: Joana Leitão + GPT-5, 2025
% -------------------------------------------------------------------------

if nargin < 4 || isempty(doseThreshold)
    doseThreshold = 10;
end
if nargin < 5 || isempty(excludeTargets)
    excludeTargets = true;
end

voxelMask = false(size(doseCube));

% --- Identify target voxels ---
targetMask = false(size(doseCube));
if excludeTargets
    for i = 1:size(cst,1)
        voiType = lower(cst{i,3});
        if contains(voiType, 'target') || contains(voiType, 'ptv') || contains(voiType, 'gtv')
            indices = cst{i,4}{1};
            targetMask(indices) = true;
        end
    end
end

% --- Resolve VOI selection ---
if isnumeric(voiSelection)
    voiIndices = voiSelection;
elseif iscell(voiSelection)
    voiIndices = find(ismember(cst(:,2), voiSelection));
else
    error('voiSelection must be numeric indices or cell array of names.');
end

for i = voiIndices(:)'
    indices = cst{i,4}{1};
    above = doseCube(indices) > doseThreshold;
    vox = indices(above);
    if excludeTargets
        vox = vox(~targetMask(vox));
    end
    voxelMask(vox) = true;
end

fprintf('VOIDoseThresholdMask: %d voxels > %.1f Gy (excludeTargets=%d)\n', ...
    nnz(voxelMask), doseThreshold, excludeTargets);
end