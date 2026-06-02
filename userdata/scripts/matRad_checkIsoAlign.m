function report = matRad_checkIsoAlign(ctMid, ctMidResized)
% matRad_checkIsoAlign - Diagnostic check of world-coordinate alignment
%                        between two CT grids
%
% Syntax:
%   report = matRad_checkIsoAlign(ctMid, ctMidResized)
%
% Description:
%   Computes and prints the world-coordinate isocenter, extent, overlap,
%   and shift between two CT grids. Useful for debugging spatial alignment
%   before running matRad_resizeCtIso or matRad_resizeCstIso.
%
% Inputs:
%   ctMid        - original mid-treatment matRad CT struct
%   ctMidResized - resized mid-treatment matRad CT struct
%
% Outputs:
%   report - struct with alignment diagnostics:
%              .dimOld, .dimNew
%              .resOld, .resNew
%              .isoWorldOld_mm, .isoWorldNew_mm
%              .isoShift_mm
%              .extentOld, .extentNew
%              .overlap_mm
%              .overlapFraction
%              .isAligned (logical, true if shift < 1 mm in all axes)
%              .hasOverlap (logical, true if overlap > 0 in all axes)
%
% Reference entry:
%   | - | `matRad_checkIsoAlign` | Diagnostic check of world-coordinate alignment between two CT grids | `report = matRad_checkIsoAlign(ctMid, ctMidResized)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

    dimOld = ctMid.cubeDim;
    dimNew = ctMidResized.cubeDim;

    resOld = ctMid.resolution;
    resNew = ctMidResized.resolution;

    % --- World extents ---
    xOld = ctMid.x(:)';         yOld = ctMid.y(:)';         zOld = ctMid.z(:)';
    xNew = ctMidResized.x(:)';  yNew = ctMidResized.y(:)';  zNew = ctMidResized.z(:)';

    extentOld = [xOld(1) xOld(end); yOld(1) yOld(end); zOld(1) zOld(end)];
    extentNew = [xNew(1) xNew(end); yNew(1) yNew(end); zNew(1) zNew(end)];

    % --- Isocenters (geometric cube center) ---
    isoCubeOld_mm = [((dimOld(2)+1)/2) * resOld.x, ...
                     ((dimOld(1)+1)/2) * resOld.y, ...
                     ((dimOld(3)+1)/2) * resOld.z];

    isoCubeNew_mm = [((dimNew(2)+1)/2) * resNew.x, ...
                     ((dimNew(1)+1)/2) * resNew.y, ...
                     ((dimNew(3)+1)/2) * resNew.z];

    isoWorldOld_mm = matRad_cubeCoords2worldCoords(isoCubeOld_mm, ctMid);
    isoWorldNew_mm = matRad_cubeCoords2worldCoords(isoCubeNew_mm, ctMidResized);
    isoShift_mm    = isoWorldNew_mm - isoWorldOld_mm;

    % --- Overlap ---
    overlapX_mm = max(0, min(xOld(end), xNew(end)) - max(xOld(1), xNew(1)));
    overlapY_mm = max(0, min(yOld(end), yNew(end)) - max(yOld(1), yNew(1)));
    overlapZ_mm = max(0, min(zOld(end), zNew(end)) - max(zOld(1), zNew(1)));

    totalExtentX = max(xOld(end), xNew(end)) - min(xOld(1), xNew(1));
    totalExtentY = max(yOld(end), yNew(end)) - min(yOld(1), yNew(1));
    totalExtentZ = max(zOld(end), zNew(end)) - min(zOld(1), zNew(1));

    overlapFraction = [overlapX_mm / totalExtentX, ...
                       overlapY_mm / totalExtentY, ...
                       overlapZ_mm / totalExtentZ];

    isAligned  = all(abs(isoShift_mm) < 1.0);
    hasOverlap = overlapX_mm > 0 && overlapY_mm > 0 && overlapZ_mm > 0;

    % --- Print report ---
    fprintf('\n========== matRad_checkIsoAlign ==========\n');
    fprintf('  %-20s [%d %d %d]  →  [%d %d %d]\n', 'cubeDim:', ...
        dimOld(1), dimOld(2), dimOld(3), dimNew(1), dimNew(2), dimNew(3));
    fprintf('  %-20s [%.4f %.4f %.4f]  →  [%.4f %.4f %.4f] mm\n', 'resolution (xyz):', ...
        resOld.x, resOld.y, resOld.z, resNew.x, resNew.y, resNew.z);
    fprintf('\n  World extent (old):\n');
    fprintf('    x: [%8.3f  →  %8.3f] mm\n', extentOld(1,1), extentOld(1,2));
    fprintf('    y: [%8.3f  →  %8.3f] mm\n', extentOld(2,1), extentOld(2,2));
    fprintf('    z: [%8.3f  →  %8.3f] mm\n', extentOld(3,1), extentOld(3,2));
    fprintf('\n  World extent (new):\n');
    fprintf('    x: [%8.3f  →  %8.3f] mm\n', extentNew(1,1), extentNew(1,2));
    fprintf('    y: [%8.3f  →  %8.3f] mm\n', extentNew(2,1), extentNew(2,2));
    fprintf('    z: [%8.3f  →  %8.3f] mm\n', extentNew(3,1), extentNew(3,2));
    fprintf('\n  Isocenter (old): [%8.3f %8.3f %8.3f] mm\n', isoWorldOld_mm);
    fprintf('  Isocenter (new): [%8.3f %8.3f %8.3f] mm\n', isoWorldNew_mm);
    fprintf('  Iso shift:       [%8.3f %8.3f %8.3f] mm', isoShift_mm);
    if isAligned
        fprintf('  ✓ aligned\n');
    else
        fprintf('  ✗ NOT aligned\n');
    end
    fprintf('\n  Overlap:  x=%.1f mm (%.0f%%)  y=%.1f mm (%.0f%%)  z=%.1f mm (%.0f%%)\n', ...
        overlapX_mm, overlapFraction(1)*100, ...
        overlapY_mm, overlapFraction(2)*100, ...
        overlapZ_mm, overlapFraction(3)*100);
    if hasOverlap
        fprintf('  ✓ grids overlap\n');
    else
        fprintf('  ✗ NO overlap — CST will be empty after resizing!\n');
    end
    fprintf('==========================================\n\n');

    % --- Build report struct ---
    report = struct();
    report.dimOld          = dimOld;
    report.dimNew          = dimNew;
    report.resOld          = resOld;
    report.resNew          = resNew;
    report.isoWorldOld_mm  = isoWorldOld_mm;
    report.isoWorldNew_mm  = isoWorldNew_mm;
    report.isoShift_mm     = isoShift_mm;
    report.extentOld       = extentOld;
    report.extentNew       = extentNew;
    report.overlap_mm      = [overlapX_mm overlapY_mm overlapZ_mm];
    report.overlapFraction = overlapFraction;
    report.isAligned       = isAligned;
    report.hasOverlap      = hasOverlap;
end