function [healthyMask, cstNew, healthyAboveThrMask] = matRad_VOIHealthy( ...
    cst, doseCube, doseThreshold, includeTargets, minIslandVox3D, minAreaVox2D)
% matRad_VOIHealthy - Create VOIs for irradiated healthy tissue with local 3D neighborhood + in-slice filtering
%
% Syntax:
%   [healthyMask, cstNew, healthyAboveThrMask] = ...
%       matRad_VOIHealthy(cst, doseCube)
%   [healthyMask, cstNew, healthyAboveThrMask] = ...
%       matRad_VOIHealthy(cst, doseCube, doseThreshold)
%   [healthyMask, cstNew, healthyAboveThrMask] = ...
%       matRad_VOIHealthy(cst, doseCube, doseThreshold, includeTargets)
%   [healthyMask, cstNew, healthyAboveThrMask] = ...
%       matRad_VOIHealthy(cst, doseCube, doseThreshold, includeTargets, minIslandVox3D)
%   [healthyMask, cstNew, healthyAboveThrMask] = ...
%       matRad_VOIHealthy(cst, doseCube, doseThreshold, includeTargets, minIslandVox3D, minAreaVox2D)
%
% Description:
%   Finds all voxels receiving dose > 0 and optionally excludes those
%   belonging to TARGET/PTV/GTV VOIs.
%
%   Then applies two filters on the “healthy” voxels:
%
%   1) Local 3D neighborhood filter (3×3×3):
%        - For each voxel, count how many voxels in its 3×3×3 neighborhood
%          are healthy (including itself).
%        - Keep only voxels with count >= minIslandVox3D.
%
%   2) Optional in-slice 2D area filter (per axial slice, 8-connectivity):
%        - In each z-slice, remove 2D components with area < minAreaVox2D.
%
%   Finally creates two OAR VOIs:
%     1) HealthyTissue[...]           - voxels with dose > 0 (after filters)
%     2) HealthyTissueAboveThr_*Gy[...] - subset with dose > doseThreshold
%
% Inputs:
%   cst            - matRad CST cell array
%   doseCube       - 3D dose matrix
%   doseThreshold  - (optional) dose threshold (Gy, default: 10)
%   includeTargets - (optional) logical (default=false);
%                    if false, exclude voxels in target VOIs (TARGET/PTV/GTV)
%   minIslandVox3D - (optional) minimum number of healthy voxels in the
%                    3×3×3 neighborhood (including the voxel itself) to
%                    keep that voxel. Default: 3. Set <=1 to skip.
%   minAreaVox2D   - (optional) minimum 2D island size (area in voxels)
%                    per slice to keep (bwareaopen). Default: 3. Set <=1 to skip.
%
% Outputs:
%   healthyMask         - logical mask of “healthy” voxels receiving dose
%                         (after target exclusion + filters)
%   cstNew              - updated CST with added VOIs:
%                         'HealthyTissue[...][_IncTargets]' and
%                         'HealthyTissueAboveThr_*Gy[...][_IncTargets]'
%   healthyAboveThrMask - logical mask of "healthy" voxels with dose >
%                         doseThreshold (after same filters)
%
% Reference List Entry:
%   | `N/A` | `matRad_VOIHealthy` | Create VOIs for irradiated healthy tissue with local 3D neighborhood + in-slice filtering | `[healthyMask, cstNew, healthyAboveThrMask] = matRad_VOIHealthy(cst, doseCube, doseThreshold, includeTargets, minIslandVox3D, minAreaVox2D)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão + GPT-5.1
% Date: 2025-12-04_0000
% -------------------------------------------------------------------------

    %% Defaults   
    if nargin < 3 || isempty(doseThreshold)
        doseThreshold = 10;
    end
    if nargin < 4 || isempty(includeTargets)
        includeTargets = false;
    end
    if nargin < 5 || isempty(minIslandVox3D)
        minIslandVox3D = 1;  % local 3D neighborhood size (voxels)
    end
    if nargin < 6 || isempty(minAreaVox2D)
        minAreaVox2D = 1;    % per-slice 2D minimum area (voxels)
    end

    if nargin < 7 || isempty(verbose), verbose = false; end

    %% Basic dose-based masks
    doseMask = doseCube > 0;

    % --- Identify target voxels
    targetMask = false(size(doseCube));
    for i = 1:size(cst,1)
        voiType = lower(cst{i,3});
        if contains(voiType, 'target') || contains(voiType, 'ptv') || contains(voiType, 'gtv')
            if ~isempty(cst{i,4}) && ~isempty(cst{i,4}{1})
                indices = cst{i,4}{1};
                targetMask(indices) = true;
            end
        end
    end

    if includeTargets
        healthyMask = doseMask;
    else
        healthyMask = doseMask & ~targetMask;
    end

    %% Local 3D neighborhood filtering (3×3×3)
    if minIslandVox3D > 1
        kernel = ones(3,3,3,'double');
        % Count healthy voxels in each 3×3×3 neighborhood
        nbhdCount = convn(double(healthyMask), kernel, 'same');
        healthyMask = healthyMask & (nbhdCount >= minIslandVox3D);
    end

    %% Thresholded version based on filtered healthyMask
    healthyAboveThrMask = healthyMask & (doseCube > doseThreshold);

    %% Optional in-slice 2D area filtering (axial slices, 8-connectivity)
    [~, ~, nz] = size(healthyMask);

    if minAreaVox2D > 1
        for z = 1:nz
            % Healthy mask
            sliceMask = healthyMask(:,:,z);
            if any(sliceMask(:))
                sliceMask = bwareaopen(sliceMask, minAreaVox2D, 8);
                healthyMask(:,:,z) = sliceMask;
            end

            % Above-threshold mask
            sliceMaskThr = healthyAboveThrMask(:,:,z);
            if any(sliceMaskThr(:))
                sliceMaskThr = bwareaopen(sliceMaskThr, minAreaVox2D, 8);
                healthyAboveThrMask(:,:,z) = sliceMaskThr;
            end
        end
    end

    %% Create CST entries with clear naming for criteria
    healthyIdx = find(healthyMask);
    healthyAboveThrIdx = find(healthyAboveThrMask);

    baseEntry = cst(end,:);
    newEntry1 = baseEntry;
    newEntry2 = baseEntry;

    % Target inclusion suffix
    suffixTarget = '';
    if includeTargets
        suffixTarget = '_IncTargets';
    end

    % Criteria suffix
    suffixCrit = '';
    if minIslandVox3D > 1 || minAreaVox2D > 1
        suffixCrit = sprintf('_Nbhd3D%d_2D%d', minIslandVox3D, minAreaVox2D);
    end

    % Final VOI names
    newEntry1{2} = ['HealthyTissue' suffixCrit suffixTarget];
    newEntry1{3} = 'OAR';
    newEntry1{4} = {healthyIdx};

    newEntry2{2} = sprintf('HealthyTissueAboveThr_%.1fGy%s%s', ...
                           doseThreshold, suffixCrit, suffixTarget);
    newEntry2{3} = 'OAR';
    newEntry2{4} = {healthyAboveThrIdx};

    cstNew = [cst; newEntry1; newEntry2];

    fprintf(['Added new CST VOIs (minIslandVox3D = %d, minAreaVox2D = %d):\n' ...
             '  "%s" (%d voxels)\n  "%s" (%d voxels)\n'], ...
            minIslandVox3D, minAreaVox2D, ...
            newEntry1{2}, numel(healthyIdx), ...
            newEntry2{2}, numel(healthyAboveThrIdx));
end