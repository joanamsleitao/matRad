function medianSpotCube = matRad_plotRay(ax, stf, iBeamTarget, iRayTarget, markerSize, weights, useGeoSpots, showLegend)
% matRad_plotRay - Visualize all spots from one selected ray in one beam
%
% Syntax:
%   medianSpotCube = matRad_plotRay(ax, stf, iBeamTarget, iRayTarget)
%   medianSpotCube = matRad_plotRay(ax, stf, iBeamTarget, iRayTarget, markerSize)
%   medianSpotCube = matRad_plotRay(ax, stf, iBeamTarget, iRayTarget, markerSize, weights)
%   medianSpotCube = matRad_plotRay(ax, stf, iBeamTarget, iRayTarget, markerSize, weights, useGeoSpots)
%   medianSpotCube = matRad_plotRay(ax, stf, iBeamTarget, iRayTarget, markerSize, weights, useGeoSpots, showLegend)
%
% Description:
%   Plots all spots belonging to one selected ray from one selected beam.
%   Spot positions are extracted from the independent helper
%   matRad_extractRayPoints(ray), which should return spotCube-based
%   positions and corresponding energies.
%
%   Spot color is based on machine energy using matRad_machineColorMap(stf).
%   Spot marker size is scaled by the corresponding spot weight.
%   Marker style is:
%     - first spot : x
%     - last spot  : triangle (^)
%     - middle spots use the ray role marker:
%         first ray  -> circle
%         middle ray -> square
%         last ray   -> triangle
%         others     -> plus
%
% Inputs:
%   ax           - Target axes handle
%   stf          - matRad steering file struct
%   iBeamTarget  - Beam index to plot
%   iRayTarget   - Ray index within the selected beam
%   markerSize   - (optional) base marker size, default: 5
%   weights      - (optional) spot weights vector, default: ones
%   useGeoSpots  - (optional) accepted for compatibility, not used here
%   showLegend   - (optional) true/false, show legend, default: true
%
% Outputs:
%   medianSpotCube - Median [x y z] cube coordinate of plotted points
%
% Reference entry:
% | `matRad_plotSingleRay` | `matRad_plotRay` | Visualize all spots from one selected ray in one beam | `medianSpotCube = matRad_plotRay(ax, stf, iBeamTarget, iRayTarget, markerSize, weights, useGeoSpots, showLegend)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% Defaults
if ~exist('markerSize','var') || isempty(markerSize)
    markerSize = 5;
end
if ~exist('weights','var') || isempty(weights)
    totalNumOfBixels = sum([stf.totalNumOfBixels]);
    weights = ones(totalNumOfBixels, 1);
end
if ~exist('useGeoSpots','var') || isempty(useGeoSpots) %#ok<NASGU>
    useGeoSpots = false; %#ok<NASGU>
end
if ~exist('showLegend','var') || isempty(showLegend)
    showLegend = true;
end

% Validation
if isempty(ax) || ~isvalid(ax)
    error('matRad_plotRay:InvalidAxes', ...
        'Invalid or missing axes handle.');
end

if iBeamTarget < 1 || iBeamTarget > numel(stf)
    error('matRad_plotRay:InvalidBeam', ...
        'iBeamTarget=%d is outside valid range 1..%d.', iBeamTarget, numel(stf));
end

nRaysBeam = numel(stf(iBeamTarget).ray);
if iRayTarget < 1 || iRayTarget > nRaysBeam
    error('matRad_plotRay:InvalidRay', ...
        'iRayTarget=%d is outside valid range 1..%d for beam %d.', ...
        iRayTarget, nRaysBeam, iBeamTarget);
end

hold(ax, 'on');

ray = stf(iBeamTarget).ray(iRayTarget);

% Marker shape by ray role in the beam
shape = local_rayMarkerShape(iRayTarget, nRaysBeam);

% Extract positions and energies using your independent helper
[spotPos, spotEnergy] = matRad_extractRayPoints(ray);

if isempty(spotPos)
    medianSpotCube = [NaN NaN NaN];
    warning('matRad_plotRay:NoPositions', ...
        'No spot positions found for beam %d ray %d.', iBeamTarget, iRayTarget);
    return;
end

% Normalize coordinates to Nx3
if size(spotPos, 2) == 2
    spotPos(:,3) = NaN;
elseif size(spotPos, 2) > 3
    spotPos = spotPos(:,1:3);
end

% Keep only valid spatial rows
validRows = all(isfinite(spotPos(:,1:2)), 2);
spotPos = spotPos(validRows, :);

if isempty(spotPos)
    medianSpotCube = [NaN NaN NaN];
    warning('matRad_plotRay:NoValidPositions', ...
        'No valid spot coordinates found for beam %d ray %d.', iBeamTarget, iRayTarget);
    return;
end

% Match weights to number of points if possible
if isempty(weights)
    spotWeights = ones(size(spotPos,1), 1);
else
    spotWeights = weights(:);
    if numel(spotWeights) < size(spotPos,1)
        spotWeights(end+1:size(spotPos,1),1) = 1;
    elseif numel(spotWeights) > size(spotPos,1)
        spotWeights = spotWeights(1:size(spotPos,1));
    end
end

% Energy handling
if isempty(spotEnergy)
    spotEnergy = ones(size(spotPos,1), 1);
else
    spotEnergy = spotEnergy(:);
    if numel(spotEnergy) < size(spotPos,1)
        spotEnergy(end+1:size(spotPos,1),1) = spotEnergy(end);
    elseif numel(spotEnergy) > size(spotPos,1)
        spotEnergy = spotEnergy(1:size(spotPos,1));
    end
end

% Weight normalization
wMax = max(spotWeights);
if wMax == 0
    wMax = 1;
end

% Energy color map
try
    energyColorMap = matRad_machineColorMap(stf);
catch
    energyColorMap = containers.Map('KeyType','double','ValueType','any');
    warning('matRad_plotRay:NoEnergyMap', ...
        'matRad_machineColorMap not available. Falling back to gray colors.');
end

% Plot spots
usedEnergies = containers.Map('KeyType','double','ValueType','any');

nPts = size(spotPos,1);

for iPt = 1:nPts
    energy = spotEnergy(iPt);

    % Color from energy map
    if isa(energyColorMap, 'containers.Map') && isKey(energyColorMap, energy)
        c = energyColorMap(energy);
    else
        c = [0.5 0.5 0.5];
    end

    % Size scaled by weight, similar to matRad_plotSpotsSlice
    w = spotWeights(iPt) / wMax;
    mSize = markerSize * max(w, 0.2);

    % Spot-specific marker shape
    if nPts == 1
        spotShape = 'x';
    elseif iPt == 1
        spotShape = 'x';
    elseif iPt == nPts
        spotShape = '^';
    else
        spotShape = shape;
    end

    plot(ax, spotPos(iPt,1), spotPos(iPt,2), spotShape, ...
        'Color', c, ...
        'MarkerFaceColor', c, ...
        'MarkerSize', mSize, ...
        'LineWidth', 1.2);

    if ~isKey(usedEnergies, energy)
        usedEnergies(energy) = true;
    end
end

% Legend
if showLegend
    energyKeys = cell2mat(keys(usedEnergies));
    energyKeys = sort(energyKeys);

    legendHandles = gobjects(0);
    legendLabels  = {};

    % Energy legend entries
    for iE = 1:numel(energyKeys)
        energy = energyKeys(iE);

        if isa(energyColorMap, 'containers.Map') && isKey(energyColorMap, energy)
            c = energyColorMap(energy);
        else
            c = [0.5 0.5 0.5];
        end

        h = plot(ax, NaN, NaN, 'o', ...
            'Color', c, ...
            'MarkerFaceColor', c, ...
            'MarkerSize', 8, ...
            'LineWidth', 1.2);

        legendHandles(end+1) = h; %#ok<AGROW>
        legendLabels{end+1} = sprintf('Energy %g', energy); %#ok<AGROW>
    end

    % Ray shape legend entry
    hRay = plot(ax, NaN, NaN, shape, ...
        'Color', 'k', ...
        'MarkerSize', 8, ...
        'LineWidth', 1.5);

    legendHandles(end+1) = hRay;
    legendLabels{end+1} = sprintf('Beam %d Ray %d', iBeamTarget, iRayTarget);

    legend(ax, legendHandles, legendLabels, ...
        'Location', 'bestoutside', ...
        'Interpreter', 'none', ...
        'FontSize', 10);
end

axis(ax, 'equal');
axis(ax, 'tight');

medianSpotCube = [ ...
    median(spotPos(:,1), 'omitnan'), ...
    median(spotPos(:,2), 'omitnan'), ...
    median(spotPos(:,3), 'omitnan') ];

end

% -------------------------------------------------------------------------
function shape = local_rayMarkerShape(iRayTarget, nRaysBeam)
% local_rayMarkerShape - Choose marker based on ray role in the beam

if nRaysBeam <= 1
    shape = 'o';
    return;
end

iMid = ceil(nRaysBeam/2);

if iRayTarget == 1
    shape = 'o';
elseif iRayTarget == iMid
    shape = 's';
elseif iRayTarget == nRaysBeam
    shape = '^';
else
    shape = '+';
end

end