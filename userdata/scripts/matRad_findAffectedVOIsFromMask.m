function affectedIdx = matRad_findAffectedVOIsFromMask(cst, flashMask, excludeIdx)
% matRad_findAffectedVOIsFromMask
% VOIs affected = any overlap with flashMask, excluding excludeIdx (targets).
%
% Inputs:
%   cst        - matRad CST
%   flashMask  - logical 3D mask of DMF-modified voxels
%   excludeIdx - VOI indices to exclude (e.g., targets)
%
% Output:
%   affectedIdx - indices of VOIs that intersect flashMask (excluding targets)

    if nargin < 3 || isempty(excludeIdx)
        excludeIdx = [];
    end
    excludeIdx = unique(excludeIdx(:));

    allIdx   = find(~cellfun(@isempty, cst(:,2)));
    testIdx  = setdiff(allIdx, excludeIdx);

    isAff = false(size(testIdx));

    for i = 1:numel(testIdx)
        idx = testIdx(i);

        if isempty(cst{idx,4}) || isempty(cst{idx,4}{1})
            continue;
        end

        vox = vertcat(cst{idx,4}{:});
        isAff(i) = any(flashMask(vox));
    end

    affectedIdx = testIdx(isAff);
end