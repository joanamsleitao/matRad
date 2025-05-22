function medianSpotCube = matRad_plotSingleRay(ax, stf, iRayTarget, markerSize, weights, useGeoSpots)
% matRad_plotSingleRay Visualizes all spots from a specific ray index in matRad.
%
%   This function plots all spots corresponding to a single `iRay` index
%   across all beams. Each spot is displayed on the given axes (`ax`) with
%   a marker size proportional to its weight and a color corresponding to
%   its energy. Ray indices are represented with unique shapes (in black).
%   If available and requested, geometric spot and ray positions from
%   `spotsInfoGeo` are also displayed.
%
%   INPUTS:
%     - ax: Handle to the axes for plotting.
%     - ct: Structure containing CT image and geometry information.
%     - stf: matRad structure with spot scanning beam geometry and ray tracing results.
%     - iRayTarget: Index of the ray to be visualized (across all beams).
%     - markerSize (optional): Reference size of markers (default = 5).
%     - weights (optional): Vector of weights for each spot.
%     - useGeoSpots (optional): If true (=1), geometric positions
%                               from `spotsInfoGeo` are also plotted.
%                               (default = false, 0)
%
%   OUTPUTS:
%     - medianSpotCube: to help calculate zoom
%
%   FEATURES:
%     - Spot colors represent energy layers (legend entries with filled markers).
%     - Spot shapes represent ray indices (legend entry in black).
%     - Ray index must be globally unique across all beams.
%     - Geometric spot positions (`spotCube`) are plotted as black diamonds.
%     - Ray entry points (`rayPosCube`) are plotted as small black squares.
%     - A legend is generated with one entry per energy, one per ray shape,
%       and optionally an entry for the geometric spot positions.
%
%   EXAMPLE USAGE:
%       figure; ax = axes;
%       matRad_plotSingleRay(ax, ct, stf, 12, 6, weights, true);
%
%   See also: matRad_plotSpotsSliceJ, matRad_world2cubeIndex, matRad_spotIx
%
%%
% --- Handle defaults ---
if ~exist('markerSize','var') || isempty(markerSize)
    markerSize = 5;
end
if ~exist('weights','var') || isempty(weights)
    totalNumOfBixels = sum([stf.totalNumOfBixels]);
    weights = ones(totalNumOfBixels, 1);
end
if ~exist('useGeoSpots','var') || isempty(useGeoSpots)
    useGeoSpots = 0;
end

% --- Initial setup ---
hold(ax, 'on');
colors = lines(10);
shapes = {'o', '+', 's', '^', 'v', 'x', 'd', 'p', 'h', '*'};
wMax = max(weights);

% --- Search for iRay ---
raySpotCubes = {};
found = false;
for iBeam = 1:numel(stf)
    for iRay = 1:numel(stf(iBeam).ray)
        if iRay == iRayTarget
            found = true;
            shape = shapes{mod(iRay-1, numel(shapes))+1};  % shape for this iRay
            ray = stf(iBeam).ray(iRay);
            tracer = ray.rayTracerInfo;
            
            numSpots = numel(ray.energy);

            % Build energy-color map
            uniqueEnergies = unique(ray.energy);
            energyToColorMap = containers.Map('KeyType', 'double', 'ValueType', 'int32');
            for i = 1:numel(uniqueEnergies)
                energyToColorMap(uniqueEnergies(i)) = i;
            end

            usedEnergies = containers.Map('KeyType','double','ValueType','any');
            rayLegendHandle = [];

            for iSpot = 1:numSpots
                wIx = matRad_spotIx(stf, iBeam, iRay, iSpot);
                w = weights(wIx) / wMax;
                mSize = markerSize * w;

                energy = ray.energy(iSpot);
                colorIdx = mod(energyToColorMap(energy)-1, size(colors,1)) + 1;
                c = colors(colorIdx, :);
                spot = tracer.perSpot(iSpot).spotCube;
                % Inside your iSpot loop (after getting spotCube):
            % spotCube = tracer.perSpot(iSpot).spotCube;
            raySpotCubes{end+1} = spot; % Collect for median calc

                h = plot(ax, spot(1), spot(2), shape, ...
                    'Color', c, 'MarkerSize', mSize, 'LineWidth', 1.2);
                if ~isKey(usedEnergies, energy)
                    usedEnergies(energy) = h;
                end
                if isempty(rayLegendHandle)
                    rayLegendHandle = plot(ax, NaN, NaN, shape, ...
                        'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.5);
                end
            end

            % Optional geometric spot positions
            geoLegendHandle = [];
            if useGeoSpots && isfield(ray, 'spotsInfoGeo')
                for iSpot = 1:numel(ray.spotsInfoGeo)
                    s = ray.spotsInfoGeo(iSpot);
                    if isfield(s, 'spotCube')
                        p = s.spotCube;
                        hGeo = plot(ax, p(1), p(2), 'kd', 'MarkerSize', 6, 'LineWidth', 1.2);
                        if isempty(geoLegendHandle)
                            geoLegendHandle = plot(ax, NaN, NaN, 'kd', ...
                                'MarkerSize', 8, 'LineWidth', 1.5);
                        end
                    end
                    if isfield(s, 'rayPosCube')
                        p = s.rayPosCube;
                        plot(ax, p(1), p(2), 'ks', 'MarkerSize', 4, 'LineWidth', 1.0);
                    end
                end
            end

            % Build legend
            legendHandles = [];
            legendLabels = [];

            % Energy (colored filled circles)
            energyKeys = cell2mat(keys(usedEnergies));
            for i = 1:numel(energyKeys)
                e = energyKeys(i);
                colorIdx = mod(energyToColorMap(e)-1, size(colors,1)) + 1;
                c = colors(colorIdx, :);
                he = plot(ax, NaN, NaN, 'o', 'Color', c, 'MarkerFaceColor', c, 'MarkerSize', 8, 'LineWidth', 1.5);
                legendHandles(end+1) = he;
                legendLabels{end+1} = ['Energy ' num2str(e)];
            end

            % Ray legend
            legendHandles(end+1) = rayLegendHandle;
            legendLabels{end+1} = ['Ray ' num2str(iRayTarget)];

            % Geo spot legend
            if ~isempty(geoLegendHandle)
                legendHandles(end+1) = geoLegendHandle;
                legendLabels{end+1} = 'Geo Spot Position';
            end

            legend(ax, legendHandles, legendLabels, ...
                'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 10);

            break;
        end
    end
    if found, break; end
end

% Compute the median spotCube position for zooming
spotCubes = cat(1, raySpotCubes{:}); % raySpotCubes should be collected in the loop
medianSpotCube = median(spotCubes, 1); % Returns [x, y, z] in cube coordinates


if ~found
    warning("Ray index %d not found in any beam.", iRayTarget);
end

