function [ctResized, cstResized, report] = matRad_resizeCtCst(ctOg, ctMid, cstMid, varargin)
% matRad_resizeCtCst - Resize mid-treatment CT and CST to reference CT grid
%                      with isocenter alignment, body contour regeneration,
%                      and optional visualization
%
% Syntax:
%   [ctResized, cstResized] = matRad_resizeCtCst(ctOg, ctMid, cstMid)
%   [ctResized, cstResized, report] = matRad_resizeCtCst(ctOg, ctMid, cstMid, Name, Value)
%
% Description:
%   Combines matRad_resizeCtIso, matRad_checkIsoAlign, matRad_resizeCstIso,
%   and matRad_createBody into a single pipeline. Resizes ctMid to the grid
%   of ctOg (same dimensions and resolution) while anchoring the world
%   isocenter of ctMid. Resamples cstMid onto the new grid using world-
%   coordinate nearest-neighbour interpolation. Optionally regenerates the
%   body contour using matRad_createBody (with gap filling, couch removal,
%   and per-slice closing/fill) and visualizes the result.
%
% Inputs:
%   ctOg   - reference matRad CT struct (provides target cubeDim + resolution)
%   ctMid  - mid-treatment matRad CT struct to resize
%   cstMid - mid-treatment matRad CST cell array defined on ctMid
%
% Name-Value Options:
%   'visualize'        - show result with matRad_showAllPlanes (default: true)
%   'nSlices'          - slices per plane for visualization (default: 6)
%   'regenBody'        - delete existing body and regenerate (default: true)
%   'thresholdHU'      - HU threshold for body contour (default: -500)
%   'isoTol'           - isocenter alignment tolerance in mm (default: 1.0)
%   'closeRadius'      - 3D closing radius in voxels for body (default: 1)
%   'sliceCloseRadius' - 2D per-slice closing radius in px for body (default: 15)
%   'sliceFill'        - per-slice 2D imfill after slice closing (default: true)
%   'keepLargestCC'    - keep only largest CC to remove couch (default: true)
%
% Outputs:
%   ctResized  - resized CT on ctOg grid, isocenter-aligned to ctMid
%   cstResized - resized CST on ctResized grid
%   report     - struct with full pipeline diagnostics:
%                  .ct       (from matRad_resizeCtIso)
%                  .align    (from matRad_checkIsoAlign)
%                  .cst      (from matRad_resizeCstIso)
%                  .body     (from matRad_createBody)
%                  .bodyRegenerated
%                  .bodyIdx
%
% Notes:
%   - If isocenter shift exceeds isoTol, an error is raised and the
%     pipeline is aborted before CST resampling.
%   - Body contour regeneration uses matRad_createBody.
%   - Visualization uses matRad_showAllPlanes.
%
% Reference entry:
%   | `matRad_resizeCtIso` + `matRad_resizeCstIso` | `matRad_resizeCtCst` | Full pipeline: resize mid-treatment CT and CST to reference grid with isocenter alignment and body regeneration | `[ctResized, cstResized, report] = matRad_resizeCtCst(ctOg, ctMid, cstMid)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

    % ------------------------------------------------------------------ %
    %  Parse inputs
    % ------------------------------------------------------------------ %
    p = inputParser();
    p.addParameter('visualize',        true,  @islogical);
    p.addParameter('nSlices',          6,     @isnumeric);
    p.addParameter('regenBody',        true,  @islogical);
    p.addParameter('thresholdHU',      -300,  @isnumeric);
    p.addParameter('isoTol',           1.0,   @isnumeric);
    p.addParameter('closeRadius',      1,     @isnumeric);
    p.addParameter('sliceCloseRadius', 15,    @isnumeric);
    p.addParameter('sliceFill',        true,  @islogical);
    p.addParameter('keepLargestCC',    true,  @islogical);
    p.parse(varargin{:});
    opt = p.Results;

    report = struct();

    % ------------------------------------------------------------------ %
    %  1. Resize CT (isocenter-anchored)
    % ------------------------------------------------------------------ %
    fprintf('\n--- Step 1: Resize CT ---\n');
    [ctResized, reportCt] = matRad_resizeCtIso(ctOg, ctMid);
    report.ct = reportCt;

    % ------------------------------------------------------------------ %
    %  2. Check alignment
    % ------------------------------------------------------------------ %
    fprintf('\n--- Step 2: Check Alignment ---\n');
    reportAlign = matRad_checkIsoAlign(ctMid, ctResized);
    report.align = reportAlign;

    if ~reportAlign.isAligned
        error('matRad_resizeCtCst:isoMismatch', ...
            ['Isocenter shift [%.3f %.3f %.3f] mm exceeds tolerance %.1f mm.\n' ...
             'Check CT grid definitions before proceeding.'], ...
            reportAlign.isoShift_mm(1), reportAlign.isoShift_mm(2), ...
            reportAlign.isoShift_mm(3), opt.isoTol);
    end

    if ~reportAlign.hasOverlap
        error('matRad_resizeCtCst:noOverlap', ...
            'CT grids have no world-coordinate overlap. CST resampling aborted.');
    end

    % ------------------------------------------------------------------ %
    %  3. Resize CST
    % ------------------------------------------------------------------ %
    fprintf('\n--- Step 3: Resize CST ---\n');
    [cstResized, reportCst] = matRad_resizeCstIso(cstMid, ctMid, ctResized);
    report.cst = reportCst;

    % ------------------------------------------------------------------ %
    %  4. Regenerate body contour
    % ------------------------------------------------------------------ %
    report.bodyRegenerated = false;
    report.bodyIdx         = [];
    report.body            = [];

    if opt.regenBody
        fprintf('\n--- Step 4: Regenerate Body Contour ---\n');

        % Find and remove existing body/external structure
        bodyNames = {'BODY','Body','External','external','body','Body outline'};
        bodyIdx = [];
        for i = 1:size(cstResized,1)
            if size(cstResized,2) >= 2 && ~isempty(cstResized{i,2})
                if any(strcmpi(string(cstResized{i,2}), string(bodyNames)))
                    bodyIdx = i;
                    break;
                end
            end
        end

        if ~isempty(bodyIdx)
            fprintf('matRad_resizeCtCst: removing existing body structure at row %d ("%s")\n', ...
                bodyIdx, cstResized{bodyIdx, 2});
            cstResized(bodyIdx, :) = [];
        else
            fprintf('matRad_resizeCtCst: no existing body structure found, adding new one\n');
        end

        % Regenerate body contour using matRad_createBody
        [cstResized, ~, reportBody] = matRad_createBody(ctResized, cstResized, opt.thresholdHU, ...
            'closeRadius',      opt.closeRadius,      ...
            'sliceCloseRadius', opt.sliceCloseRadius, ...
            'sliceFill',        true,        ...
            'keepLargestCC',    true,    ...
            'replaceExisting',  true);

        report.body            = reportBody;
        report.bodyRegenerated = true;
        report.bodyIdx         = reportBody.bodyRow;

        fprintf('matRad_resizeCtCst: body contour regenerated at row %d (threshold = %d HU)\n', ...
            reportBody.bodyRow, opt.thresholdHU);
    end

    % ------------------------------------------------------------------ %
    %  5. Visualization
    % ------------------------------------------------------------------ %
    if opt.visualize
        fprintf('\n--- Step 5: Visualization ---\n');
        matRad_showAllPlanes(ctResized, cstResized, [], opt.nSlices, [], 3);
    end

    fprintf('\n✅ matRad_resizeCtCst: pipeline complete.\n');
    fprintf('   dimOld = [%d %d %d]  →  dimNew = [%d %d %d]\n', ...
        report.ct.dimMid(1), report.ct.dimMid(2), report.ct.dimMid(3), ...
        report.ct.dimRef(1), report.ct.dimRef(2), report.ct.dimRef(3));
    fprintf('   iso shift = [%.3f %.3f %.3f] mm\n', report.align.isoShift_mm);
    fprintf('   empty structures = %d\n', report.cst.nEmpty);
    fprintf('   body regenerated = %d\n', report.bodyRegenerated);
end