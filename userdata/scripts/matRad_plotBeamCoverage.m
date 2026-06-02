function h = matRad_plotBeamCoverage(ax, stf, iBeamTarget)
% matRad_plotBeamCoverage - Visualize beam spot coverage as a shaded arrow
%
% Syntax:
%   h = matRad_plotBeamCoverage(ax, stf, iBeamTarget)
%
% Description:
%   Highlights the spot coverage area of a beam by:
%   1. Connecting 5 key spot positions into an arrow-shaped polygon:
%      - First spot of the first ray
%      - First spot of the middle ray
%      - All spots of the last ray
%      - Last spot of the middle ray
%      - Last spot of the first ray
%   2. Fills the polygon with a semi-transparent color
%   3. Outlines the polygon and marks vertices for clarity
%
%   Useful for quickly assessing the spatial extent and orientation
%   of a beam's spot distribution.
%
% Inputs:
%   ax          - Axes handle (use [] for gca)
%   stf         - Steering file structure (1 x nBeams)
%   iBeamTarget - Index of beam to visualize (1 <= iBeamTarget <= numel(stf))
%
% Outputs:
%   h - Graphics handle struct:
%       .patch  - Patch object (shaded area)
%       .line   - Outline line
%       .points - Vertex marker handles
%
% Reference entry:
% | — | `matRad_plotBeamCoverage` | Shaded arrow showing beam spot coverage | `h = matRad_plotBeamCoverage(ax, stf, iBeam)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

    % --- Input validation ---
    if nargin < 3 || isempty(iBeamTarget)
        iBeamTarget = 1;
    end
    if iBeamTarget < 1 || iBeamTarget > numel(stf)
        error('Invalid beam index: iBeamTarget must be between 1 and %d', numel(stf));
    end
    if nargin < 2 || isempty(stf)
        error('Missing required input: stf');
    end
    if nargin < 1 || isempty(ax)
        ax = gca;
    end

    beam = stf(iBeamTarget);
    hold(ax, 'on');

    % --- Helper to get spot position ---
    getSpotPos = @(ray, iSpot) getSpotPosition(ray, iSpot);

    % --- Get key rays ---
    nRays = beam.numOfRays;
    if nRays < 3
        warning('Beam %d has fewer than 3 rays — skipping coverage plot', iBeamTarget);
        h = struct('patch', [], 'line', [], 'points', []);
        return;
    end

    iFirst = 1;
    iMid   = round((nRays + 1) / 2);
    iLast  = nRays;

    rayFirst = beam.ray(iFirst);
    rayMid   = beam.ray(iMid);
    rayLast  = beam.ray(iLast);

    % --- Get key spots ---
    p1 = getSpotPos(rayFirst, 1);                      % First spot of first ray
    p2 = getSpotPos(rayMid,   1);                      % First spot of middle ray

    % All spots of last ray
    nSpotsLast = numel(rayLast.energy);
    p3_all = zeros(nSpotsLast, 2);
    for i = 1:nSpotsLast
        s = getSpotPos(rayLast, i);
        if isempty(s)
            p3_all(i,:) = NaN;
        else
            p3_all(i,:) = s(1:2);
        end
    end

    % Last spot of middle ray
    nSpotsMid = numel(rayMid.energy);
    p4 = getSpotPos(rayMid, nSpotsMid);

    % Last spot of first ray
    nSpotsFirst = numel(rayFirst.energy);
    p5 = getSpotPos(rayFirst, nSpotsFirst);

    % --- Concatenate all points in order ---
    points = [
        p1;
        p2;
        p3_all;
        p4;
        p5
    ];

    % Remove rows with NaN
    validRows = ~any(isnan(points), 2);
    points    = points(validRows, :);

    if size(points, 1) < 3
        warning('Not enough valid spot positions for beam %d — skipping coverage plot', iBeamTarget);
        h = struct('patch', [], 'line', [], 'points', []);
        return;
    end

    % --- Plot shaded polygon ---
    color = lines(1); % Use default color
    h.patch = patch(ax, points(:,1), points(:,2), color, ...
        'FaceAlpha', 0.2, ...
        'EdgeColor', 'none');

    % --- Outline polygon ---
    h.line = plot(ax, [points(:,1); points(1,1)], [points(:,2); points(1,2)], '-', ...
        'Color', color, 'LineWidth', 1.5);

    % --- Mark vertices ---
    h.points = plot(ax, points(:,1), points(:,2), 'ko', ...
        'MarkerFaceColor', 'k', 'MarkerSize', 5);

    title(ax, sprintf('Beam Coverage (Beam %d)', iBeamTarget), ...
        'Interpreter', 'none', 'FontSize', 12);

    % Return graphics handle
end

% -------------------------------------------------------------------------
function spot = getSpotPosition(ray, iSpot)
% Internal helper to fetch spot cube from either tracer or geo info
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
end