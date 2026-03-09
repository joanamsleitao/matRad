function affectedIdx = matRad_findAffectedNonTargetVOIs( ...
    cst, flashDose, doseThreshold, targetIdx)
% matRad_findAffectedNonTargetVOIs
% Identify all NON-TARGET VOIs that intersect FLASH-affected voxels
%
% FLASH-affected voxels are defined as:
%   flashDose >= doseThreshold
%   AND voxel NOT inside a target (PTV/GTV/CTV)
%
% This reflects the concept that FLASH sparing is a beam property,
% not an OAR-specific property.
%
% Inputs:
%   cst           - matRad CST cell array
%   flashDose     - 3D FLASH dose cube (no DMF applied)
%   doseThreshold - FLASH threshold [Gy]
%   targetIdx     - indices of target VOIs (from matRad_findTargetVOIs)
%
% Output:
%   affectedIdx   - CST indices of VOIs affected by FLASH (non-target)
%
% Author: Joana Leitão, 2025
% -------------------------------------------------------------------------

    % --- Build target mask
    targetMask = false(size(flashDose));

    for ii = 1:numel(targetIdx)
        idx = targetIdx(ii);
        if isempty(cst{idx,4}) || isempty(cst{idx,4}{1})
            continue;
        end
        vox = vertcat(cst{idx,4}{:});
        targetMask(vox) = true;
    end

    % --- FLASH-affected voxel mask (beam-based)
    flashMask = (flashDose >= doseThreshold) & ~targetMask;

    % --- Loop over all VOIs except targets
    allIdx = find(~cellfun(@isempty, cst(:,2)));
    nonTargetIdx = setdiff(allIdx, targetIdx);

    affected = false(size(nonTargetIdx));

    for i = 1:numel(nonTargetIdx)
        idx = nonTargetIdx(i);

        if isempty(cst{idx,4}) || isempty(cst{idx,4}{1})
            continue;
        end

        vox = vertcat(cst{idx,4}{:});
        affected(i) = any(flashMask(vox));
    end

    affectedIdx = nonTargetIdx(affected);
end