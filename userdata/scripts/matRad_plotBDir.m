function hOut = matRad_plotBDir(ax, stf, beamNames)
% matRad_plotBDir - Plot a simple beam-direction overview on the current
%                   CT/CST slice using one arrow per beam.
%
% Syntax:
%   hOut = matRad_plotBDir(ax, stf)
%   hOut = matRad_plotBDir(ax, stf, beamNames)
%
% Description:
%   Draws one arrow per beam on the provided axes. The arrow direction is
%   estimated from the centroid of the first ray to the centroid of the
%   last ray in each beam. This gives a compact overview of beam direction
%   without plotting individual spots.
%
%   Intended use:
%     1) Plot CT/CST background first
%     2) Call this function on top
%     3) Use it as the first tile in a tiledlayout
%
% Inputs:
%   ax        - Target axes handle. If empty, uses gca
%   stf       - matRad steering file struct array (1 x nBeams)
%   beamNames - (optional) cell array of beam labels
%
% Outputs:
%   hOut - struct with fields:
%          .arrow  - quiver handles, one per beam
%          .start  - start-marker handles, one per beam
%          .label  - text handles, one per beam
%
% Reference entry:
% | Previous Name | Current Name | Description | Call | Status |
% | --- | --- | --- | --- | --- |
% | — | `matRad_plotBDir` | Plot simple beam-direction arrows using first/last ray centroids | `hOut = matRad_plotBDir(ax, stf)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 1 || isempty(ax)
    ax = gca;
end
if nargin < 3 || isempty(beamNames)
    beamNames = {};
end

nBeams = numel(stf);
cmap   = lines(max(nBeams, 1));

hold(ax, 'on');

hOut = struct();
hOut.arrow = gobjects(nBeams, 1);
hOut.start = gobjects(nBeams, 1);
hOut.label = gobjects(nBeams, 1);

for iBeam = 1:nBeams
    if ~isfield(stf(iBeam), 'numOfRays') || stf(iBeam).numOfRays < 1
        continue;
    end

    rayFirst = stf(iBeam).ray(1);
    rayLast  = stf(iBeam).ray(stf(iBeam).numOfRays);

    pStart = localRayCentroid(rayFirst);
    pEnd   = localRayCentroid(rayLast);

    if isempty(pStart) || isempty(pEnd)
        continue;
    end

    d = pEnd(1:2) - pStart(1:2);
    if any(~isfinite(d)) || norm(d) == 0
        continue;
    end

    c = cmap(iBeam, :);

    % Arrow
    hOut.arrow(iBeam) = quiver(ax, pStart(1), pStart(2), d(1), d(2), 0, ...
        'Color', c, ...
        'LineWidth', 1.5, ...
        'MaxHeadSize', 0.35, ...
        'AutoScale', 'off');

    % Start marker
    hOut.start(iBeam) = plot(ax, pStart(1), pStart(2), 'o', ...
        'MarkerSize', 5.5, ...
        'MarkerFaceColor', 'w', ...
        'MarkerEdgeColor', c, ...
        'LineWidth', 1.2);

    % Label near the midpoint
    midPt = pStart(1:2) + 0.52 * d;
    if ~isempty(beamNames) && numel(beamNames) >= iBeam && ~isempty(beamNames{iBeam})
        lbl = beamNames{iBeam};
    else
        lbl = sprintf('Beam %d', iBeam);
    end

    hOut.label(iBeam) = text(ax, midPt(1), midPt(2), lbl, ...
        'Color', c, ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'Interpreter', 'none', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'bottom');
end

end

% -------------------------------------------------------------------------
function p = localRayCentroid(ray)
% localRayCentroid - Estimate a 2D representative point for a ray by
% averaging all valid spot positions.
p = [];

nSpots = localGetNumSpots(ray);
if nSpots < 1
    return;
end

pts = nan(nSpots, 2);
nValid = 0;

for iSpot = 1:nSpots
    [spot, ok] = localGetSpotPos(ray, iSpot);
    if ok && numel(spot) >= 2 && all(isfinite(spot(1:2)))
        nValid = nValid + 1;
        pts(nValid, :) = spot(1:2);
    end
end

pts = pts(1:nValid, :);

if isempty(pts)
    return;
end

p = mean(pts, 1);
end

% -------------------------------------------------------------------------
function nSpots = localGetNumSpots(ray)
% localGetNumSpots - Return number of spots in a ray
if isfield(ray, 'energy') && ~isempty(ray.energy)
    nSpots = numel(ray.energy);
elseif isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot')
    nSpots = numel(ray.rayTracerInfo.perSpot);
elseif isfield(ray, 'spotsInfoGeo')
    nSpots = numel(ray.spotsInfoGeo);
else
    nSpots = 0;
end
end

% -------------------------------------------------------------------------
function [spot, ok] = localGetSpotPos(ray, iSpot)
% localGetSpotPos - Get spot position from ray structure
spot = [];
ok   = false;

if iSpot < 1
    return;
end

if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot') ...
        && numel(ray.rayTracerInfo.perSpot) >= iSpot ...
        && isfield(ray.rayTracerInfo.perSpot(iSpot), 'spotCube')
    spot = ray.rayTracerInfo.perSpot(iSpot).spotCube;
    ok = true;
    return;
end

if isfield(ray, 'spotsInfoGeo') && numel(ray.spotsInfoGeo) >= iSpot ...
        && isfield(ray.spotsInfoGeo(iSpot), 'spotCube')
    spot = ray.spotsInfoGeo(iSpot).spotCube;
    ok = true;
    return;
end
end