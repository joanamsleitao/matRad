function medianSpotCube = matRad_plotSpotsByEnergyLayer(ax, ct, stf, markerSize, weights, showRayTracing, useGeoSpots, energyRanges)
% matRad_plotSpotsByEnergyRange Visualizes spots filtered by specified energy ranges with distinct shapes/colors.
%
% INPUTS:
%   ax            - axes handle
%   ct            - CT structure
%   stf           - treatment plan structure (array of beams)
%   markerSize    - base marker size scale (default 5)
%   weights       - vector of weights for spots (default ones)
%   showRayTracing- boolean to show ray paths (default false)
%   useGeoSpots   - boolean to plot geo spots (default false)
%   energyRanges  - vector of energies to include (default all)
%
% OUTPUT:
%   medianSpotCube - median [X Y Z] spot position of all plotted spots
%
% Notes:
%   - Spots with zero weight get tiny markers.
%   - Different beams get different marker shapes.
%   - Energies get distinct colors.
%   - Uses tolerance when matching energies.

if nargin < 4 || isempty(markerSize),    markerSize = 5; end
if nargin < 5 || isempty(weights)
    totalSpots = sum(arrayfun(@(b) sum(arrayfun(@(r) numel(r.energy), b.ray)), stf));
    weights = ones(totalSpots,1);
end
if nargin < 6 || isempty(showRayTracing), showRayTracing = false; end
if nargin < 7 || isempty(useGeoSpots), useGeoSpots = false; end
if nargin < 8, energyRanges = []; end

if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    medianSpotCube = [NaN NaN NaN];
    return;
end
hold(ax, 'on');

energyTol = 1e-05; % tolerance for energy matching

colors = lines(20); % color map for energies
shapes = {'o', '+', 's', '^', 'v', 'x', 'd', 'p', 'h', '*'}; % shapes for beams

% Gather all unique energies from stf
allEnergies = [];
for b = 1:numel(stf)
    for r = 1:numel(stf(b).ray)
        allEnergies = [allEnergies stf(b).ray(r).energy]; %#ok<AGROW>
    end
end
uniqueEnergies = unique(allEnergies);

% If energyRanges not specified, plot all energies
if isempty(energyRanges)
    energiesToPlot = uniqueEnergies;
else
    energiesToPlot = energyRanges(:)';
end

% Build map energy -> color index for consistency
energyToColorIdx = containers.Map('KeyType','double','ValueType','int32');
for i = 1:numel(uniqueEnergies)
    energyToColorIdx(uniqueEnergies(i)) = mod(i-1,size(colors,1)) + 1;
end

usedEnergies = containers.Map('KeyType','double','ValueType','logical');
usedBeams = containers.Map('KeyType','int32','ValueType','logical');

allSpotCubes = [];

weightIdx = 0; % running index to track spot weights in weights vector

for iBeam = 1:numel(stf)
    shape = shapes{mod(iBeam-1, numel(shapes))+1};
    for iRay = 1:numel(stf(iBeam).ray)
        rayInfo = stf(iBeam).ray(iRay).rayTracerInfo;

        % Show ray tracing points
        if showRayTracing && isfield(rayInfo, 'ix')
            for idx = 1:numel(rayInfo.ix)
                p = matRad_world2cubeIndex(matRad_cubeIndex2worldCoords(rayInfo.ix(idx), ct), ct);
                plot(ax, p(2), p(1), 'b.', 'MarkerSize', 2);
            end
        end

        % Plot spots for this ray
        numSpots = numel(stf(iBeam).ray(iRay).energy);
        for iSpot = 1:numSpots
            weightIdx = weightIdx + 1;
            spotEnergy = stf(iBeam).ray(iRay).energy(iSpot);

            % Skip spot if not in energyRanges (with tolerance)
            if ~isempty(energiesToPlot) && ~any(abs(energiesToPlot - spotEnergy) < energyTol)
                continue
            end

            w = weights(weightIdx);
            mSize = markerSize * max(w, 0.01); % tiny if zero weight

            colorIdx = energyToColorIdx(spotEnergy);
            c = colors(colorIdx, :);

            spotCube = rayInfo.perSpot(iSpot).spotCube;
            h = plot(ax, spotCube(1), spotCube(2), shape, ...
                'Color', c, 'MarkerSize', mSize, 'LineWidth', 1.2);

            % Remember for legend
            usedEnergies(spotEnergy) = true;
            usedBeams(iBeam) = true;

            allSpotCubes(end+1, :) = spotCube; %#ok<AGROW>
        end

        % Plot geo spots if requested
        if useGeoSpots && isfield(stf(iBeam).ray(iRay), 'spotsInfoGeo')
            for iGeoSpot = 1:numel(stf(iBeam).ray(iRay).spotsInfoGeo)
                pos = stf(iBeam).ray(iRay).spotsInfoGeo(iGeoSpot).spotCube;
                hGeo = plot(ax, pos(1), pos(2), 'kd', 'MarkerSize', 6, 'LineWidth', 1.2);
            end
        end
    end
end

% Build legend handles for energies
energyKeys = cell2mat(keys(usedEnergies));
energyKeys = sort(energyKeys);
energyLegendHandles = gobjects(numel(energyKeys), 1);
energyLegendLabels = strings(numel(energyKeys), 1);
for i = 1:numel(energyKeys)
    e = energyKeys(i);
    colorIdx = energyToColorIdx(e);
    c = colors(colorIdx, :);
    energyLegendHandles(i) = plot(ax, NaN, NaN, 'o', 'Color', c, 'MarkerFaceColor', c, 'MarkerSize', 8, 'LineWidth', 1.5);
    energyLegendLabels(i) = sprintf('Energy %.2f MeV', e);
end

% Build legend handles for beams
beamKeys = cell2mat(keys(usedBeams));
beamLegendHandles = gobjects(numel(beamKeys), 1);
beamLegendLabels = strings(numel(beamKeys), 1);
for i = 1:numel(beamKeys)
    b = beamKeys(i);
    shape = shapes{mod(b-1,numel(shapes))+1};
    beamLegendHandles(i) = plot(ax, NaN, NaN, shape, 'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.5);
    beamLegendLabels(i) = sprintf('Beam %d', b);
end

% Combine legends and show
legendHandles = [energyLegendHandles; beamLegendHandles];
legendLabels = [energyLegendLabels; beamLegendLabels];
legend(ax, legendHandles, legendLabels, 'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 10);

% Median spot cube for zooming/reference
if ~isempty(allSpotCubes)
    medianSpotCube = median(allSpotCubes, 1);
else
    medianSpotCube = [NaN NaN NaN];
end

axis(ax, 'equal');
grid(ax, 'on');
xlabel(ax, 'X (voxel index)');
ylabel(ax, 'Y (voxel index)');
title(ax, 'Spots filtered by Energy Layers');

hold(ax, 'off');

end
