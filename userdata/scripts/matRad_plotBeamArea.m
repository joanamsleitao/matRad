function hOut = matRad_plotBeamArea(ax, stf, iBeam, faceAlpha, edgeColor)
% matRad_plotBeamArw - Plot an arrow-shaped shaded region for one beam
%                      using boundary spots from first, middle, and last ray.
%
% Syntax:
%   hOut = matRad_plotBeamArw(ax, stf, iBeam)
%   hOut = matRad_plotBeamArw(ax, stf, iBeam, faceAlpha)
%   hOut = matRad_plotBeamArw(ax, stf, iBeam, faceAlpha, edgeColor)
%
% Description:
%   Builds an arrow-like polygon for a given beam by collecting:
%     - first spot of first ray
%     - first spot of middle ray
%     - all spots of last ray
%     - last spot of middle ray
%     - last spot of first ray
%   The resulting polygon is filled with transparent shading and outlined.
%
%   This function is intended as a compact beam-shape visualization.
%
% Inputs:
%   ax         - Target axes handle (if empty, uses gca)
%   stf        - matRad steering file struct array
%   iBeam      - Beam index to plot
%   faceAlpha  - (optional) transparency of shaded patch, default: 0.18
%   edgeColor  - (optional) RGB color or MATLAB color spec for outline/fill.
%                If omitted, a beam-specific color from lines() is used.
%
% Outputs:
%   hOut - struct with graphics handles:
%          .patch  - patch handle
%          .edge   - outline line handle
%
% Reference entry:
% | Previous Name | Current Name | Description | Call | Status |
% | --- | --- | --- | --- | --- |
% | — | `matRad_plotBeamArw` | Plot arrow-shaped shaded beam footprint from first/mid/last ray boundary spots | `[hOut] = matRad_plotBeamArw(ax, stf, iBeam)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 1 || isempty(ax)
    ax = gca;
end
if nargin < 4 || isempty(faceAlpha)
    faceAlpha = 0.18;
end

nBeams = numel(stf);
if nargin < 5 || isempty(edgeColor)
    cmap = lines(nBeams);
    edgeColor = cmap(iBeam, :);
end

hOut = struct('patch', gobjects(1), 'edge', gobjects(1));

beam = stf(iBeam);
nRays = beam.numOfRays;

if isempty(nRays) || nRays < 1
    warning('Beam %d has no rays. Skipping.', iBeam);
    return;
end

iFirst = 1;
iMid   = round((nRays + 1) / 2);
iLast  = nRays;

rayFirst = beam.ray(iFirst);
rayMid   = beam.ray(iMid);
rayLast  = beam.ray(iLast);

% Collect boundary points in the requested order
pts = [];

% 1) first spot of first ray
p = localGetSpotPos(rayFirst, 1);
pts = localAppendPoint(pts, p);

% 2) first spot of middle ray
p = localGetSpotPos(rayMid, 1);
pts = localAppendPoint(pts, p);

% 3) all spots of last ray
nSpotsLast = localGetNumSpots(rayLast);
for iSpot = 1:nSpotsLast
    p = localGetSpotPos(rayLast, iSpot);
    pts = localAppendPoint(pts, p);
end

% 4) last spot of middle ray
nSpotsMid = localGetNumSpots(rayMid);
p = localGetSpotPos(rayMid, nSpotsMid);
pts = localAppendPoint(pts, p);

% 5) last spot of first ray
nSpotsFirst = localGetNumSpots(rayFirst);
p = localGetSpotPos(rayFirst, nSpotsFirst);
pts = localAppendPoint(pts, p);

% Need at least 3 valid points to draw a polygon
if size(pts, 1) < 3
    warning('Beam %d does not have enough valid points for an arrow shape.', iBeam);
    return;
end

% Close polygon
ptsClosed = [pts; pts(1,:)];

hold(ax, 'on');

% Shaded fill
hOut.patch = patch(ax, ptsClosed(:,1), ptsClosed(:,2), edgeColor, ...
    'FaceAlpha', faceAlpha, ...
    'EdgeColor', 'none', ...
    'HandleVisibility', 'off');

% Outline
hOut.edge = plot(ax, ptsClosed(:,1), ptsClosed(:,2), '-', ...
    'Color', edgeColor, ...
    'LineWidth', 1.8, ...
    'HandleVisibility', 'off');

end

% -------------------------------------------------------------------------
function pts = localAppendPoint(pts, p)
% Append 2D point if valid
if ~isempty(p) && numel(p) >= 2 && all(isfinite(p(1:2)))
    pts = [pts; p(1:2)]; %#ok<AGROW>
end
end

% -------------------------------------------------------------------------
function nSpots = localGetNumSpots(ray)
% Estimate number of spots in a ray
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
function spot = localGetSpotPos(ray, iSpot)
% Get spot position from rayTracerInfo or spotsInfoGeo
spot = [];

if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot') ...
        && numel(ray.rayTracerInfo.perSpot) >= iSpot ...
        && isfield(ray.rayTracerInfo.perSpot(iSpot), 'spotCube')
    spot = ray.rayTracerInfo.perSpot(iSpot).spotCube;
    return;
end

if isfield(ray, 'spotsInfoGeo') && numel(ray.spotsInfoGeo) >= iSpot ...
        && isfield(ray.spotsInfoGeo(iSpot), 'spotCube')
    spot = ray.spotsInfoGeo(iSpot).spotCube;
    return;
end

% Fallbacks for alternate field naming, if needed
if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'spotCube') ...
        && size(ray.rayTracerInfo.spotCube, 1) >= iSpot
    spot = ray.rayTracerInfo.spotCube(iSpot, :);
    return;
end
end