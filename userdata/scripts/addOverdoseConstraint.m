function [cst, ixNewVOI] = addOverdoseConstraint(cst, doseCube, doseThreshold, ixRefVOI)
% ADDOVERDOSECONSTRAINT - Creates new VOI for overdosed areas and adds max dose constraint
%
% Syntax:  [cst, ixNewVOI] = addOverdoseConstraint(cst, doseCube, doseThreshold, ixRefVOI)
%
% Inputs:
%   cst             - Cell structure of CST (matRad format) (cell array)
%   doseCube        - 3D dose matrix matching structure mask size (double array)
%   doseThreshold   - Dose threshold for defining overdose [Gy] (double)
%   ixRefVOI        - Index of reference VOI in CST (integer, optional)
%
% Outputs:
%   cst             - Updated CST with new VOI and constraint (cell array)
%   ixNewVOI        - Index of newly added VOI in CST (integer)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: analyzePlanDose

% --- Handle default input for base VOI ---
if nargin < 4 || isempty(ixRefVOI)
    ixRefVOI = find(strcmpi(cst(:,3), 'EXTERNAL'), 1);
    if isempty(ixRefVOI)
        error('No structure labeled EXTERNAL found in CST.');
    end
end

% Get indices for base VOI
indBase = cst{ixRefVOI, 4}{1};
doseInBase = doseCube(indBase);

% Find overdosed voxels
indOver = indBase(doseInBase > doseThreshold);

% Optionally exclude voxels overlapping other structures (e.g., PTV, OARs)
% Build a mask of relevant voxels from all other VOIs
indAll = [];
for i = 1:size(cst,1)
    if i == ixRefVOI
        continue;  % skip self
    end
    indAll = [indAll; cst{i, 4}{1}];
end
indAll = unique(indAll);

% Exclude those voxels from overdosed volume
indOverCleaned = setdiff(indOver, indAll);

% If nothing is left, issue warning
if isempty(indOverCleaned)
    warning('No overdosed voxels remain after excluding other VOIs. No new VOI added.');
    ixNewVOI = [];
    return;
end

% --- Create new CST entry ---
cst = [cst; cst(ixRefVOI, :)]; % duplicate base row
ixNewVOI = size(cst,1);

% Name update
baseName = cst{ixRefVOI, 2};
newName = sprintf('%s_Over%.1fGy', baseName, doseThreshold);
cst{ixNewVOI, 2} = newName;

% Mark as OAR
cst{ixNewVOI, 3} = 'OAR';

% Assign new voxel indices
cst{ixNewVOI, 4} = {indOverCleaned};

% Slightly change color for visibility
cst{ixNewVOI, 5}.visibleColor = min(cst{ixRefVOI, 5}.visibleColor * 1.1, [1 1 1]);

% --- Add dose objective: MaxDVH at 2% volume ---
obj.className = 'DoseObjectives.matRad_MaxDVH';
obj.parameters = {doseThreshold, 2};  % dose, volume percentage
obj.penalty = 1e3;  % high penalty
cst{ixNewVOI, 6} = {obj};

% --- Logging ---
fprintf('[addOverdoseConstraint] Added VOI "%s" at index %d with %d voxels > %.1f Gy\n', ...
    newName, ixNewVOI, numel(indOverCleaned), doseThreshold);

% --- Visualization of overdosed region ---
% Create binary mask
maskOver = false(size(doseCube));
maskOver(indOverCleaned) = true;

% Find axial slice with most overdosed voxels
[~, sliceIndex] = max(squeeze(sum(sum(maskOver,1))));

% Plot
figure;
imagesc(doseCube(:,:,sliceIndex));
colormap hot;
colorbar;
axis image off;
hold on;

% Overlay overdosed region
maskSlice = maskOver(:,:,sliceIndex);
h = contour(maskSlice, [0.5 0.5], 'r', 'LineWidth', 2);
title(sprintf('Overdosed Region (>%g Gy) on Slice %d', doseThreshold, sliceIndex));
legend(gca, 'Overdosed region');

end
