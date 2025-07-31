function [cst, ixNewVOI] = addOverdoseConstraint(cst, doseCube, doseThreshold, ixRefVOI)
% ADDOVERDOSECONSTRAINT Create a new VOI for overdosed areas and add max dose constraint.
%
%   This function identifies voxels within a specified VOI that exceed a given
%   dose threshold, adds a new entry in the CST with those voxels, and appends
%   a high-penalty maxDVH constraint to it.
%
% INPUTS:
%   cst              - Cell structure of CST (matRad format).
%   doseCube         - 3D dose matrix matching the structure mask size.
%   doseThreshold    - Dose threshold [Gy] for defining overdose (e.g., 30).
%   ixRefVOI        - Index of the VOI to apply the constraint to (optional).
%                      Defaults to the first VOI labeled 'EXTERNAL'.
%
% OUTPUTS:
%   cst              - Updated CST with new VOI and constraint added.
%   ixNewVOI         - Index of the newly added VOI in the CST.
%
% Author: ChatGPT & User, 2025

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
