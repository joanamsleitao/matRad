function hAx = matRad_plotSliceSpots(ax, ct, cst, stfBeam, targetSlice, doseCube)
% matRad_plotSliceSpots - Plot spots in one selected slice for one beam, color-coded by energy
%
% Syntax:
%   hAx = matRad_plotSliceSpots(ax, ct, cst, stfBeam)
%   hAx = matRad_plotSliceSpots(ax, ct, cst, stfBeam, targetSlice)
%   hAx = matRad_plotSliceSpots(ax, ct, cst, stfBeam, targetSlice, doseCube)
%
% Description:
%   Plots only the spots from one beam that lie in a selected CT slice.
%   Spots are grouped by energy layer and colored with a fixed categorical
%   palette. Marker shapes are cycled to improve distinguishability when
%   many energy layers are present.
%
%   By default, the selected slice is the beam isocenter slice.
%   The selected slice is plotted on top of a CT/CST background.
%
%   This function expects spot positions to be available in:
%       ray.rayTracerInfo.perSpot(iSpot).spotCube
%
%   In that convention, spotCube is expected to be ordered as:
%       [x, y, z] = [col, row, slice]
%
% Inputs:
%   ax          - axes handle to plot into
%   ct          - matRad CT struct
%   cst         - matRad CST struct
%   stfBeam     - one beam struct, e.g. stf(iBeam)
%   targetSlice - (optional) slice index to display. If omitted or empty,
%                 the beam's isocenter slice is used.
%   doseCube    - (optional) dose cube to overlay in the background
%
% Output:
%   hAx - axes handle
%
% Reference entry:
% | `matRad_plotSliceSpots` | `matRad_plotSliceSpots` | Plot spots in one slice for one beam, color-coded by energy | `[hAx] = matRad_plotSliceSpots(gca, ct, cst, stf(iBeam))` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 1 || isempty(ax)
    figure('Color', 'w');
    ax = axes;
end

if nargin < 6
    doseCube = [];
end

if isempty(stfBeam) || ~isstruct(stfBeam)
    error('matRad_plotSliceSpots:InvalidBeamInput', ...
        'stfBeam must be one beam struct, e.g. stf(iBeam).');
end

if ~isfield(stfBeam, 'isoCenter') || isempty(stfBeam.isoCenter)
    error('matRad_plotSliceSpots:MissingIsoCenter', ...
        'stfBeam.isoCenter is missing.');
end

hold(ax, 'on');
axes(ax);

% -------------------------------------------------------------------------
% Determine isocenter slice
% -------------------------------------------------------------------------
isoCube = matRad_world2cubeCoords(stfBeam.isoCenter, ct);
isoSlice = round(isoCube(3));

if nargin < 5 || isempty(targetSlice)
    targetSlice = isoSlice;
end

% -------------------------------------------------------------------------
% Draw background
% -------------------------------------------------------------------------
if isempty(doseCube)
    matRad_showSliceFast(ct, cst, []);
else
    matRad_showSliceFast(ct, cst, doseCube);
end
hold(ax, 'on');

% -------------------------------------------------------------------------
% Collect spots in the selected slice
% -------------------------------------------------------------------------
xAll = [];
yAll = [];
eAll = [];

if ~isfield(stfBeam, 'ray') || isempty(stfBeam.ray)
    warning('matRad_plotSliceSpots:NoRays', ...
        'The provided beam contains no rays.');
    title(ax, 'No rays in beam', 'Interpreter', 'none');
    axis(ax, 'equal');
    axis(ax, 'tight');
    box(ax, 'on');
    legend(ax, 'off');
    hAx = ax;
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

        if round(spotCube(3)) ~= targetSlice
            continue;
        end

        xAll(end+1,1) = spotCube(1); %#ok<AGROW>
        yAll(end+1,1) = spotCube(2); %#ok<AGROW>
        eAll(end+1,1) = spotEnergy; %#ok<AGROW>
    end
end

if isempty(xAll)
    warning('matRad_plotSliceSpots:NoSpotsFound', ...
        'No spots found in slice %d for this beam.', targetSlice);

    if targetSlice == isoSlice
        title(ax, sprintf('Beam spots in slice %d (isocenter slice) - no spots found', targetSlice), ...
            'Interpreter', 'none');
    else
        title(ax, sprintf('Beam spots in slice %d - no spots found', targetSlice), ...
            'Interpreter', 'none');
    end

    axis(ax, 'equal');
    axis(ax, 'tight');
    box(ax, 'on');
    legend(ax, 'off');
    hAx = ax;
    return;
end

% -------------------------------------------------------------------------
% Plot by energy layer
% -------------------------------------------------------------------------
uniqueE = unique(eAll, 'sorted');
nE = numel(uniqueE);

% Fixed categorical palette: easier to read than a continuous colormap
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

    hLayer(iE) = scatter(ax, xAll(idx), yAll(idx), 34, ...
        'filled', ...
        'Marker', mk, ...
        'MarkerFaceColor', col, ...
        'MarkerEdgeColor', col, ...
        'DisplayName', sprintf('E = %g', uniqueE(iE)));
end

% -------------------------------------------------------------------------
% Indication for isocenter slice
% -------------------------------------------------------------------------
if targetSlice == isoSlice
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
axis(ax, 'equal');
axis(ax, 'tight');
grid(ax, 'on');
box(ax, 'on');

% Small padding around points
xRange = max(xAll) - min(xAll);
yRange = max(yAll) - min(yAll);
pad = max([5, round(0.05 * max(xRange, yRange))]);

xlim(ax, [min(xAll)-pad, max(xAll)+pad]);
ylim(ax, [min(yAll)-pad, max(yAll)+pad]);

if targetSlice == isoSlice
    title(ax, sprintf('Beam spots in slice %d (isocenter slice)', targetSlice), ...
        'Interpreter', 'none');
else
    title(ax, sprintf('Beam spots in slice %d', targetSlice), ...
        'Interpreter', 'none');
end

legend(ax, hLayer, 'Location', 'eastoutside', 'Interpreter', 'none');

hAx = ax;
end