function [cst, isoInfo, ixIso] = matRad_VOIAxialIsoVol(ct, cst, ixRefVOI, marginXY_mm, nameIso, intersectWithVOI, visualize)
% matRad_VOIAxialIsoVol - Create an axial isocentric VOI from per-slice centers of a reference VOI
%
% Syntax:
%   [cst, isoInfo, ixIso] = matRad_VOIAxialIsoVol(ct, cst, ixRefVOI, marginXY_mm)
%   [cst, isoInfo, ixIso] = matRad_VOIAxialIsoVol(ct, cst, ixRefVOI, marginXY_mm, nameIso)
%   [cst, isoInfo, ixIso] = matRad_VOIAxialIsoVol(ct, cst, ixRefVOI, marginXY_mm, nameIso, intersectWithVOI)
%   [cst, isoInfo, ixIso] = matRad_VOIAxialIsoVol(ct, cst, ixRefVOI, marginXY_mm, nameIso, intersectWithVOI, visualize)
%
% Description:
%   For each axial slice that contains voxels of the reference VOI, this
%   function:
%     1) Computes the 2D centroid (in voxel indices) of the VOI voxels in
%        that slice.
%     2) Creates an in-plane circular/elliptical region centered at this
%        centroid with radius marginXY_mm (in mm), using ct.resolution.x/y.
%   The per-slice masks are stacked along the axial direction, creating an
%   "isocentric tube" VOI that follows the axial center of the structure.
%
%   Optionally, the resulting tube can be intersected with the original VOI
%   so that it stays fully inside the reference structure.
%
% Inputs:
%   ct               - matRad CT structure
%   cst              - matRad CST cell array
%   ixRefVOI         - Index of reference VOI in CST
%   marginXY_mm      - In-plane margin around slice centroid [mm]
%   nameIso          - (optional) Name of the new isocentric VOI. If empty,
%                      defaults to '<VOI>_Iso<margin>mm'
%   intersectWithVOI - (optional) logical, default: true
%                      If true, tube is intersected with the original VOI.
%   visualize        - (optional) logical, default: false
%                      If true, shows one axial slice with VOIs overlaid.
%
% Outputs:
%   cst    - Updated CST including the new isocentric VOI
%   isoInfo- Struct with metadata about the isocentric VOI
%   ixIso  - Index of the new VOI in CST
%
% Notes:
%   - The centroid is computed slice-wise in voxel index space.
%   - Distances are converted to mm using ct.resolution.x and .y.
%   - Only slices that contain the reference VOI contribute to the tube.
%
% Reference List Entry:
%   | `N/A` | `matRad_VOIAxialIsoVol` | Create an axial isocentric VOI from per-slice centers of a reference VOI | `[cst, isoInfo, ixIso] = matRad_VOIAxialIsoVol(ct, cst, ixRefVOI, marginXY_mm, nameIso, intersectWithVOI, visualize)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão + GPT-5.1
% Date: 2025-12-09_1300
% -------------------------------------------------------------------------

    %% Input checks and defaults
    if nargin < 3 || isempty(ixRefVOI)
        error('matRad_VOIAxialIsoVol:MissingRefVOI', ...
              'ixRefVOI must be provided (index of reference VOI in CST).');
    end

    if nargin < 4 || isempty(marginXY_mm)
        error('matRad_VOIAxialIsoVol:MissingMargin', ...
              'marginXY_mm (in-plane margin in mm) must be provided.');
    end

    if nargin < 5 || isempty(nameIso)
        refName  = cst{ixRefVOI,2};
        nameIso  = sprintf('%s_Iso%imm', refName, round(marginXY_mm));
    end

    if nargin < 6 || isempty(intersectWithVOI)
        intersectWithVOI = true;
    end

    if nargin < 7 || isempty(visualize)
        visualize = false;
    end

    %% Basic info
    refName     = cst{ixRefVOI,2};
    baseIndices = cst{ixRefVOI,4}{1};
    if isempty(baseIndices)
        error('matRad_VOIAxialIsoVol:EmptyRefVOI', ...
              'Reference VOI "%s" has no voxels.', refName);
    end

    nx = ct.cubeDim(1);
    ny = ct.cubeDim(2);
    nz = ct.cubeDim(3);

    resX = ct.resolution.x;
    resY = ct.resolution.y;

    %% Build reference mask
    voiMask = false(ct.cubeDim);
    voiMask(baseIndices) = true;

    %% Get voxel indices (subscripts) of reference VOI
    [ix, iy, iz] = ind2sub(ct.cubeDim, baseIndices);
    uniqueSlices = unique(iz);

    %% Prepare isocentric mask and per-slice info
    isoMask = false(ct.cubeDim);

    sliceInfo = struct('slice', {}, 'center_ij', {}, 'center_mm', {});

    fprintf('--- Axial Isocentric VOI Generation ---\n');
    fprintf('Reference VOI: %s (ix %d, %d voxels)\n', refName, ixRefVOI, numel(baseIndices));
    fprintf('In-plane margin: %.1f mm; intersectWithVOI = %d\n', marginXY_mm, intersectWithVOI);

    r2_mm = marginXY_mm^2;

    %% Precompute index grids for full slice (could restrict to a window if needed)
    [X, Y] = ndgrid(1:nx, 1:ny);  % X ~ row index, Y ~ column index

    for k = 1:numel(uniqueSlices)
        z = uniqueSlices(k);

        % Voxels of VOI in this slice
        inSlice = (iz == z);
        slice_ix = ix(inSlice);
        slice_iy = iy(inSlice);

        if isempty(slice_ix)
            continue;
        end

        % Slice centroid in index space
        cx = mean(slice_ix);
        cy = mean(slice_iy);

        % Distance (mm) from centroid for all voxels in this slice
        dx_mm = (X - cx) * resX;
        dy_mm = (Y - cy) * resY;
        dist2_mm = dx_mm.^2 + dy_mm.^2;

        % In-plane iso mask for this slice
        mask2D = dist2_mm <= r2_mm;

        % Assign to 3D isocentric mask
        isoMask(:,:,z) = isoMask(:,:,z) | mask2D;

        % Store info
        center_mm = [(cx-0.5)*resX, (cy-0.5)*resY, (z-0.5)*ct.resolution.z];
        sliceInfo(end+1).slice      = z; %#ok<AGROW>
        sliceInfo(end).center_ij    = [cx, cy];
        sliceInfo(end).center_mm    = center_mm;

        fprintf('Slice %3d: center = (%.2f, %.2f) vox → (%.2f, %.2f) mm, voxels in iso mask: %d\n', ...
                z, cx, cy, center_mm(1), center_mm(2), nnz(mask2D));
    end

    %% Optionally restrict to original VOI
    if intersectWithVOI
        isoMask = isoMask & voiMask;
    end

    isoIndices = find(isoMask);
    nIso = numel(isoIndices);

    if nIso == 0
        warning('matRad_VOIAxialIsoVol:EmptyIsoVOI', ...
                'Isocentric VOI "%s" resulted in 0 voxels. Nothing added to CST.', nameIso);
        isoInfo = struct('name', nameIso, 'ixRefVOI', ixRefVOI, ...
                         'marginXY_mm', marginXY_mm, 'intersectWithVOI', intersectWithVOI, ...
                         'nVoxels', 0, 'sliceInfo', sliceInfo);
        ixIso = [];
        return;
    end

    %% Add new VOI to CST
    ixIso = size(cst,1) + 1;

    cst{ixIso, 1} = ixIso;
    cst{ixIso, 2} = nameIso;
    cst{ixIso, 3} = 'TARGET';     % or 'AUX' / 'ISOCENTER' depending on your convention
    cst{ixIso, 4} = {isoIndices};
    cst{ixIso, 5} = cst{ixRefVOI, 5};
    cst{ixIso, 5}.visibleColor = rand(1,3);
    cst{ixIso, 5}.Priority     = ixIso;

    %% Collect metadata
    isoInfo = struct();
    isoInfo.name            = nameIso;
    isoInfo.ixRefVOI        = ixRefVOI;
    isoInfo.refName         = refName;
    isoInfo.marginXY_mm     = marginXY_mm;
    isoInfo.intersectWithVOI= intersectWithVOI;
    isoInfo.nVoxels         = nIso;
    isoInfo.sliceInfo       = sliceInfo;

    fprintf('Created isocentric VOI "%s" with %d voxels.\n', nameIso, nIso);
    fprintf('----------------------------------------\n');

    %% Optional visualization
    if visualize
        midZ = round(median(uniqueSlices));
        figure;
        matRad_showSliceFast(ct, cst, [], midZ);
        title(sprintf('Axial isocentric VOI "%s" on slice %d', nameIso, midZ), ...
              'Interpreter', 'none');
    end
end