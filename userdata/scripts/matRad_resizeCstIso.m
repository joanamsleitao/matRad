function [cstOut, report] = matRad_resizeCstIso(cstMid, ctMid, ctMidResized)
% matRad_resizeCstIso - Resize mid-treatment CST to a resized mid-treatment
%                       CT using world-coordinate interpolation with aligned isocenters
%
% Syntax:
%   cstOut = matRad_resizeCstIso(cstMid, ctMid, ctMidResized)
%   [cstOut, report] = matRad_resizeCstIso(cstMid, ctMid, ctMidResized)
%
% Description:
%   Resamples all VOI masks stored in cstMid from the original ctMid grid
%   to the ctMidResized grid using world-coordinate nearest-neighbour
%   interpolation. This function assumes ctMidResized has already been built
%   so that its world isocenter is aligned with ctMid.
%
% Inputs:
%   cstMid       - matRad CST cell array defined on ctMid
%   ctMid        - original mid-treatment matRad CT struct
%   ctMidResized - resized mid-treatment matRad CT struct
%
% Outputs:
%   cstOut - resized CST on ctMidResized grid
%   report - struct with diagnostics:
%              .dimOld
%              .dimNew
%              .isoWorldOld_mm
%              .isoWorldNew_mm
%              .isoShift_mm
%              .nEmpty
%              .emptyStructures
%
% Notes:
%   - This function assumes cst{i,4}{j} contains linear voxel indices.
%   - Nearest-neighbour interpolation is used to preserve binary masks.
%   - NaN values produced outside the interpolation domain are set to zero.
%
% Reference entry:
%   | `matRad_resizeCstToGrid` | `matRad_resizeCstIso` | Resize mid-treatment CST to resized CT using world-coordinate interpolation with aligned isocenters | `[cstOut, report] = matRad_resizeCstIso(cstMid, ctMid, ctMidResized)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

    cstOut = cstMid;

    xOld = ctMid.x(:)';
    yOld = ctMid.y(:)';
    zOld = ctMid.z(:)';

    xNew = ctMidResized.x(:)';
    yNew = ctMidResized.y(:)';
    zNew = ctMidResized.z(:)';

    if isfield(ctMid, 'cubeDim')
        dimOld = ctMid.cubeDim;
    else
        dimOld = [numel(yOld) numel(xOld) numel(zOld)];
    end

    if isfield(ctMidResized, 'cubeDim')
        dimNew = ctMidResized.cubeDim;
    else
        dimNew = [numel(yNew) numel(xNew) numel(zNew)];
    end

    isoCubeOld_mm = [((dimOld(2)+1)/2) * ctMid.resolution.x, ...
                     ((dimOld(1)+1)/2) * ctMid.resolution.y, ...
                     ((dimOld(3)+1)/2) * ctMid.resolution.z];

    isoCubeNew_mm = [((dimNew(2)+1)/2) * ctMidResized.resolution.x, ...
                     ((dimNew(1)+1)/2) * ctMidResized.resolution.y, ...
                     ((dimNew(3)+1)/2) * ctMidResized.resolution.z];

    isoWorldOld_mm = matRad_cubeCoords2worldCoords(isoCubeOld_mm, ctMid);
    isoWorldNew_mm = matRad_cubeCoords2worldCoords(isoCubeNew_mm, ctMidResized);
    isoShift_mm = isoWorldNew_mm - isoWorldOld_mm;

    fprintf('matRad_resizeCstIso: old iso = [%.3f %.3f %.3f] mm\n', isoWorldOld_mm);
    fprintf('matRad_resizeCstIso: new iso = [%.3f %.3f %.3f] mm\n', isoWorldNew_mm);
    fprintf('matRad_resizeCstIso: shift   = [%.3f %.3f %.3f] mm\n', isoShift_mm);

    if any(abs(isoShift_mm) > 1e-3)
        warning('matRad_resizeCstIso:isoMismatch', ...
            'ctMid and ctMidResized isocenters are not aligned within tolerance.');
    end

    emptyStructures = {};

    for i = 1:size(cstMid,1)
        for j = 1:numel(cstMid{i,4})

            idxOld = cstMid{i,4}{j};

            if isempty(idxOld)
                cstOut{i,4}{j} = [];
                continue;
            end

            idxOld = idxOld(idxOld >= 1 & idxOld <= prod(dimOld));

            maskOld = false(dimOld);
            maskOld(idxOld) = true;

            maskNew = matRad_interp3(xOld, yOld, zOld, double(maskOld), ...
                                     xNew, yNew', zNew, 'nearest');

            maskNew(isnan(maskNew)) = 0;
            maskNew = maskNew > 0.5;

            idxNew = find(maskNew);

            if isempty(idxNew)
                emptyStructures{end+1} = sprintf('%s (scenario %d)', cstMid{i,2}, j); %#ok<AGROW>
                warning('matRad_resizeCstIso:emptyStructure', ...
                    'Resizing created an empty structure "%s" in scenario %d.', ...
                    cstMid{i,2}, j);
            end

            cstOut{i,4}{j} = idxNew;
        end
    end

    report = struct();
    report.dimOld = dimOld;
    report.dimNew = dimNew;
    report.isoWorldOld_mm = isoWorldOld_mm;
    report.isoWorldNew_mm = isoWorldNew_mm;
    report.isoShift_mm = isoShift_mm;
    report.nEmpty = numel(emptyStructures);
    report.emptyStructures = emptyStructures;

    fprintf('matRad_resizeCstIso: done. Empty structures: %d\n', report.nEmpty);
end