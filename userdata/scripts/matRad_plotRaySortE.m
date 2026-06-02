function hAx = matRad_plotRaySortE(ax, rayOrBeam, isoCenterCube)
% matRad_plotRaySortE - Plot spots by energy layer, color/shape coded, and connected
%
% Syntax:
%   hAx = matRad_plotRaySortE(ax, rayOrBeam, isoCenterCube)
%
% Description:
%   Plots all spots belonging to one ray or one beam in the XY plane.
%   Spots are grouped by energy layer, color-coded with a fixed categorical
%   palette, and assigned different marker shapes to improve readability.
%
%   Spots belonging to the same energy layer are connected with a dashed
%   line. Spots that lie in the same slice as the isocenter are highlighted
%   with a black outline marker.
%
%   The legend explains the energy layer colors and the isocenter-slice
%   marker.
%
% Inputs:
%   ax            - Axes handle to plot into
%   rayOrBeam     - Either a single ray struct or a beam struct containing
%                   rayOrBeam.ray
%   isoCenterCube - (optional) Isocenter in cube coordinates. Can be either
%                   a 3-element vector [x y z] or a scalar z-slice index.
%
% Output:
%   hAx - Axes handle
%
% Reference entry:
% | `matRad_plotRaySortZ` | `matRad_plotRaySortE` | Plot ray spots sorted by energy layer, color/shape coded, with iso-slice marker | `[hAx] = matRad_plotRaySortE(ax, rayOrBeam, isoCenterCube)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão / OpenAI
% -------------------------------------------------------------------------

if nargin < 1 || isempty(ax)
    figure;
    ax = axes;
end
if nargin < 3
    isoCenterCube = [];
end

hold(ax, 'on');

% Accept either a beam struct or a single ray struct / ray array
if isstruct(rayOrBeam) && isfield(rayOrBeam, 'ray')
    rays = rayOrBeam.ray;
else
    rays = rayOrBeam;
end

if isempty(rays)
    hAx = ax;
    return;
end

% Determine isocenter slice
isoSlice = [];
if ~isempty(isoCenterCube)
    if numel(isoCenterCube) >= 3
        isoSlice = round(isoCenterCube(3));
    else
        isoSlice = round(isoCenterCube(1));
    end
end

% Collect all spots
allX = [];
allY = [];
allZ = [];
allE = [];
allRayIdx = [];
allSpotIdx = [];

for iRay = 1:numel(rays)
    ray = rays(iRay);
    spots = local_getRaySpots(ray);

    if isempty(spots)
        continue;
    end

    for iSpot = 1:numel(spots)
        if ~isfield(spots(iSpot), 'energy') || isempty(spots(iSpot).energy)
            continue;
        end

        if isfield(spots(iSpot), 'spotCube') && numel(spots(iSpot).spotCube) >= 3
            p = spots(iSpot).spotCube(:).';
        elseif isfield(spots(iSpot), 'spotWorld') && numel(spots(iSpot).spotWorld) >= 3
            p = spots(iSpot).spotWorld(:).';
        else
            continue;
        end

        allX(end+1,1) = p(1); %#ok<AGROW>
        allY(end+1,1) = p(2); %#ok<AGROW>
        allZ(end+1,1) = p(3); %#ok<AGROW>
        allE(end+1,1) = spots(iSpot).energy; %#ok<AGROW>
        allRayIdx(end+1,1) = iRay; %#ok<AGROW>
        allSpotIdx(end+1,1) = iSpot; %#ok<AGROW>
    end
end

if isempty(allE)
    warning('matRad_plotRaySortE:NoSpots', ...
        'No valid spots with energy information found.');
    hAx = ax;
    return;
end

% Unique energies sorted ascending
uniqueE = unique(allE, 'sorted');
nE = numel(uniqueE);

% Fixed categorical palette: cleaner than a continuous colormap for many ELs
palette = [ ...
    0.0000 0.4470 0.7410;  % blue
    0.8500 0.3250 0.0980;  % orange
    0.9290 0.6940 0.1250;  % yellow
    0.4940 0.1840 0.5560;  % purple
    0.4660 0.6740 0.1880;  % green
    0.3010 0.7450 0.9330;  % cyan
    0.6350 0.0780 0.1840;  % dark red
    0.2000 0.2000 0.2000;  % dark gray
    0.8000 0.4000 0.7000;  % pinkish
    0.1000 0.6000 0.6000]; % teal

markerList = {'o','s','^','d','v','>','<','p','h','x'};
nPalette = size(palette, 1);
nMarkers = numel(markerList);

hLayer = gobjects(nE, 1);

for iE = 1:nE
    idx = (allE == uniqueE(iE));
    if ~any(idx)
        continue;
    end

    % Sort by ray and spot index to make the connection reproducible
    sortMat = [allRayIdx(idx), allSpotIdx(idx)];
    [~, ord] = sortrows(sortMat);

    x = allX(idx);
    y = allY(idx);
    z = allZ(idx);

    x = x(ord);
    y = y(ord);
    z = z(ord);

    col = palette(mod(iE-1, nPalette) + 1, :);
    mk  = markerList{mod(iE-1, nMarkers) + 1};

    % Dashed connection line for the layer
    if numel(x) > 1
        plot(ax, x, y, '--', ...
            'Color', col, ...
            'LineWidth', 1.0, ...
            'HandleVisibility', 'off');
    end

    % Main markers
    hLayer(iE) = plot(ax, x, y, ...
        'LineStyle', 'none', ...
        'Marker', mk, ...
        'MarkerSize', 6, ...
        'MarkerEdgeColor', col, ...
        'MarkerFaceColor', col, ...
        'Color', col, ...
        'DisplayName', sprintf('E = %g', uniqueE(iE)));

    % Highlight spots in the same slice as the isocenter
    if ~isempty(isoSlice)
        isoMask = (round(z) == isoSlice);
        if any(isoMask)
            plot(ax, x(isoMask), y(isoMask), ...
                'LineStyle', 'none', ...
                'Marker', mk, ...
                'MarkerSize', 9, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', 'none', ...
                'LineWidth', 1.2, ...
                'HandleVisibility', 'off');
        end
    end
end

xlabel(ax, 'x');
ylabel(ax, 'y');
grid(ax, 'on');
box(ax, 'on');

% Legend
if ~isempty(isoSlice)
    hIso = plot(ax, nan, nan, 'ko', ...
        'MarkerSize', 7, ...
        'MarkerFaceColor', 'none', ...
        'LineWidth', 1.2, ...
        'DisplayName', 'spot in isocenter slice');
    legend(ax, [hLayer(isgraphics(hLayer)); hIso], ...
        'Location', 'eastoutside', ...
        'Interpreter', 'none');
else
    legend(ax, hLayer(isgraphics(hLayer)), ...
        'Location', 'eastoutside', ...
        'Interpreter', 'none');
end

hAx = ax;
end

% -------------------------------------------------------------------------
function spots = local_getRaySpots(ray)
% local_getRaySpots - Get per-spot info from a ray struct
%
% Prefers ray.rayTracerInfo.perSpot if available.

spots = [];

if isstruct(ray) && isfield(ray, 'rayTracerInfo') && ...
        isfield(ray.rayTracerInfo, 'perSpot') && ~isempty(ray.rayTracerInfo.perSpot)
    spots = ray.rayTracerInfo.perSpot;
end
end