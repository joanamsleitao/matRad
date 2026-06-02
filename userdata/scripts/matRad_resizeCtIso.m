function [ctResized, report] = matRad_resizeCtIso(ctRef, ctMid)
% matRad_resizeCtIso - Resize mid-treatment CT to reference CT dimensions
%                      while aligning CT world isocenters
%
% Syntax:
%   ctResized = matRad_resizeCtIso(ctRef, ctMid)
%   [ctResized, report] = matRad_resizeCtIso(ctRef, ctMid)
%
% Description:
%   Resamples the HU cube of ctMid to the target dimensions defined by ctRef.
%   The output CT keeps the anatomical world isocenter of ctMid, while the
%   voxel grid size and resolution are taken from ctRef.
%
%   This is useful when a mid-treatment CT must be mapped to a new grid size
%   while preserving its anatomical center in world coordinates.
%
% Inputs:
%   ctRef - reference matRad CT struct providing target cubeDim and resolution
%   ctMid - mid-treatment matRad CT struct to be resized
%
% Outputs:
%   ctResized - resized CT on the target grid
%   report    - struct with diagnostics:
%                 .dimRef
%                 .dimMid
%                 .dimResized
%                 .resRef
%                 .resMid
%                 .isoCubeRef_mm
%                 .isoCubeMid_mm
%                 .isoWorldRef_mm
%                 .isoWorldMid_mm
%                 .originResized_mm
%                 .extentResized_mm
%
% Notes:
%   - HU values are resized in index space using imresize3 with linear
%     interpolation.
%   - The resized CT axes are rebuilt so that the world-coordinate isocenter
%     of ctResized matches the world-coordinate isocenter of ctMid.
%
% Reference entry:
%   | `matRad_resizeCt` | `matRad_resizeCtIso` | Resize mid-treatment CT to reference dimensions while preserving mid-treatment world isocenter | `[ctResized, report] = matRad_resizeCtIso(ctRef, ctMid)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

    dimRef = ctRef.cubeDim;
    dimMid = ctMid.cubeDim;

    resRef = ctRef.resolution;
    resMid = ctMid.resolution;

    volMid = double(ctMid.cubeHU{1});
    volResized = imresize3(volMid, dimRef, 'linear');

    isoCubeRef_mm = [((dimRef(2)+1)/2) * resRef.x, ...
                     ((dimRef(1)+1)/2) * resRef.y, ...
                     ((dimRef(3)+1)/2) * resRef.z];

    isoCubeMid_mm = [((dimMid(2)+1)/2) * resMid.x, ...
                     ((dimMid(1)+1)/2) * resMid.y, ...
                     ((dimMid(3)+1)/2) * resMid.z];

    isoWorldRef_mm = matRad_cubeCoords2worldCoords(isoCubeRef_mm, ctRef);
    isoWorldMid_mm = matRad_cubeCoords2worldCoords(isoCubeMid_mm, ctMid);

    x0 = isoWorldMid_mm(1) - (((dimRef(2)+1)/2) - 1) * resRef.x;
    y0 = isoWorldMid_mm(2) - (((dimRef(1)+1)/2) - 1) * resRef.y;
    z0 = isoWorldMid_mm(3) - (((dimRef(3)+1)/2) - 1) * resRef.z;

    xNew = x0 + (0:dimRef(2)-1) * resRef.x;
    yNew = y0 + (0:dimRef(1)-1) * resRef.y;
    zNew = z0 + (0:dimRef(3)-1) * resRef.z;

    ctResized = ctMid;
    ctResized.cubeHU = {cast(volResized, class(ctMid.cubeHU{1}))};
    ctResized.cubeDim = dimRef;
    ctResized.resolution = resRef;
    ctResized.x = xNew;
    ctResized.y = yNew;
    ctResized.z = zNew;

    report = struct();
    report.dimRef = dimRef;
    report.dimMid = dimMid;
    report.dimResized = dimRef;
    report.resRef = resRef;
    report.resMid = resMid;
    report.isoCubeRef_mm = isoCubeRef_mm;
    report.isoCubeMid_mm = isoCubeMid_mm;
    report.isoWorldRef_mm = isoWorldRef_mm;
    report.isoWorldMid_mm = isoWorldMid_mm;
    report.originResized_mm = [xNew(1) yNew(1) zNew(1)];
    report.extentResized_mm = [xNew(1) xNew(end); yNew(1) yNew(end); zNew(1) zNew(end)];

    fprintf('matRad_resizeCtIso: dimMid     = [%d %d %d]\n', dimMid(1), dimMid(2), dimMid(3));
    fprintf('matRad_resizeCtIso: dimRef     = [%d %d %d]\n', dimRef(1), dimRef(2), dimRef(3));
    fprintf('matRad_resizeCtIso: isoMid     = [%.3f %.3f %.3f] mm\n', isoWorldMid_mm);
    fprintf('matRad_resizeCtIso: new origin = [%.3f %.3f %.3f] mm\n', xNew(1), yNew(1), zNew(1));
    fprintf('matRad_resizeCtIso: new extent x=[%.3f %.3f], y=[%.3f %.3f], z=[%.3f %.3f]\n', ...
        xNew(1), xNew(end), yNew(1), yNew(end), zNew(1), zNew(end));
end