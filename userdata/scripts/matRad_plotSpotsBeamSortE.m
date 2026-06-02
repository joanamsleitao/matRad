function [hAx, hLayer] = matRad_plotSpotsBeamSortE(ax, stfBeam, sliceShown, ct)
% matRad_plotSpotsBeamSortE - Overlay spots in one selected slice for one beam,
%                             color-coded by energy and connected with dashed lines
%
% Syntax:
%   [hAx, hLayer] = matRad_plotSpotsBeamSortE(ax, stfBeam, sliceShown)
%   [hAx, hLayer] = matRad_plotSpotsBeamSortE(ax, stfBeam, sliceShown, ct)
%
% Description:
%   Plots only the spots from one beam that lie in the selected slice.
%   Spots are grouped by energy layer, color-coded with a fixed categorical
%   palette, assigned different marker shapes, and connected with thin
%   dashed lines per energy layer.
%
%   This function is intended as an overlay on an already plotted slice
%   (for example from matRad_showSliceFast). It does NOT draw CT/CST.
%
%   If ct is provided, the beam isocenter slice is used only for annotation.
%
% Inputs:
%   ax         - axes handle to plot into
%   stfBeam    - one beam struct, e.g. stf(iBeam)
%   sliceShown - slice index shown in the background
%   ct         - (optional) matRad CT struct, only used to determine the
%                beam isocenter slice for annotation
%
% Outputs:
%   hAx    - axes handle
%   hLayer - handles to the plotted energy-layer objects
%
% Reference entry:
% | `matRad_plotSpotsBeamSortE` | `matRad_plotSpotsBeamSortE` | Overlay spots in one slice for one beam, energy-colored, dashed connections | `[hAx] = matRad_plotSpotsBeamSortE(ax, stf(iBeam), sliceShown, ct)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 1 || isempty(ax)
    figure('Color', 'w');
    ax = axes;
end

if nargin < 4
    ct = [];
end

if isempty(stfBeam) || ~isstruct(stfBeam)
    error('matRad_plotSpotsBeamSortE:InvalidBeamInput', ...
        'stfBeam must be one beam struct, e.g. stf(iBeam).');
end

if nargin < 3 || isempty(sliceShown)
    error('matRad_plotSpotsBeamSortE:MissingSlice', ...
        'A sliceShown value must be provided.');
end

hold(ax, 'on');

% -------------------------------------------------------------------------
% Determine beam isocenter slice if ct is available
% -------------------------------------------------------------------------
isoSlice = [];
if ~isempty(ct) && isfield(stfBeam, 'isoCenter') && ~isempty(stfBeam.isoCenter)
    isoCube = matRad_world2cubeCoords(stfBeam.isoCenter, ct);
    isoSlice = round(isoCube(3));
end

% -------------------------------------------------------------------------
% Collect spots in the selected slice
% -------------------------------------------------------------------------
xAll = [];
yAll = [];
eAll = [];
rayAll = [];
spotAll = [];

if ~isfield(stfBeam, 'ray') || isempty(stfBeam.ray)
    warning('matRad_plotSpotsBeamSortE:NoRays', ...
        'The provided beam contains no rays.');
    hAx = ax;
    hLayer = gobjects(0);
    return;
end

for iRay = 1:numel(stfBeam.ray)
    ray = stfBeam.ray(iRay);

    if ~isfield(ray, 'rayTracerInfo') || ...
            ~isfield(ray.rayTracerInfo, 'perSpot') || ...
            isempty(ray.rayTracerInfo.perSpot)
        continue;
    end

    spots = ray.rayTracerInfo.perSpot;

    for iSpot = 1:numel(spots)
        if ~isfield(spots(iSpot), 'spotCube') || numel(spots(iSpot).spotCube) < 3
            continue;
        end
        if ~isfield(spots(iSpot), 'energy') || isempty(spots(iSpot).energy)
            continue;
        end

        spotCube = spots(iSpot).spotCube(:).';
        spotEnergy = spots(iSpot).energy;

        if round(spotCube(3)) ~= sliceShown
            continue;
        end

        xAll(end+1,1) = spotCube(1); %#ok<AGROW>
        yAll(end+1,1) = spotCube(2); %#ok<AGROW>
        eAll(end+1,1) = spotEnergy; %#ok<AGROW>
        rayAll(end+1,1) = iRay; %#ok<AGROW>
        spotAll(end+1,1) = iSpot; %#ok<AGROW>
    end
end

if isempty(xAll)
    warning('matRad_plotSpotsBeamSortE:NoSpotsFound', ...
        'No spots found in slice %d for this beam.', sliceShown);
    hAx = ax;
    hLayer = gobjects(0);
    return;
end

% -------------------------------------------------------------------------
% Plot by energy layer
% -------------------------------------------------------------------------
uniqueE = unique(eAll, 'sorted');
nE = numel(uniqueE);

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
    idx = (eAll == uniqueE(iE));

    col = palette(mod(iE-1, nPalette) + 1, :);
    mk  = markerList{mod(iE-1, nMarkers) + 1};

    x = xAll(idx);
    y = yAll(idx);
    r = rayAll(idx);
    s = spotAll(idx);

    % Stable order before connecting them
    [~, ord] = sortrows([r, s], [1 2]);
    x = x(ord);
    y = y(ord);

    % Thin dashed connection line for this energy layer
    if numel(x) > 1
        plot(ax, x, y, '--', ...
            'Color', col, ...
            'LineWidth', 0.7, ...
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
        'DisplayName', sprintf('E = %g MeV', uniqueE(iE)));
end

% -------------------------------------------------------------------------
% Isocenter annotation
% -------------------------------------------------------------------------
if ~isempty(isoSlice) && sliceShown == isoSlice
    text(ax, 0.02, 0.98, 'isocenter slice', ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'FontWeight', 'bold', ...
        'Color', [0.85 0.10 0.10], ...
        'BackgroundColor', 'w', ...
        'Margin', 2);
end

xlabel(ax, 'x');
ylabel(ax, 'y');
grid(ax, 'on');
box(ax, 'on');

title(ax, sprintf('Beam spots in slice %d', sliceShown), ...
    'Interpreter', 'none');

if ~isempty(isoSlice) && sliceShown == isoSlice
    title(ax, sprintf('Beam spots in slice %d (isocenter slice)', sliceShown), ...
        'Interpreter', 'none');
end

legend(ax, hLayer, 'Location', 'eastoutside', 'Interpreter', 'none');

hAx = ax;
end