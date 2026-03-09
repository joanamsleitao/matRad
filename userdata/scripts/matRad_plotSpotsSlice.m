function medianSpotCube = matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights, showRayTracing, useGeoSpots, sliceIdx)
% matRad_plotSpotsSlice - Visualizes spot positions for a given CT slice
%
% Syntax:
%   medianSpotCube = matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights, showRayTracing, useGeoSpots, sliceIdx)
%
% Description:
%   Plots spot positions on a given axis, color-coded by machine energy
%   (via matRad_machineColorMap) and shaped by beam index. Optionally
%   filters spots by CT slice index.
%
% Inputs:
%   ax              - axes handle for plotting
%   ct              - CT structure
%   stf             - treatment plan struct (beam geometry)
%   markerSize      - marker size scale (default 5)
%   weights         - vector of weights for spots (default ones)
%   showRayTracing  - bool to show ray paths (default false)
%   useGeoSpots     - bool to plot spots from spotsInfoGeo (default false)
%   sliceIdx        - CT slice index (Z direction) to show spots (optional).
%                     If empty, shows all spots (default).
%
% Output:
%   medianSpotCube - Median spot position [X Y Z] (for zoom)
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_plotSpotsSlice` | `matRad_plotSpotsSlice` | Visualize spot positions color-coded by energy | `medianSpotCube = matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights, showRayTracing, useGeoSpots, sliceIdx)` | 🟢 |
% -------------------------------------------------------------------------

%% --- Defaults ---
if ~exist('markerSize','var') || isempty(markerSize)
    markerSize = 5;
end
if ~exist('weights','var') || isempty(weights)
    totalNumOfBixels = sum([stf.totalNumOfBixels]);
    weights = ones(totalNumOfBixels, 1);
end
if ~exist('showRayTracing','var') || isempty(showRayTracing)
    showRayTracing = false;
end
if ~exist('useGeoSpots','var') || isempty(useGeoSpots)
    useGeoSpots = false;
end
if ~exist('sliceIdx','var')
    sliceIdx = []; % no filtering
end
if isempty(ax) || ~isvalid(ax)
    warning('matRad_plotSpotsSlice:InvalidAxes', ...
            'Invalid or missing axes handle. Nothing will be plotted.');
    medianSpotCube = [NaN NaN NaN];
    return;
end

hold(ax, 'on');

%% --- Setup ---
wMax = max(weights);
if wMax == 0
    warning('matRad_plotSpotsSlice:ZeroWeights', ...
            'All weights are zero. No spots will be plotted.');
    medianSpotCube = [NaN NaN NaN];
    return;
end

shapes = {'o', '+', 's', '^', 'v', 'x', 'd', 'p', 'h', '*'};

usedEnergies = containers.Map('KeyType','double','ValueType','any');
usedBeams    = containers.Map('KeyType','int32','ValueType','any');

legendGeoSpotHandled = false;
legendGeoSpotHandle = [];

allSpotCubes = [];

%% --- Get machine-based energy color map ---
energyColorMap = matRad_machineColorMap(stf);

%% --- Loop beams/rays/spots ---
for iBeam = 1:numel(stf)
    shape = shapes{mod(iBeam-1, numel(shapes)) + 1};
    
    for iRay = 1:numel(stf(iBeam).ray)
        currentRay = stf(iBeam).ray(iRay).rayTracerInfo;

        % Optional: show ray tracing path
        if showRayTracing
            for idx = 1:numel(currentRay.ix)
                p = matRad_world2cubeIndex(matRad_cubeIndex2worldCoords(currentRay.ix(idx), ct), ct);
                plot(ax, p(2), p(1), 'b.', 'MarkerSize', 2);
            end
        end

        numSpots = numel(stf(iBeam).ray(iRay).energy);
        
        for iSpot = 1:numSpots
            wIx = matRad_spotIx(stf, iBeam, iRay, iSpot);
            w   = weights(wIx) / wMax;

            % Skip zero-weight spots
            if w == 0
                continue;
            end

            energy   = stf(iBeam).ray(iRay).energy(iSpot);
            spotCube = currentRay.perSpot(iSpot).spotCube; % [x y z]

            % Slice filtering: skip if not in requested slice
            if ~isempty(sliceIdx) && round(spotCube(3)) ~= sliceIdx
                continue;
            end

            % Get color from machine energy map
            if isKey(energyColorMap, energy)
                c = energyColorMap(energy);
            else
                % Fallback: gray if energy not in machine map
                c = [0.5 0.5 0.5];
                warning('matRad_plotSpotsSlice:EnergyNotFound', ...
                        'Energy %.1f MeV not found in machine colormap. Using gray.', energy);
            end

            % Scale marker size by weight
            mSize = markerSize * max(w, 0.2);

            % Plot spot
            h = plot(ax, spotCube(1), spotCube(2), shape, ...
                'Color', c, 'MarkerSize', mSize, 'LineWidth', 1.2);

            % Track for legend
            if ~isKey(usedEnergies, energy)
                usedEnergies(energy) = h;
            end
            if ~isKey(usedBeams, iBeam)
                usedBeams(iBeam) = h;
            end

            allSpotCubes(end+1, :) = spotCube; %#ok<AGROW>
        end

        % --- Geo spots (optional) ---
        if useGeoSpots && isfield(stf(iBeam).ray(iRay), 'spotsInfoGeo')
            for iSpot = 1:numel(stf(iBeam).ray(iRay).spotsInfoGeo)
                pos = stf(iBeam).ray(iRay).spotsInfoGeo(iSpot).spotCube;
                
                % Slice filtering for geo spots
                if ~isempty(sliceIdx) && round(pos(3)) ~= sliceIdx
                    continue;
                end
                
                hGeo = plot(ax, pos(1), pos(2), 'kd', ...
                    'MarkerSize', 6, 'LineWidth', 1.2);
                
                if ~legendGeoSpotHandled
                    legendGeoSpotHandle = hGeo;
                    legendGeoSpotHandled = true;
                end
            end
        end
    end
end

%% --- Build legends ---

% Energy legend: colored filled circles
energyKeys = cell2mat(keys(usedEnergies));
uniqueEnergiesSorted = sort(energyKeys);
numEnergies = numel(uniqueEnergiesSorted);
energyLegendHandles = gobjects(numEnergies, 1);
energyLegendLabels = strings(numEnergies, 1);

for i = 1:numEnergies
    energy = uniqueEnergiesSorted(i);
    
    if isKey(energyColorMap, energy)
        c = energyColorMap(energy);
    else
        c = [0.5 0.5 0.5];
    end
    
    % Plot invisible colored circles for legend
    energyLegendHandles(i) = plot(ax, NaN, NaN, 'o', ...
        'Color', c, 'MarkerFaceColor', c, 'MarkerSize', 8, 'LineWidth', 1.5);
    energyLegendLabels(i) = sprintf('Energy %.1f MeV', round(energy, 1));
end

% Beam legend: black shapes, one per beam
beamKeys = cell2mat(keys(usedBeams));
uniqueBeamsSorted = sort(beamKeys);
numBeams = numel(uniqueBeamsSorted);
beamLegendHandles = gobjects(numBeams, 1);
beamLegendLabels = strings(numBeams, 1);

for i = 1:numBeams
    iBeam = uniqueBeamsSorted(i);
    shape = shapes{mod(iBeam-1, numel(shapes)) + 1};
    
    % Plot invisible black shapes for legend
    beamLegendHandles(i) = plot(ax, NaN, NaN, shape, ...
        'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.5);
    beamLegendLabels(i) = sprintf('Beam %d', iBeam);
end

% Geo spot legend entry
geoLegendHandles = [];
geoLegendLabels = [];
if legendGeoSpotHandled
    geoLegendHandles = plot(ax, NaN, NaN, 'kd', ...
        'MarkerSize', 8, 'LineWidth', 1.5);
    geoLegendLabels = "Geo Spot Position";
end

% Combine all legend handles and labels
legendHandles = [energyLegendHandles; beamLegendHandles];
legendLabels = [energyLegendLabels; beamLegendLabels];

if legendGeoSpotHandled
    legendHandles(end+1) = geoLegendHandles;
    legendLabels(end+1) = geoLegendLabels;
end

legend(ax, legendHandles, legendLabels, ...
    'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 10);

%% --- Compute median for zooming ---
if ~isempty(allSpotCubes)
    medianSpotCube = median(allSpotCubes, 1); % [X Y Z]
else
    medianSpotCube = [NaN NaN NaN];
end

end