function hFig = matRad_raysLinePerBeam(ct, cst, stf, doseCube, plane, zoomFactor)
% matRad_raysLinePerBeam - Create tiled figures of all beams and rays in a plan
%
% Syntax:
%   hFig = matRad_raysLinePerBeam(ct, cst, pln, stf)
%   hFig = matRad_raysLinePerBeam(ct, cst, pln, stf, doseDirect)
%   hFig = matRad_raysLinePerBeam(ct, cst, pln, stf, doseDirect, plane)
%   hFig = matRad_raysLinePerBeam(ct, cst, pln, stf, doseDirect, plane, zoomFactor)
%
% Description:
%   Creates one or more tiled figures where each tile shows the CT/CST
%   background and all rays belonging to one beam using
%   matRad_plotRaySortZ(ax, stf(iBeam)).
%
%   A maximum of 2 beam plots is shown per figure.
%   The z-slice legend is shown only once, in the first beam tile.
%   A common zoom window is applied to all axes using matRad_getZoomWindow.
%
% Inputs:
%   ct         - matRad CT structure
%   cst        - matRad CST structure
%   pln        - matRad plan structure
%   stf        - matRad steering file structure
%   doseDirect - (optional) dose cube to overlay in each tile
%   plane      - (optional) view plane index, forced to 3 (axial)
%   zoomFactor - (optional) zoom factor for common display window
%
% Outputs:
%   hFig - Array of figure handles, one per created figure
%
% Reference entry:
% | `N/A` | `matRad_raysLinePerBeam` | Create tiled beam and ray plots, 2 per figure | `hFig = matRad_raysLinePerBeam(ct, cst, pln, stf, doseDirect, 3, 0.15)` | 🟢 |
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
    warning('matRad_raysLinePerBeam:PlaneForcedToAxial', ...
        'Only axial plane is supported. Forcing plane = 3.');
    plane = 3;
end

nBeams = numel(stf);
if nBeams == 0
    error('matRad_raysLinePerBeam:NoBeams', ...
        'The STF contains no beams.');
end

% Common zoom window for all figures
xCenter = round(ct.cubeDim(2) / 2);
yCenter = round(ct.cubeDim(1) / 2);

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

        % Background
        [slice, hleg] = matRad_showSliceFast(ct, cst, doseCube, ...
            [], [], 1, zoomFactor);
        hold(ax, 'on');

        % Plot all rays in this beam
        matRad_plotRaySortZ(ax, stf(iBeam));

        % Keep legend only once: first beam tile of the first figure
        if iFig == 1 && iTile == 1
            legend(ax, 'show', 'Location', 'eastoutside', 'Interpreter', 'none');
        else
            legend(ax, 'off');
        end

        % Consistent axes appearance
        set(ax, 'Color', 'none');
        set(ax, 'Layer', 'top');

        nRays = 0;
        if isfield(stf(iBeam), 'ray')
            nRays = numel(stf(iBeam).ray);
        end

        title(ax, sprintf('Beam %d (%d rays)', iBeam, nRays), ...
            'Interpreter', 'none');

    end
end

end