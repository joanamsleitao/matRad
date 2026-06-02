function hFig = matRad_spotsBeamSortELperVOI(ct, cst, stf, ixVOI, ixBeam, doseCube, targetSlice, zoomFactor)
% matRad_spotsBeamSortELperVOI - Plot only one beam's spots that lie inside a VOI,
%                                sorted by energy layer
%
% Syntax:
%   hFig = matRad_spotsBeamSortELperVOI(ct, cst, stf, ixVOI, ixBeam)
%   hFig = matRad_spotsBeamSortELperVOI(ct, cst, stf, ixVOI, ixBeam, doseCube)
%   hFig = matRad_spotsBeamSortELperVOI(ct, cst, stf, ixVOI, ixBeam, doseCube, targetSlice)
%   hFig = matRad_spotsBeamSortELperVOI(ct, cst, stf, ixVOI, ixBeam, doseCube, targetSlice, zoomFactor)
%
% Description:
%   Creates a single figure showing the CT/CST background for one selected
%   slice and overlays only the spots from one selected beam whose voxel
%   positions fall inside the specified VOI.
%
%   A spot is kept only if:
%       1) its rounded voxel coordinate lies inside ixVOI, and
%       2) its z-index matches the displayed slice.
%
%   Spots are plotted color-coded by energy layer using the same sorting
%   convention as matRad_plotSpotsBeamSortE.
%
% Inputs:
%   ct          - matRad CT structure
%   cst         - matRad CST cell array
%   stf         - matRad steering file structure array
%   ixVOI       - Linear voxel indices of the VOI region
%   ixBeam      - Beam index to display
%   doseCube    - (optional) dose cube to overlay
%   targetSlice - (optional) slice index to display; if empty, the beam
%                 isocenter slice is used
%   zoomFactor  - (optional) zoom factor for the CT display window
%
% Outputs:
%   hFig - Figure handle
%
% Reference entry:
% | `N/A` | `matRad_spotsBeamSortELperVOI` | Plot one beam's spots inside a VOI, sorted by energy layer | `hFig = matRad_spotsBeamSortELperVOI(ct, cst, stf, ixInterface, ixBeam, doseCube)` | 🟢 |
%
% ----
% Author: Joana Leitão
% ----

if nargin < 6 || isempty(doseCube)
    doseCube = [];
end

if nargin < 7
    targetSlice = [];
end

if nargin < 8 || isempty(zoomFactor)
    zoomFactor = 0.85;
end

if isempty(stf) || ~isstruct(stf)
    error('matRad_spotsBeamSortELperVOI:InvalidSTF', ...
        'stf must be a non-empty struct array.');
end

if nargin < 5 || isempty(ixBeam) || ~isscalar(ixBeam) || ixBeam < 1 || ixBeam > numel(stf)
    error('matRad_spotsBeamSortELperVOI:InvalidBeamIndex', ...
        'ixBeam must be a valid beam index between 1 and numel(stf).');
end

if isempty(ixVOI)
    warning('matRad_spotsBeamSortELperVOI:EmptyVOI', ...
        'ixVOI is empty. No VOI filtering will be applied.');
end

ctSize = size(ct.cubeHU);

% Build a logical VOI mask for fast membership testing
voiMask = false(ctSize);
if ~isempty(ixVOI)
    ixVOI = ixVOI(:);
    ixVOI = ixVOI(ixVOI >= 1 & ixVOI <= numel(voiMask));
    voiMask(ixVOI) = true;
end

stfBeam = stf(ixBeam);

% Determine beam isocenter slice
isoSlice = [];
if isfield(stfBeam, 'isoCenter') && ~isempty(stfBeam.isoCenter)
    isoCube = matRad_world2cubeCoords(stfBeam.isoCenter, ct);
    isoSlice = round(isoCube(3));
elseif isfield(cst, 'cst') %#ok<NASGU>
    % fallback not used; kept for compatibility with different setups
    isoSlice = [];
end

if isempty(targetSlice)
    if isempty(isoSlice)
        targetSlice = round(ctSize(3) / 2);
    else
        targetSlice = isoSlice;
    end
end

hFig = figure( ...
    'Color', 'w', ...
    'Units', 'normalized', ...
    'OuterPosition', [0 0 1 1]);

ax = axes('Parent', hFig);
axes(ax);
hold(ax, 'on');

% Background slice
matRad_showSliceFast(ct, cst, doseCube, targetSlice, [], 1, zoomFactor);
hold(ax, 'on');

% Collect only spots that are inside the VOI and in the selected slice
xAll = [];
yAll = [];
eAll = [];
rayAll = [];
spotAll = [];

if ~isfield(stfBeam, 'ray') || isempty(stfBeam.ray)
    warning('matRad_spotsBeamSortELperVOI:NoRays', ...
        'Beam %d contains no rays.', ixBeam);
    title(ax, sprintf('Beam %d - no rays', ixBeam), 'Interpreter', 'none');
    legend(ax, 'off');
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

        % matRad convention here: spotCube = [x, y, z]
        spotVox = round(spotCube);

        % Bounds check
        if any(spotVox < 1) || ...
                spotVox(1) > ctSize(1) || spotVox(2) > ctSize(2) || spotVox(3) > ctSize(3)
            continue;
        end

        % Keep only spots in the selected slice
        if round(spotVox(3)) ~= targetSlice
            continue;
        end

        % Keep only spots inside the VOI
        spotLin = sub2ind(ctSize, spotVox(1), spotVox(2), spotVox(3));
        if ~isempty(ixVOI) && ~voiMask(spotLin)
            continue;
        end

        xAll(end+1,1) = spotCube(1); %#ok<AGROW>
        yAll(end+1,1) = spotCube(2); %#ok<AGROW>
        eAll(end+1,1) = spotEnergy;  %#ok<AGROW>
        rayAll(end+1,1) = iRay;       %#ok<AGROW>
        spotAll(end+1,1) = iSpot;     %#ok<AGROW>
    end
end

if isempty(xAll)
    warning('matRad_spotsBeamSortELperVOI:NoSpotsFound', ...
        'No spots from beam %d were found inside the VOI in slice %d.', ixBeam, targetSlice);

    if ~isempty(isoSlice) && targetSlice == isoSlice
        title(ax, sprintf('Beam %d | slice %d (isocenter) | no VOI spots found', ...
            ixBeam, targetSlice), 'Interpreter', 'none');
    else
        title(ax, sprintf('Beam %d | slice %d | no VOI spots found', ...
            ixBeam, targetSlice), 'Interpreter', 'none');
    end

    legend(ax, 'off');
    box(ax, 'on');
    axis(ax, 'equal');
    axis(ax, 'tight');
    return;
end

% Plot by energy layer
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

    % Stable order before connecting
    [~, ord] = sortrows([r, s], [1 2]);
    x = x(ord);
    y = y(ord);

    if numel(x) > 1
        plot(ax, x, y, '--', ...
            'Color', col, ...
            'LineWidth', 0.7, ...
            'HandleVisibility', 'off');
    end

    hLayer(iE) = plot(ax, x, y, ...
        'LineStyle', 'none', ...
        'Marker', mk, ...
        'MarkerSize', 6, ...
        'MarkerEdgeColor', col, ...
        'MarkerFaceColor', col, ...
        'Color', col, ...
        'DisplayName', sprintf('E = %g MeV', uniqueE(iE)));
end

% Axis formatting
set(ax, 'Color', 'none');
set(ax, 'Layer', 'top');
set(ax, 'Box', 'on');
grid(ax, 'on');
axis(ax, 'equal');
axis(ax, 'tight');

% Optional zoom around beam/isocenter region
if ~isempty(zoomFactor)
    if ~isempty(isoSlice) && isfield(stfBeam, 'isoCenter') && ~isempty(stfBeam.isoCenter)
        isoCube = matRad_world2cubeCoords(stfBeam.isoCenter, ct);
        isoCenterIx = round(isoCube);
        [xlimVals, ylimVals] = matRad_getZoomWindow(isoCenterIx(2), isoCenterIx(1), ct, zoomFactor);
        if xlimVals(1) ~= xlimVals(2) && ylimVals(1) ~= ylimVals(2)
            set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
        end
    end
end

if ~isempty(isoSlice) && targetSlice == isoSlice
    title(ax, sprintf('Beam %d | slice %d (isocenter) | VOI spots only', ixBeam, targetSlice), ...
        'Interpreter', 'none');
else
    title(ax, sprintf('Beam %d | slice %d | VOI spots only', ixBeam, targetSlice), ...
        'Interpreter', 'none');
end

xlabel(ax, 'x');
ylabel(ax, 'y');
legend(ax, hLayer, 'Location', 'eastoutside', 'Interpreter', 'none');

end