function medianSpotCube = matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights, showRayTracing, useGeoSpots, sliceIdx)
% matRad_plotSpotsSlice - Visualizes spot positions for a given CT slice.
%
% INPUTS:
%   ax, ct, stf       - axes handle, CT structure, treatment plan struct
%   markerSize        - marker size scale (default 5)
%   weights           - vector of weights for spots (default ones)
%   showRayTracing    - bool to show ray paths (default false)
%   useGeoSpots       - bool to plot spots from spotsInfoGeo (default false)
%   sliceIdx          - CT slice index (Z direction) to show spots (optional).
%                       If empty, shows all spots (default).
%
% OUTPUT:
%   medianSpotCube    - Median spot position [X Y Z] (for zoom)

%% --- Defaults
if ~exist('markerSize','var') || isempty(markerSize)
    markerSize = 5;
end
if ~exist('weights','var') || isempty(weights)
    totalNumOfBixels = sum([stf.totalNumOfBixels]);
    weights = ones(totalNumOfBixels, 1);
end
if ~exist('showRayTracing','var') || isempty(showRayTracing)
    showRayTracing = 0;
end
if ~exist('useGeoSpots','var') || isempty(useGeoSpots)
    useGeoSpots = 0;
end
if ~exist('sliceIdx','var')
    sliceIdx = []; % no filtering
end
if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    return;
end
hold(ax, 'on');

%% --- Setup
wMax = max(weights);
colors = lines(10);
shapes = {'o', '+', 's', '^', 'v', 'x', 'd', 'p', 'h', '*'};

usedEnergies = containers.Map('KeyType','double','ValueType','any');
usedBeams    = containers.Map('KeyType','int32','ValueType','any');

legendGeoSpotHandled = false;
legendGeoSpotHandle = [];

allSpotCubes = [];

%% --- Build energy-to-color map
allEnergies = [stf.ray];
allEnergies = [allEnergies.energy];
uniqueEnergies = unique(allEnergies);
energyToColorMap = containers.Map('KeyType', 'double', 'ValueType', 'int32');
for i = 1:numel(uniqueEnergies)
    energyToColorMap(uniqueEnergies(i)) = i;
end

%% --- Loop beams/rays/spots
for iBeam = 1:numel(stf)
    shape = shapes{mod(iBeam-1,numel(shapes))+1};
    for iRay = 1:numel(stf(iBeam).ray)
        currentRay = stf(iBeam).ray(iRay).rayTracerInfo;

        if showRayTracing
            for idx = 1:numel(currentRay.ix)
                p = matRad_world2cubeIndex(matRad_cubeIndex2worldCoords(currentRay.ix(idx), ct), ct);
                plot(ax, p(2), p(1), 'b.', 'MarkerSize', 2);
            end
        end

        numSpots = numel(stf(iBeam).ray(iRay).energy);
        for iSpot = 1:numSpots
            wIx = matRad_spotIx(stf, iBeam, iRay, iSpot);
            w   = weights(wIx)/wMax;
            mSize = markerSize * max(w, 0.2);

            energy   = stf(iBeam).ray(iRay).energy(iSpot);
            colorIdx = mod(energyToColorMap(energy)-1, size(colors,1)) + 1;
            c = colors(colorIdx, :);

            spotCube = currentRay.perSpot(iSpot).spotCube; % [x y z]

            % --- Slice filtering ---
            % if ~isempty(sliceIdx) && round(spotCube(3)) ~= sliceIdx
            %     continue; % skip if not in this slice
            % end

            if w == 0 % && round(spotCube(3)) ~= sliceIdx
                continue; % skip if not in this slice
            end
            % 
            % if w == 0
            %     mSize = 0;
            % end

            h = plot(ax, spotCube(1), spotCube(2), shape, 'Color', c, ...
                'MarkerSize', mSize, 'LineWidth', 1.2);

            if ~isKey(usedEnergies, energy)
                usedEnergies(energy) = h;
            end
            if ~isKey(usedBeams, iBeam)
                usedBeams(iBeam) = h;
            end

            allSpotCubes(end+1,:) = spotCube; %#ok<AGROW>
        end

        % --- Geo spots ---
        if useGeoSpots && isfield(stf(iBeam).ray(iRay), 'spotsInfoGeo')
            for iSpot = 1:numel(stf(iBeam).ray(iRay).spotsInfoGeo)
                pos = stf(iBeam).ray(iRay).spotsInfoGeo(iSpot).spotCube;
                if ~isempty(sliceIdx) && round(pos(3)) ~= sliceIdx
                    continue;
                end
                hGeo = plot(ax, pos(1), pos(2), 'kd', 'MarkerSize', 6, 'LineWidth', 1.2);
                if ~legendGeoSpotHandled
                    legendGeoSpotHandle = hGeo;
                    legendGeoSpotHandled = true;
                end
            end
        end
    end
end

%% --- Build legends

% Create dummy handles for legend entries
holdState = ishold(ax);
hold(ax, 'on');

% Energy legend: colored filled circles
energyKeys = cell2mat(keys(usedEnergies));
uniqueEnergiesSorted = sort(energyKeys);
numEnergies = numel(uniqueEnergiesSorted);
energyLegendHandles = gobjects(numEnergies,1);
energyLegendLabels = strings(numEnergies,1);

for i = 1:numEnergies
    energy = uniqueEnergiesSorted(i);
    colorIdx = mod(energyToColorMap(energy)-1, size(colors,1)) + 1;
    c = colors(colorIdx, :);
    % Plot invisible colored circles for legend
    energyLegendHandles(i) = plot(ax, NaN, NaN, 'o', 'Color', c, 'MarkerFaceColor', c, 'MarkerSize', 8, 'LineWidth', 1.5);
    energyLegendLabels(i) = "Energy " + string(energy);
end

% Beam legend: black shapes, one per beam
numBeams = numel(stf);
beamLegendHandles = gobjects(numBeams,1);
beamLegendLabels = strings(numBeams,1);

for iBeam = 1:numBeams
    shape = shapes{mod(iBeam-1,numel(shapes))+1};
    % Plot invisible black shapes for legend
    beamLegendHandles(iBeam) = plot(ax, NaN, NaN, shape, 'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.5);
    beamLegendLabels(iBeam) = "Beam " + string(iBeam);
end

% Geo spot legend entry
geoLegendHandles = [];
geoLegendLabels = [];
if legendGeoSpotHandled
    geoLegendHandles = plot(ax, NaN, NaN, 'kd', 'MarkerSize', 8, 'LineWidth', 1.5);
    geoLegendLabels = "Geo Spot Position";
end

% Combine all legend handles and labels
legendHandles = [energyLegendHandles; beamLegendHandles];
legendLabels = [energyLegendLabels; beamLegendLabels];

if legendGeoSpotHandled
    legendHandles(end+1) = geoLegendHandles;
    legendLabels(end+1) = geoLegendLabels;
end

% hold(ax, holdState);

legend(ax, legendHandles, legendLabels, 'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 10);

%%
% Compute median for zooming
if ~isempty(allSpotCubes)
    medianSpotCube = median(allSpotCubes, 1); % [X Y Z]
else
    medianSpotCube = [NaN NaN NaN];
end

end
