function hFig = matRad_raysPerPlan(ct, cst, pln, stf, doseCube, plane, weights)
% matRad_raysPerPlan - Create a tiled overview of all beams and rays in a plan
%
% Syntax:
%   hFig = matRad_raysPerPlan(ct, cst, pln, stf)
%   hFig = matRad_raysPerPlan(ct, cst, pln, stf, doseCube)
%   hFig = matRad_raysPerPlan(ct, cst, pln, stf, doseCube, plane)
%   hFig = matRad_raysPerPlan(ct, cst, pln, stf, doseCube, plane, weights)
%
% Description:
%   Creates a tiled figure where:
%     1) The first tile shows the CT/CST background and all beam directions
%        using matRad_showSliceFast(ct, cst, doseCube) and
%        matRad_plotBeamAnglesCoplanar(ax, pln, ct, plane)
%     2) Each following tile shows the CT/CST background and all rays
%        belonging to one beam
%
%   The figure is axial-only and meant to be centered at the isocenter.
%   Rays are plotted with fixed marker size and without GeoSpots.
%
% Inputs:
%   ct       - matRad CT structure
%   cst      - matRad CST structure
%   pln      - matRad plan structure
%   stf      - matRad steering file struct
%   doseCube - (optional) dose cube to overlay in the overview tile
%   plane    - (optional) view plane index, forced to 3 (axial)
%   weights  - (optional) spot weights vector for the full plan
%
% Outputs:
%   hFig - Figure handle
%
% Reference entry:
% | `N/A` | `matRad_raysPerPlan` | Create tiled beam overview and per-beam ray plots | `hFig = matRad_raysPerPlan(ct, cst, pln, stf, doseCube, 3, weights)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% Defaults / enforce axial
if ~exist('plane','var') || isempty(plane)
    plane = 3;
end
if plane ~= 3
    warning('matRad_raysPerPlan:PlaneForcedToAxial', ...
        'Only axial plane is supported. Forcing plane = 3.');
    plane = 3;
end

if ~exist('doseCube','var') || isempty(doseCube)
    doseCube = [];
end

if ~exist('weights','var') || isempty(weights)
    totalNumOfBixels = sum([stf.totalNumOfBixels]);
    weights = ones(totalNumOfBixels, 1);
end

nBeams = numel(stf);
if nBeams == 0
    error('matRad_raysPerPlan:NoBeams', ...
        'The STF contains no beams.');
end

% Figure and layout
hFig = figure('Color','w', 'Units','normalized', 'OuterPosition',[0 0 1 1]);
nTiles = nBeams + 1;
nCols  = ceil(sqrt(nTiles));
nRows  = ceil(nTiles / nCols);

t = tiledlayout(hFig, nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

% ---------------------------------------------------------------------
% Tile 1: beam overview
% ---------------------------------------------------------------------
ax0 = nexttile(t, 1);
matRad_showSliceFast(ct, cst, doseCube);
hold(ax0, 'on');
matRad_plotBeamAnglesCoplanar(ax0, pln, ct, plane);
title(ax0, 'all beams', 'Interpreter', 'none');
axis(ax0, 'equal');
axis(ax0, 'tight');
box(ax0, 'on');

% ---------------------------------------------------------------------
% Beam tiles: one tile per beam, all rays in the beam
% ---------------------------------------------------------------------
markerSize = 7;

for iBeam = 1%:nBeams
    ax = nexttile(t, iBeam + 1);

    matRad_showSliceFast(ct, cst, []);
    hold(ax, 'on');

    nRays = numel(stf(iBeam).ray);

    for iRay = 1:nRays
        % Build a per-ray weight vector matching the spots in this ray
        nSpots = numel(stf(iBeam).ray(iRay).energy);
        rayWeights = ones(nSpots, 1);

        for iSpot = 1:nSpots
            wIx = matRad_spotIx(stf, iBeam, iRay, iSpot);
            if ~isempty(weights) && wIx >= 1 && wIx <= numel(weights)
                rayWeights(iSpot) = weights(wIx);
            end
        end

        matRad_plotRay(ax, stf, iBeam, iRay, markerSize, rayWeights, false, false);
    end

    title(ax, sprintf('Beam %d (%d rays)', iBeam, nRays), ...
        'Interpreter', 'none');

    axis(ax, 'equal');
    axis(ax, 'tight');
    box(ax, 'on');
end

end