%% Mid-Treatment CT/CST Resampling Pipeline for Adaptive Radiotherapy
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2017-2026 the matRad development team.
%
% This file is part of the matRad project. It is subject to the license
% terms in the LICENSE file found in the top-level directory of this
% distribution and at https://github.com/e0404/matRad/LICENSE.md. No part
% of the matRad project, including this file, may be copied, modified,
% propagated, or distributed except according to the terms contained in the
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% In this script we will show
% (i)   how to load a reference (planning) CT and a mid-treatment CT for
%       the same patient into matRad
% (ii)  how to resize the mid-treatment CT to match the reference CT grid
%       (same voxel dimensions and resolution) while preserving the
%       world-coordinate isocenter of the mid-treatment scan
% (iii) how to verify that the two CT grids are correctly aligned in world
%       space after resampling
% (iv)  how to resample the mid-treatment CST (structure set / RTStruct)
%       onto the new resized CT grid using world-coordinate interpolation
% (v)   how to regenerate a clean BODY contour on the resized CT, including
%       gap filling, couch/table removal, and per-slice closing
% (vi)  how to run the full pipeline in a single call and visualize results

%% Set matRad runtime configuration
% This sets up all required paths. Run from the matRad root directory if
% this throws an error.
matRad_rc;

%% -----------------------------------------------------------------------
%  Patient Data Import
%  -----------------------------------------------------------------------
% We load two time points for the same Head & Neck patient:
%   - ctOg  : the original planning CT (reference grid)
%   - ctMid : the mid-treatment CT (to be resampled onto ctOg's grid)
%
% Each .mat file contains a matRad 'ct' struct and a 'cst' cell array.
% The ct struct holds:
%   ct.cubeHU    - cell array with the HU volume {1}
%   ct.cubeDim   - [nX nY nZ] voxel dimensions
%   ct.resolution- struct with fields .x .y .z (mm per voxel)
%   ct.x / .y / .z - world-coordinate axes (mm)
%
% The cst cell array encodes the structure set (VOIs / RTStruct):
%   cst{i,1} - VOI index
%   cst{i,2} - VOI name (string)
%   cst{i,3} - VOI type ('TARGET' or 'OAR')
%   cst{i,4} - cell with linear voxel indices into the CT grid
%   cst{i,5} - struct with dose objectives / constraints
%   cst{i,6} - additional objectives

fprintf('Loading patient data...\n');

% Planning (reference) CT — Patient 2, scan date 20/08/2009
load(fullfile(pwd, 'HeadAndNeck', 'matRadPatient_Patient 2_20082009.mat'));
ctOg  = ct;  clear ct;
cstOg = cst; clear cst;

% Mid-treatment CT — same patient, scan date 06/10/2009
load(fullfile(pwd, 'HeadAndNeck', 'matRadPatient_Patient 2_06102009.mat'), 'ct', 'cst');
ctMid  = ct;  clear ct;
cstMid = cst; clear cst;

fprintf('ctOg  grid: [%d %d %d] voxels, res = [%.2f %.2f %.2f] mm\n', ...
    ctOg.cubeDim,  ctOg.resolution.x,  ctOg.resolution.y,  ctOg.resolution.z);
fprintf('ctMid grid: [%d %d %d] voxels, res = [%.2f %.2f %.2f] mm\n', ...
    ctMid.cubeDim, ctMid.resolution.x, ctMid.resolution.y, ctMid.resolution.z);

%% -----------------------------------------------------------------------
%  Step 1 — Resize the mid-treatment CT to the reference grid
%  -----------------------------------------------------------------------
% matRad_resizeCtIso resamples ctMid so that its voxel grid matches ctOg
% (same cubeDim and resolution). Crucially, it anchors the resampling to
% the world-coordinate isocenter of ctMid, so anatomical structures remain
% in the correct world position after resampling.
%
% Internally the function:
%   1. Reads the target dimensions and resolution from ctOg
%   2. Computes the world-coordinate isocenter of ctMid
%   3. Builds a new world-coordinate axis grid centred on that isocenter
%   4. Resamples ctMid.cubeHU{1} onto the new grid using trilinear
%      interpolation (interp3), filling out-of-range voxels with air HU
%
% Output:
%   ctMidResized  - ct struct on ctOg's grid, world origin from ctMid
%   reportCt      - diagnostics: dimMid, dimRef, isoCenter, world extents

fprintf('\n--- Step 1: Resize mid-treatment CT ---\n');
[ctMidResized, reportCt] = matRad_resizeCtIso(ctOg, ctMid);

fprintf('  dimMid = [%d %d %d]  →  dimRef = [%d %d %d]\n', ...
    reportCt.dimMid, reportCt.dimRef);

%% -----------------------------------------------------------------------
%  Step 2 — Verify isocenter alignment between original and resized CT
%  -----------------------------------------------------------------------
% Before resampling the structure set it is essential to confirm that the
% two CT grids share the same world-coordinate isocenter (within tolerance).
% A large shift would indicate a grid definition error and would cause all
% CST voxel indices to map to the wrong anatomy.
%
% matRad_checkIsoAlign computes:
%   - isoCenter of ctMid and ctMidResized in world coordinates (mm)
%   - isoShift_mm : difference vector between the two isocenters
%   - isAligned   : true if ||isoShift_mm|| < tolerance (default 1 mm)
%   - hasOverlap  : true if the two world extents overlap in all 3 axes
%
% If isAligned = false or hasOverlap = false, CST resampling should NOT
% proceed — the CT grids are inconsistent.

fprintf('\n--- Step 2: Check isocenter alignment ---\n');
reportAlign = matRad_checkIsoAlign(ctMid, ctMidResized);

fprintf('  isoCenter ctMid        = [%.2f %.2f %.2f] mm\n', reportAlign.isoCenterOld_mm);
fprintf('  isoCenter ctMidResized = [%.2f %.2f %.2f] mm\n', reportAlign.isoCenterNew_mm);
fprintf('  iso shift              = [%.3f %.3f %.3f] mm\n', reportAlign.isoShift_mm);
fprintf('  isAligned  = %d  |  hasOverlap = %d\n', reportAlign.isAligned, reportAlign.hasOverlap);

if ~reportAlign.isAligned || ~reportAlign.hasOverlap
    error('Grid alignment check failed — aborting CST resampling.');
end

%% -----------------------------------------------------------------------
%  Step 3 — Resample the mid-treatment CST onto the resized CT grid
%  -----------------------------------------------------------------------
% The CST stores structure voxel memberships as linear indices into the
% original ctMid grid. After resizing the CT, those indices are no longer
% valid — they must be remapped to the new ctMidResized grid.
%
% matRad_resizeCstIso performs this remapping using world-coordinate
% nearest-neighbour interpolation:
%   1. Converts each VOI's linear indices → 3D subscripts in ctMid
%   2. Converts subscripts → world coordinates (mm) using ctMid axes
%   3. Finds the nearest voxel in ctMidResized for each world coordinate
%   4. Converts back to linear indices in ctMidResized
%
% This approach is robust to resolution changes and ensures anatomical
% structures remain correctly positioned in world space.
%
% Output:
%   cstMidResized - CST with voxel indices valid for ctMidResized
%   reportCst     - diagnostics: nStructures, nEmpty, per-VOI voxel counts

fprintf('\n--- Step 3: Resample CST onto resized CT grid ---\n');
[cstMidResized, reportCst] = matRad_resizeCstIso(cstMid, ctMid, ctMidResized);

fprintf('  structures resampled = %d\n', reportCst.nStructures);
fprintf('  empty after resample = %d\n', reportCst.nEmpty);

% Quick visual check — axial plane, slice 75
figure;
matRad_showSliceFast(ctMidResized, cstMidResized, [], 75);
title('Step 3 result: ctMidResized + cstMidResized (axial slice 75)');

%% -----------------------------------------------------------------------
%  Step 4 — Regenerate the BODY contour on the resized CT
%  -----------------------------------------------------------------------
% After resampling, the BODY contour inherited from cstMid may have small
% gaps or artefacts introduced by interpolation. It is therefore best
% practice to regenerate it directly from the HU values of ctMidResized.
%
% matRad_createBody implements a multi-step pipeline:
%   1. Threshold the HU cube (default -270 HU for H&N)
%   2. Optionally remove a specific HU interval (e.g. table material)
%   3. 3D morphological closing to bridge small gaps
%   4. 3D imfill to fill enclosed cavities
%   5. Keep only the largest 3D connected component → removes couch/table
%   6. Per-slice 2D closing (disk SE, radius 15 px) → closes lungs/air
%   7. Per-slice 2D imfill → fills any remaining intra-slice holes
%
% The 'replaceExisting' flag ensures any old BODY row in the CST is
% overwritten rather than a duplicate being appended.

fprintf('\n--- Step 4: Regenerate BODY contour ---\n');
thresholdHU = -270;   % H&N patients: -270 HU works well

[cstMidResized, bodyMask, reportBody] = matRad_createBody(ctMidResized, cstMidResized, ...
    thresholdHU,              ...
    'closeRadius',      1,    ...  % 3D closing radius (voxels)
    'keepLargestCC',    true, ...  % remove disconnected objects (couch)
    'sliceCloseRadius', 15,   ...  % 2D per-slice closing radius (pixels)
    'sliceFill',        true, ...  % 2D per-slice hole fill
    'replaceExisting',  true);     % overwrite existing BODY row

fprintf('  initial voxels = %d  →  final voxels = %d\n', ...
    reportBody.nVoxelsInitial, reportBody.nVoxelsFinal);
fprintf('  components before CC filter = %d\n', reportBody.nComponentsBefore);

% Visualize all three anatomical planes with the new BODY contour
hFig = matRad_showAllPlanes(ctMidResized, cstMidResized, [], 20, [], 3);
sgtitle('Step 4 result: regenerated BODY contour');

%% -----------------------------------------------------------------------
%  Full pipeline in a single call — matRad_resizeCtCst
%  -----------------------------------------------------------------------
% Steps 1–4 above are wrapped into the convenience function
% matRad_resizeCtCst, which accepts the same Name-Value options and returns
% a unified report struct containing sub-reports from each step:
%   report.ct    → from matRad_resizeCtIso   (Step 1)
%   report.align → from matRad_checkIsoAlign (Step 2)
%   report.cst   → from matRad_resizeCstIso  (Step 3)
%   report.body  → from matRad_createBody    (Step 4)
%
% This is the recommended entry point for routine use.

fprintf('\n--- Full pipeline: matRad_resizeCtCst ---\n');
thresholdHU = -270;

[ctMidResized, cstMidResized, report] = matRad_resizeCtCst(ctOg, ctMid, cstMid, ...
    'visualize',        true,        ... % show matRad_showAllPlanes at the end
    'nSlices',          15,          ... % slices per plane in visualization
    'regenBody',        true,        ... % run Step 4 body regeneration
    'thresholdHU',      thresholdHU, ... % HU threshold for body
    'closeRadius',      1,           ... % 3D closing radius
    'sliceCloseRadius', 15,          ... % 2D per-slice closing radius
    'sliceFill',        true,        ... % 2D per-slice hole fill
    'keepLargestCC',    true);           % remove couch/table

% Summary of pipeline results
fprintf('\nPipeline summary:\n');
fprintf('  CT  : [%d %d %d] → [%d %d %d]\n', ...
    report.ct.dimMid, report.ct.dimRef);
fprintf('  Align: shift = [%.3f %.3f %.3f] mm | aligned = %d | overlap = %d\n', ...
    report.align.isoShift_mm, report.align.isAligned, report.align.hasOverlap);
fprintf('  CST : %d structures | %d empty after resample\n', ...
    report.cst.nStructures, report.cst.nEmpty);
fprintf('  Body: %d → %d voxels | regenerated = %d\n', ...
    report.body.nVoxelsInitial, report.body.nVoxelsFinal, report.bodyRegenerated);