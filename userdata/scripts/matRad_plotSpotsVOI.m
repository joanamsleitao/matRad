function [rayTbl, spotTblAll, voiTbl, spotTblVOI, hLayer] = matRad_plotSpotsVOI(ax, ct, cst, stf, ixVOI, ixBeam, sliceShown, zoomFactor, saveMatFile)
% matRad_plotSpotsVOI - Plot only the spots from one beam that lie inside a VOI,
%                       and return tables for rays, all spots, VOI voxels,
%                       and filtered VOI spots
%
% Syntax:
%   [rayTbl, spotTblAll, voiTbl, spotTblVOI] = matRad_plotSpotsVOI(ax, ct, cst, stf, ixVOI, ixBeam, sliceShown)
%   [rayTbl, spotTblAll, voiTbl, spotTblVOI] = matRad_plotSpotsVOI(ax, ct, cst, stf, ixVOI, ixBeam, sliceShown, zoomFactor)
%   [rayTbl, spotTblAll, voiTbl, spotTblVOI] = matRad_plotSpotsVOI(ax, ct, cst, stf, ixVOI, ixBeam, sliceShown, zoomFactor, saveMatFile)
%
% Description:
%   This function:
%     1) Extracts all rays/spots from one selected beam.
%     2) Converts the VOI linear voxel indices from cst{ixVOI,4}{1} into cube
%        coordinates using matRad_lin2cubeCoords.
%     3) Compares spotCube coordinates directly against the VOI cube coordinates.
%     4) Overlays only the VOI spots in the chosen slice on an already plotted
%        background axis.
%
%   IMPORTANT:
%   - ixVOI is the row index in cst.
%   - cst{ixVOI,4}{1} contains the VOI voxels as linear indices.
%   - spotCube is assumed to already be in cube coordinates.
%   - This function does NOT create a figure. It plots into the axes passed
%     in ax, so call matRad_showSliceFast outside first.
%
% Inputs:
%   ax          - axes handle to plot into
%   ct          - matRad CT structure
%   cst         - matRad CST cell array
%   stf         - matRad steering file structure array
%   ixVOI       - row index in cst of the VOI to use
%   ixBeam      - beam index to process
%   sliceShown  - slice currently displayed in the background
%   zoomFactor  - (optional) zoom factor for the background display
%   saveMatFile - (optional) .mat filename to save the tables
%
% Outputs:
%   rayTbl      - Ray summary table for the selected beam
%   spotTblAll  - Detailed spot table for all spots of the selected beam
%   voiTbl      - Table of VOI voxels from cst{ixVOI,4}{1}
%   spotTblVOI  - Spot table filtered to spots inside the VOI
%   hLayer      - Handles of the plotted energy-layer objects
%
% Reference entry:
% | `N/A` | `matRad_plotSpotsVOI` | Plot one beam's spots inside a specified VOI and return ray/spot tables | `[rayTbl, spotTblAll, voiTbl, spotTblVOI] = matRad_plotSpotsVOI(ax, ct, cst, stf, ixInterface, ixBeam, sliceShown)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 1 || isempty(ax)
    ax = gca; % do not create a figure here
end

if nargin < 8 || isempty(zoomFactor)
    zoomFactor = 0.85;
end

if nargin < 9
    saveMatFile = '';
end

if isempty(stf) || ~isstruct(stf)
    error('matRad_plotSpotsVOI:InvalidSTF', ...
        'stf must be a non-empty struct array.');
end

if nargin < 6 || isempty(ixBeam) || ~isscalar(ixBeam) || ixBeam < 1 || ixBeam > numel(stf)
    error('matRad_plotSpotsVOI:InvalidBeamIndex', ...
        'ixBeam must be a valid beam index between 1 and numel(stf).');
end

if nargin < 5 || isempty(ixVOI) || ~isscalar(ixVOI) || ixVOI < 1 || ixVOI > size(cst,1)
    error('matRad_plotSpotsVOI:InvalidVOIRow', ...
        'ixVOI must be a valid row index in cst.');
end

if nargin < 7 || isempty(sliceShown)
    error('matRad_plotSpotsVOI:MissingSlice', ...
        'sliceShown must be provided.');
end

% CT dimensions
if isfield(ct, 'cubeDim') && ~isempty(ct.cubeDim)
    ctDim = ct.cubeDim;
else
    ctDim = size(ct.cubeHU);
end
ctDim = double(ctDim(:).');

% -------------------------------------------------------------------------
% 1) Build VOI voxel table from cst{ixVOI,4}{1}
% -------------------------------------------------------------------------
if ~iscell(cst) || size(cst,2) < 4 || isempty(cst{ixVOI,4})
    error('matRad_plotSpotsVOI:InvalidCSTVOI', ...
        'cst{ixVOI,4}{1} is missing or empty.');
end

linVOI = cst{ixVOI,4}{1};
linVOI = unique(linVOI(:));
linVOI = linVOI(linVOI >= 1 & linVOI <= prod(ctDim));

% Convert VOI linear indices into cube coordinates
[voiI, voiJ, voiK] = matRad_lin2cubeCoords(ct.cubeDim, linVOI);

voiWorld = matRad_cubeIndex2worldCoords(linVOI, ct);

voiTbl = table(linVOI, voiI, voiJ, voiK, ...
    voiWorld(:,1), voiWorld(:,2), voiWorld(:,3), ...
    'VariableNames', {'linVox', 'iCube', 'jCube', 'kCube', ...
                      'xWorld', 'yWorld', 'zWorld'});

voiCube = [voiI(:), voiJ(:), voiK(:)];

% -------------------------------------------------------------------------
% 2) Build ray table for the selected beam
% -------------------------------------------------------------------------
stfBeam = stf(ixBeam);

nRays = 0;
if isfield(stfBeam, 'ray') && ~isempty(stfBeam.ray)
    nRays = numel(stfBeam.ray);
end

rayGlobal = zeros(nRays, 1);
iBeamCol  = repmat(ixBeam, nRays, 1);
iRayCol   = zeros(nRays, 1);
nSpotsCol = zeros(nRays, 1);

xStartCol = NaN(nRays, 1);
yStartCol = NaN(nRays, 1);
zStartCol = NaN(nRays, 1);

xEndCol = NaN(nRays, 1);
yEndCol = NaN(nRays, 1);
zEndCol = NaN(nRays, 1);

for iRay = 1:nRays
    rayGlobal(iRay) = iRay;
    iRayCol(iRay) = iRay;

    ray = stfBeam.ray(iRay);

    if isfield(ray, 'energy') && ~isempty(ray.energy)
        nSpotsCol(iRay) = numel(ray.energy);
    elseif isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot') && ~isempty(ray.rayTracerInfo.perSpot)
        nSpotsCol(iRay) = numel(ray.rayTracerInfo.perSpot);
    else
        nSpotsCol(iRay) = 0;
    end

    spotPos = [];
    if exist('matRad_extractRayPoints', 'file') == 2
        try
            [spotPos, ~] = matRad_extractRayPoints(ray);
        catch
            spotPos = [];
        end
    end

    if ~isempty(spotPos)
        pStart = spotPos(1, :);
        pEnd   = spotPos(end, :);

        xStartCol(iRay) = pStart(1);
        yStartCol(iRay) = pStart(2);
        zStartCol(iRay) = pStart(3);

        xEndCol(iRay) = pEnd(1);
        yEndCol(iRay) = pEnd(2);
        zEndCol(iRay) = pEnd(3);
    end
end

rayTbl = table(rayGlobal, iBeamCol, iRayCol, nSpotsCol, ...
    xStartCol, yStartCol, zStartCol, ...
    xEndCol, yEndCol, zEndCol, ...
    'VariableNames', {'globalRay', 'iBeam', 'iRay', 'nSpots', ...
                      'xStart', 'yStart', 'zStart', ...
                      'xEnd', 'yEnd', 'zEnd'});

% -------------------------------------------------------------------------
% 3) Build a detailed spot table for all spots in the selected beam
% -------------------------------------------------------------------------
spotGlobalCol = [];
iBeamSpotCol  = [];
iRaySpotCol   = [];
iSpotCol      = [];
energyCol     = [];

iCubeCol      = [];
jCubeCol      = [];
kCubeCol      = [];

linVoxCol   = [];
xWorldCol   = [];
yWorldCol   = [];
zWorldCol   = [];
inVOICol    = [];

if ~isfield(stfBeam, 'ray') || isempty(stfBeam.ray)
    warning('matRad_plotSpotsVOI:NoRays', ...
        'Beam %d contains no rays.', ixBeam);
else
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

            spotCube = round(spots(iSpot).spotCube(:).');
            spotEnergy = spots(iSpot).energy;

            % spotCube is assumed to already be in cube coordinates [i j k]
            iC = spotCube(1);
            jC = spotCube(2);
            kC = spotCube(3);

            % Bounds check
            if iC < 1 || jC < 1 || kC < 1 || ...
               iC > ctDim(1) || jC > ctDim(2) || kC > ctDim(3)
                continue;
            end

            linVox = sub2ind(ctDim, iC, jC, kC);

            spotGlobalCol(end+1,1) = numel(spotGlobalCol) + 1; %#ok<AGROW>
            iBeamSpotCol(end+1,1)  = ixBeam; %#ok<AGROW>
            iRaySpotCol(end+1,1)   = iRay; %#ok<AGROW>
            iSpotCol(end+1,1)      = iSpot; %#ok<AGROW>
            energyCol(end+1,1)     = spotEnergy; %#ok<AGROW>

            iCubeCol(end+1,1) = iC; %#ok<AGROW>
            jCubeCol(end+1,1) = jC; %#ok<AGROW>
            kCubeCol(end+1,1) = kC; %#ok<AGROW>

            linVoxCol(end+1,1) = linVox; %#ok<AGROW>
            inVOICol(end+1,1)  = ismember([jC iC kC], voiCube, 'rows'); %#ok<AGROW>
        end
    end
end

if ~isempty(linVoxCol)
    worldCoords = matRad_cubeIndex2worldCoords(linVoxCol, ct);
    xWorldCol = worldCoords(:,1);
    yWorldCol = worldCoords(:,2);
    zWorldCol = worldCoords(:,3);
end

spotTblAll = table(spotGlobalCol, iBeamSpotCol, iRaySpotCol, iSpotCol, energyCol, ...
    iCubeCol, jCubeCol, kCubeCol, ...
    linVoxCol, xWorldCol, yWorldCol, zWorldCol, inVOICol, ...
    'VariableNames', {'globalSpot', 'iBeam', 'iRay', 'iSpot', 'energy', ...
                      'iCube', 'jCube', 'kCube', ...
                      'linVox', 'xWorld', 'yWorld', 'zWorld', 'inVOI'});

spotTblVOI = spotTblAll(spotTblAll.inVOI == 1, :);

% -------------------------------------------------------------------------
% 4) Overlay only VOI spots in the displayed slice
% -------------------------------------------------------------------------
% sliceShown is the kCube slice in cube coordinates
spotTblPlot = spotTblVOI(spotTblVOI.kCube == sliceShown, :);

hLayer = gobjects(0);

if isempty(spotTblPlot)
    title(ax, sprintf('Beam %d | slice %d | no VOI spots found', ixBeam, sliceShown), ...
        'Interpreter', 'none');
else
    uniqueE = unique(spotTblPlot.energy, 'sorted');
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
layerLabels = cell(nE, 1);

for iE = 1:nE
    idx = (spotTblPlot.energy == uniqueE(iE));
    subTbl = spotTblPlot(idx, :);

    % Stable order for connected lines
    subTbl = sortrows(subTbl, {'iRay', 'iSpot'});

    col = palette(mod(iE-1, nPalette) + 1, :);
    mk  = markerList{mod(iE-1, nMarkers) + 1};

    % For display: x = jCube, y = iCube
    x = subTbl.jCube;
    y = subTbl.iCube;

    nThisLayer = height(subTbl);
layerLabels{iE} = sprintf('%g MeV (n=%d)', uniqueE(iE), nThisLayer);
    if nThisLayer > 1
        plot(ax, y, x, '--', ...
            'Color', col, ...
            'LineWidth', 0.7, ...
            'HandleVisibility', 'off');
    end

    hLayer(iE) = plot(ax, y, x, ...
        'LineStyle', 'none', ...
        'Marker', mk, ...
        'MarkerSize', 6, ...
        'MarkerEdgeColor', col, ...
        'MarkerFaceColor', col, ...
        'Color', col, ...
        'DisplayName', layerLabels{iE});
end

% Keep any existing legend from matRad_showSliceFast and add these new items
legend(ax, 'show');
lgd = legend(ax);
if isgraphics(lgd)
    lgd.Location = 'eastoutside';
    lgd.Interpreter = 'none';
    lgd.Box = 'off';
    lgd.AutoUpdate = 'on';
end

title(ax, sprintf('Beam %d | slice %d | VOI spots only', ixBeam, sliceShown), ...
    'Interpreter', 'none');


  
end

xlabel(ax, 'j / x');
ylabel(ax, 'i / y');
grid(ax, 'on');
box(ax, 'on');
set(ax, 'Color', 'none', 'Layer', 'top');

% % Optional zoom around beam isocenter
% if ~isempty(zoomFactor) && isfield(stfBeam, 'isoCenter') && ~isempty(stfBeam.isoCenter)
%     isoCube = matRad_world2cubeCoords(stfBeam.isoCenter, ct);
%     isoCenterIx = round(isoCube);
%     [xlimVals, ylimVals] = matRad_getZoomWindow(isoCenterIx(2), isoCenterIx(1), ct, zoomFactor);
%     if xlimVals(1) ~= xlimVals(2) && ylimVals(1) ~= ylimVals(2)
%         set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
%     end
% end

% -------------------------------------------------------------------------
% Optional save
% -------------------------------------------------------------------------
if ~isempty(saveMatFile)
    save(saveMatFile, 'rayTbl', 'spotTblAll', 'voiTbl', 'spotTblVOI', 'sliceShown', 'ixBeam', 'ixVOI');
end

end