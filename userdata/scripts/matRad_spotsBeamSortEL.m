function hFig = matRad_spotsBeamSortEL(ct, cst, stf, doseCube, plane, zoomFactor)
% matRad_spotsBeamSortEL - Create tiled figures of spots in the displayed slice for all beams
%
% Syntax:
%   hFig = matRad_spotsBeamSortEL(ct, cst, stf)
%   hFig = matRad_spotsBeamSortEL(ct, cst, stf, doseCube)
%   hFig = matRad_spotsBeamSortEL(ct, cst, stf, doseCube, plane)
%   hFig = matRad_spotsBeamSortEL(ct, cst, stf, doseCube, plane, zoomFactor)
%
% Description:
%   Creates one or more tiled figures where each tile shows the CT/CST
%   background for the currently displayed slice and all spots belonging to
%   one beam in that slice.
%
%   Spots are plotted color-coded by energy layer using
%   matRad_plotSpotsBeamSortE(ax, stf(iBeam), sliceShown, ct).
%
%   Each beam tile shows its own legend.
%
% Inputs:
%   ct         - matRad CT structure
%   cst        - matRad CST structure
%   stf        - matRad steering file structure
%   doseCube   - (optional) dose cube to overlay in each tile
%   plane      - (optional) view plane index, forced to 3 (axial)
%   zoomFactor - (optional) zoom factor for common display window
%
% Outputs:
%   hFig - Array of figure handles, one per created figure
%
% Reference entry:
% | `N/A` | `matRad_spotsBeamSortEL` | Create tiled beam plots of spots in one slice, sorted by energy layer | `hFig = matRad_spotsBeamSortEL(ct, cst, stf, doseCube, 3, 0.85)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 4 || isempty(doseCube)
    doseCube = [];
end

if nargin < 5 || isempty(plane)
    plane = 3;
end

if nargin < 6 || isempty(zoomFactor)
    zoomFactor = 0.85;
end

if plane ~= 3
    warning('matRad_spotsBeamSortEL:PlaneForcedToAxial', ...
        'Only axial plane is supported. Forcing plane = 3.');
    plane = 3; %#ok<NASGU>
end

nBeams = numel(stf);
if nBeams == 0
    error('matRad_spotsBeamSortEL:NoBeams', ...
        'The STF contains no beams.');
end

% Figure batching: 2 beam tiles per figure
maxPlotsPerFig = 2;
nFigs = ceil(nBeams / maxPlotsPerFig);
hFig = gobjects(nFigs, 1);

beamCounter = 0;

for iFig = 1:nFigs
    nThisFig = min(maxPlotsPerFig, nBeams - beamCounter);

    hFig(iFig) = figure( ...
        'Color', 'w', ...
        'Units', 'normalized', ...
        'OuterPosition', [0 0 1 1]);

    t = tiledlayout(hFig(iFig), 1, nThisFig, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact');

    for iTile = 1:nThisFig
        beamCounter = beamCounter + 1;
        iBeam = beamCounter;

        ax = nexttile(t, iTile);

        % Background slice
        [sliceShown, ~] = matRad_showSliceFast(ct, cst, doseCube, [], [], 1, zoomFactor);
        hold(ax, 'on');

        % Overlay spots in the displayed slice, sorted by energy layer
        [~, hLayer] = matRad_plotSpotsBeamSortE(ax, stf(iBeam), sliceShown, ct);

        % Local legend for this beam only
        hLayer = hLayer(isgraphics(hLayer));
        if ~isempty(hLayer)
            legend(ax, hLayer, get(hLayer, 'DisplayName'), ...
                'Location', 'eastoutside', 'Interpreter', 'none');
        else
            legend(ax, 'off');
        end

        % Consistent axes appearance
        set(ax, 'Color', 'none');
        set(ax, 'Layer', 'top');
        set(ax, 'Box', 'on');

        nRays = 0;
        if isfield(stf(iBeam), 'ray')
            nRays = numel(stf(iBeam).ray);
        end

        gantryAngle = NaN;
        if isfield(stf(iBeam), 'gantryAngle') && ~isempty(stf(iBeam).gantryAngle)
            gantryAngle = stf(iBeam).gantryAngle;
        end

        if ~isnan(gantryAngle)
            title(ax, sprintf('Beam %d | gantry %.1f° | %d rays | slice %d', ...
                iBeam, gantryAngle, nRays, sliceShown), ...
                'Interpreter', 'none');
        else
            title(ax, sprintf('Beam %d | %d rays | slice %d', ...
                iBeam, nRays, sliceShown), ...
                'Interpreter', 'none');
        end
    end
end

end