function [cst, bodyMask, report] = matRad_createBody(ct, cst, thresholdHU, varargin)
% matRad_genBodyClean - Create BODY contour from CT HU, fill gaps, and
%                       remove table/disconnected components
%
% Syntax:
%   cst = matRad_genBodyClean(ct, cst)
%   cst = matRad_genBodyClean(ct, cst, thresholdHU)
%   [cst, bodyMask, report] = matRad_genBodyClean(ct, cst, thresholdHU, Name, Value)
%
% Description:
%   Generates a BODY contour from the CT HU cube for patient cases that do
%   not have one, or when a cleaner BODY contour is needed.
%
%   Processing steps:
%     1) Threshold CT HU cube
%     2) Optionally remove a user-defined HU interval
%     3) Close small gaps in 3D
%     4) Fill enclosed holes in 3D
%     5) Keep only the largest 3D connected component to remove detached
%        objects such as the treatment couch/table
%     6) Per-slice 2D closing (axial) to bridge gaps like lungs/air pockets
%     7) Per-slice 2D imfill to fill any remaining internal holes per slice
%
% Inputs:
%   ct          - matRad CT struct
%   cst         - matRad CST cell array
%   thresholdHU - HU threshold for body generation (default: -500)
%
% Name-Value Options:
%   'excludeHUrange'   - optional HU range [min max] to remove before filling
%                        default: []
%   'closeRadius'      - 3D closing radius in voxels (default: 1)
%   'keepLargestCC'    - keep only largest 3D connected component (default: true)
%   'sliceCloseRadius' - 2D per-slice closing radius in pixels after couch
%                        removal, to bridge gaps like lungs (default: 15)
%                        set to 0 to skip
%   'sliceFill'        - apply per-slice 2D imfill after slice closing
%                        (default: true)
%   'replaceExisting'  - replace existing BODY/External if found (default: false)
%   'bodyNames'        - names used to detect an existing body contour
%                        default: {'BODY','Body','External','external','body'}
%
% Outputs:
%   cst      - matRad CST with inserted/updated BODY contour
%   bodyMask - final 3D binary body mask
%   report   - struct with diagnostics
%
% Reference entry:
%   | `matRad_generateBodyContour` | `matRad_genBodyClean` | Create BODY contour, fill gaps, remove table, and fill per-slice | `[cst, bodyMask, report] = matRad_genBodyClean(ct, cst, -500)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

    matRad_cfg = MatRad_Config.instance();

    available = matRad_checkEnvDicomRequirements(matRad_cfg.env);
    if ~available
        matRad_cfg.dispError('Image processing toolbox / packages not available!');
    end

    if nargin < 3 || isempty(thresholdHU)
        thresholdHU = -500;
    end

    p = inputParser();
    p.addParameter('excludeHUrange',   [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
    p.addParameter('closeRadius',       1, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('keepLargestCC',  true, @(x) islogical(x) || isnumeric(x));
    p.addParameter('sliceCloseRadius', 15, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    p.addParameter('sliceFill',      true, @(x) islogical(x) || isnumeric(x));
    p.addParameter('replaceExisting',false, @(x) islogical(x) || isnumeric(x));
    p.addParameter('bodyNames', {'BODY','Body','External','external','body', 'Body outline'}, @iscell);
    p.parse(varargin{:});
    opt = p.Results;

    huCube = ct.cubeHU{1};

    % 1) Threshold HU
    mask0 = huCube > thresholdHU;

    % 2) Optionally remove a specific HU interval
    if ~isempty(opt.excludeHUrange)
        huMin = min(opt.excludeHUrange);
        huMax = max(opt.excludeHUrange);
        maskRemove = huCube >= huMin & huCube <= huMax;
        mask0(maskRemove) = false;
    end

    % 3) Close small gaps in 3D
    if opt.closeRadius > 0
        n = 2*opt.closeRadius + 1;
        se = true(n, n, n);
        mask1 = imclose(mask0, se);
    else
        mask1 = mask0;
    end

    % 4) Fill holes in 3D
    bodyMask = imfill(mask1, 'holes');

    % 5) Remove disconnected objects, e.g. table/couch
    nCompBefore    = 0;
    compSizesBefore = [];

    ccBefore    = bwconncomp(bodyMask, 26);
    nCompBefore = ccBefore.NumObjects;
    if nCompBefore > 0
        compSizesBefore = cellfun(@numel, ccBefore.PixelIdxList);
    end

    if opt.keepLargestCC && ccBefore.NumObjects > 1
        [~, ixLargest] = max(compSizesBefore);
        maskLargest = false(size(bodyMask));
        maskLargest(ccBefore.PixelIdxList{ixLargest}) = true;
        bodyMask = maskLargest;
    end

    % 6) Per-slice 2D closing + 7) per-slice 2D fill (axial plane)
    %    Bridges internal gaps like lungs/air pockets that survive 3D steps,
    %    producing a solid closed body outline in each axial slice
    if opt.sliceCloseRadius > 0 || opt.sliceFill
        nSlices = size(bodyMask, 3);
        if opt.sliceCloseRadius > 0
            se2d = strel('disk', opt.sliceCloseRadius);
        end
        for k = 1:nSlices
            sl = bodyMask(:,:,k);
            if opt.sliceCloseRadius > 0
                sl = imclose(sl, se2d);
            end
            if opt.sliceFill
                sl = imfill(sl, 'holes');
            end
            bodyMask(:,:,k) = sl;
        end
        fprintf('matRad_genBodyClean: slice-wise close+fill done (%d slices)\n', nSlices);
    end

    % Find existing BODY / External if requested
    bodyRow = [];
    if opt.replaceExisting
        for i = 1:size(cst,1)
            if size(cst,2) >= 2 && ~isempty(cst{i,2})
                thisName = string(cst{i,2});
                if any(strcmpi(thisName, string(opt.bodyNames)))
                    bodyRow = i;
                    break;
                end
            end
        end
    end

    % Write to CST
    if isempty(bodyRow)
        pos = size(cst,1);
        cst{pos+1,1}      = pos;
        cst{pos+1,2}      = 'BODY';
        cst{pos+1,3}      = 'OAR';
        cst{pos+1,4}{1}   = find(bodyMask);
        cst{pos+1,5}.Priority     = 99;
        cst{pos+1,5}.alphaX       = 0.1;
        cst{pos+1,5}.betaX        = 0.05;
        cst{pos+1,5}.Visible      = 1;
        cst{pos+1,5}.visibleColor = [0.1 0.65 0.3];
        cst{pos+1,6}      = [];
        bodyRow = pos + 1;
    else
        cst{bodyRow,4}{1} = find(bodyMask);
    end

    % Report
    report = struct();
    report.thresholdHU          = thresholdHU;
    report.excludeHUrange       = opt.excludeHUrange;
    report.closeRadius          = opt.closeRadius;
    report.keepLargestCC        = logical(opt.keepLargestCC);
    report.sliceCloseRadius     = opt.sliceCloseRadius;
    report.sliceFill            = logical(opt.sliceFill);
    report.bodyRow              = bodyRow;
    report.nVoxelsInitial       = nnz(mask0);
    report.nVoxelsFinal         = nnz(bodyMask);
    report.nComponentsBefore    = nCompBefore;
    report.componentSizesBefore = compSizesBefore;

    fprintf('matRad_genBodyClean: thresholdHU = %.1f\n', thresholdHU);
    fprintf('matRad_genBodyClean: initial voxels = %d\n', report.nVoxelsInitial);
    fprintf('matRad_genBodyClean: final voxels   = %d\n', report.nVoxelsFinal);
    fprintf('matRad_genBodyClean: components before largest-CC filtering = %d\n', report.nComponentsBefore);
end