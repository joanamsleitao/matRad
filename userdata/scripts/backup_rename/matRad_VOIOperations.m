function [cst, newIx] = matRad_VOIOperations(cst, ix1, ix2, operation, newName)
% matRad_VOIOperations Combine voxel indices from two VOIs in CST with set operations
%
% [cst, newIx] = matRad_VOIOperations(cst, ix1, ix2, operation, newName)
%
% Inputs:
%   cst       - CST cell array
%   ix1, ix2  - indices of VOIs to combine
%   operation - string, one of {'setdiff', 'union', 'intersect'}
%   newName   - name for the new VOI to create in CST
%
% Outputs:
%   cst       - updated CST with new VOI
%   newIx     - index of the new VOI in CST
%
% Example:
%   [cst, newIx] = combineVOIVoxels(cst, 3, 5, 'setdiff', 'PTV_minus_GTV');

% Validate inputs
validOps = {'setdiff', 'union', 'intersect'};
if ~ismember(operation, validOps)
    error('Operation must be one of: %s', strjoin(validOps, ', '));
end

% Extract voxel indices from CST
vox1 = cst{ix1, 4}{1};
vox2 = cst{ix2, 4}{1};

% Perform operation
switch operation
    case 'setdiff'
        newVox = setdiff(vox1, vox2);
    case 'union'
        newVox = union(vox1, vox2);
    case 'intersect'
        newVox = intersect(vox1, vox2);
end

% Prepare new CST entry
newIx = size(cst, 1) + 1;
cst{newIx, 1} = newIx;            % Index
cst{newIx, 2} = newName;          % Name
cst{newIx, 3} = 'COMBINED';       % Type (custom)
cst{newIx, 4} = {newVox};         % Voxel indices

% Copy color and priority from first VOI, or set default
if isfield(cst{ix1, 5}, 'visibleColor')
    cst{newIx, 5} = cst{ix1, 5};
else
    cst{newIx, 5}.visibleColor = rand(1,3); % random color
end
cst{newIx, 5}.Priority = newIx;

end
