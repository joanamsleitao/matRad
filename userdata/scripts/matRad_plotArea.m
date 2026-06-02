function hOut = matRad_plotArea(ax, stf, beamNames, colorMode, alphaMode)
% matRad_plotArea - Plot an arrow-like shaded footprint per beam using
%                   selected boundary spots, with visible representative
%                   spots and an open dashed outline.
%
% Syntax:
%   hOut = matRad_plotArea(ax, stf)
%   hOut = matRad_plotArea(ax, stf, beamNames)
%   hOut = matRad_plotArea(ax, stf, beamNames, colorMode, alphaMode)
%
% Description:
%   For each beam, builds a footprint polygon using:
%     - first spot of first ray
%     - first spot of middle ray
%     - all spots of last ray
%     - last spot of middle ray
%     - last spot of first ray
%
%   The interior is shaded with transparent alpha.
%   The outline is drawn as an open dashed line, so the first and last spot
%   of the first ray are not connected by the line.
%   The key spots remain visible on top of the shaded area.
%
% Inputs:
%   ax        - Target axes handle. If empty, uses gca.
%   stf       - matRad steering file struct array
%   beamNames - (optional) cell array of beam labels
%   colorMode - (optional) 'lines' (default) or 'gray'
%   alphaMode - (optional) 'vary' (default) or 'fixed'
%
% Outputs:
%   hOut - struct with fields:
%          .patch   - patch handles, one per beam
%          .edge    - outline line handles, one per beam
%          .markers - marker handles, one per beam
%
% Reference entry:
% | Previous Name | Current Name | Description | Call | Status |
% | --- | --- | --- | --- | --- |
% | — | `matRad_plotArea` | Plot shaded beam footprint with visible boundary spots and open dashed outline | `hOut = matRad_plotArea(ax, stf)` | 🟢 |
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
if nargin < 4 || isempty(colorMode)
    colorMode = 'lines';
end
if nargin < 5 || isempty(alphaMode)
    alphaMode = 'vary';
end

nBeams = numel(stf);
hold(ax, 'on');

% --- Colors ---
switch lower(colorMode)
    case 'gray'
        cmap = gray(max(nBeams, 2));
        cmap = cmap(round(linspace(1, size(cmap,1), nBeams)), :);
    otherwise
        cmap = lines(max(nBeams, 2));
        cmap = cmap(round(linspace(1, size(cmap,1), nBeams)), :);
end

% --- Alpha values ---
switch lower(alphaMode)
    case 'fixed'
        alphaVals = 0.18 * ones(nBeams, 1);
    otherwise
        alphaVals = linspace(0.10, 0.28, nBeams).';
end

hOut = struct();
hOut.patch   = gobjects(nBeams, 1);
hOut.edge    = gobjects(nBeams, 1);
hOut.markers = gobjects(nBeams, 1);

for iBeam = 1:nBeams
    beam = stf(iBeam);

    if ~isfield(beam, 'numOfRays') || isempty(beam.numOfRays) || beam.numOfRays < 1
        continue;
    end

    nRays = beam.numOfRays;
    iFirst = 1;
    iMid   = round((nRays + 1) / 2);
    iLast  = nRays;

    rayFirst = beam.ray(iFirst);
    rayMid   = beam.ray(iMid);
    rayLast  = beam.ray(iLast);

    c = cmap(iBeam, :);
    a = alphaVals(iBeam);

    % ------------------------------------------------------------
    % Collect points in the requested order
    % ------------------------------------------------------------
    pts = [];
    ptType = {};   % 'first', 'mid', 'last' for marker styling

    % 1) first spot of first ray
    [p, ok] = localGetSpotPos(rayFirst, 1);
    if ok
        pts(end+1, :) = p(1:2); %#ok<AGROW>
        ptType{end+1} = 'first'; %#ok<AGROW>
    end

    % 2) first spot of middle ray
    [p, ok] = localGetSpotPos(rayMid, 1);
    if ok
        pts(end+1, :) = p(1:2); %#ok<AGROW>
        ptType{end+1} = 'mid'; %#ok<AGROW>
    end

    % 3) all spots of last ray
    nSpotsLast = localGetNumSpots(rayLast);
    for iSpot = 1:nSpotsLast
        [p, ok] = localGetSpotPos(rayLast, iSpot);
        if ok
            pts(end+1, :) = p(1:2); %#ok<AGROW>
            ptType{end+1} = 'last'; %#ok<AGROW>
        end
    end

    % 4) last spot of middle ray
    nSpotsMid = localGetNumSpots(rayMid);
    [p, ok] = localGetSpotPos(rayMid, nSpotsMid);
    if ok
        pts(end+1, :) = p(1:2); %#ok<AGROW>
        ptType{end+1} = 'mid'; %#ok<AGROW>
    end

    % 5) last spot of first ray
    nSpotsFirst = localGetNumSpots(rayFirst);
    [p, ok] = localGetSpotPos(rayFirst, nSpotsFirst);
    if ok
        pts(end+1, :) = p(1:2); %#ok<AGROW>
        ptType{end+1} = 'first'; %#ok<AGROW>
    end

    if size(pts, 1) < 3
        continue;
    end

    % ------------------------------------------------------------
    % Shaded area: closed polygon for fill
    % ------------------------------------------------------------
    ptsClosed = [pts; pts(1,:)];

    hOut.patch(iBeam) = patch(ax, ptsClosed(:,1), ptsClosed(:,2), c, ...
        'FaceAlpha', a, ...
        'EdgeColor', 'none', ...
        'HandleVisibility', 'off');

    % ------------------------------------------------------------
    % Open dashed outline: do NOT close the line
    % ------------------------------------------------------------
    hOut.edge(iBeam) = plot(ax, pts(:,1), pts(:,2), '--', ...
        'Color', c, ...
        'LineWidth', 0.9, ...
        'HandleVisibility', 'off');

    % ------------------------------------------------------------
    % Visible representative spots on top
    % ------------------------------------------------------------
    % Plot markers for each selected point, using the ray position as shape
    hMark = gobjects(numel(ptType), 1);

    for k = 1:numel(ptType)
        switch ptType{k}
            case 'first'
                mk = 'o';
            case 'mid'
                mk = 's';
            case 'last'
                mk = '^';
            otherwise
                mk = 'o';
        end

        hMark(k) = plot(ax, pts(k,1), pts(k,2), mk, ...
            'MarkerSize', 6, ...
            'MarkerEdgeColor', c, ...
            'MarkerFaceColor', 'w', ...
            'LineWidth', 1.1, ...
            'HandleVisibility', 'off');
    end

    hOut.markers(iBeam) = hMark(find(isgraphics(hMark), 1, 'first'));

    % Optional label
    if ~isempty(beamNames) && numel(beamNames) >= iBeam && ~isempty(beamNames{iBeam})
        ctr = mean(pts, 1, 'omitnan');
        text(ax, ctr(1), ctr(2), beamNames{iBeam}, ...
            'Color', c, ...
            'FontSize', 9, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'Interpreter', 'none');
    end
end

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
    ok   = true;
    return;
end

if isfield(ray, 'spotsInfoGeo') && numel(ray.spotsInfoGeo) >= iSpot ...
        && isfield(ray.spotsInfoGeo(iSpot), 'spotCube')
    spot = ray.spotsInfoGeo(iSpot).spotCube;
    ok   = true;
    return;
end
end