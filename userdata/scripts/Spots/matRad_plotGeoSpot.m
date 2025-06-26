function medianSpotCube = matRad_plotGeoSpot(ax, stf, beamSelection, raySelection, markerSize, showRayTracing)
% matRad_plotGeoSpot - Visualizes geometric spot positions for selected beams and rays.
%
% INPUTS:
%   ax             : axes handle to plot into.
%   stf            : matRad structure with beam and ray data.
%   beamSelection  : vector of beam indices to plot.
%   raySelection   : (optional) cell array or vector specifying rays per beam.
%                    If empty or missing, all rays in beamSelection are plotted.
%   markerSize     : (optional) marker size, default=6.
%   showRayTracing : (optional) bool to plot ray paths, default=false.
%
% OUTPUT:
%   medianSpotCube : median of all spot positions plotted.

if nargin < 4
    raySelection = [];
end
if nargin < 5 || isempty(markerSize)
    markerSize = 6;
end
if nargin < 6 || isempty(showRayTracing)
    showRayTracing = false;
end

hold(ax, 'on');
usedBeams = containers.Map('KeyType','char','ValueType','any');
legendHandles = [];
legendLabels = [];
raySpotCubes = {};

for b = 1:numel(beamSelection)
    iBeam = beamSelection(b);

    % Determine rays to plot for this beam
    if isempty(raySelection)
        raysToPlot = 1:numel(stf(iBeam).ray);
    elseif isnumeric(raySelection) && numel(beamSelection) == 1
        raysToPlot = raySelection;
    elseif iscell(raySelection) && numel(raySelection) == numel(beamSelection)
        raysToPlot = raySelection{b};
    else
        error('raySelection must be empty, numeric vector for single beam, or cell array per beam.');
    end

    for iRay = raysToPlot
        ray = stf(iBeam).ray(iRay);
        tracer = ray.rayTracerInfo;

        if showRayTracing && isfield(tracer, 'ix')
            for idx = 1:numel(tracer.ix)
                p = matRad_world2cubeIndex(matRad_cubeIndex2worldCoords(tracer.ix(idx), stf(iBeam).ct), stf(iBeam).ct);
                plot(ax, p(2), p(1), 'b.', 'MarkerSize', 1);
            end
        end

        for iSpot = 1:numel(ray.spotsInfoGeo)
            s = ray.spotsInfoGeo(iSpot);

            if isfield(s, 'spotCube')
                spot = s.spotCube;
                raySpotCubes{end+1} = spot;

                % Plot geo spot as black diamond only
                plot(ax, spot(1), spot(2), 'kd', 'MarkerSize', markerSize, 'LineWidth', 1.2);
            end

            if isfield(s, 'rayPosCube')
                p = s.rayPosCube;
                plot(ax, p(1), p(2), 'ks', 'MarkerSize', 4, 'LineWidth', 1.0);
            end
        end
    end

    beamKey = sprintf('Beam %d', iBeam);
    if ~isKey(usedBeams, beamKey)
        % Use black diamond for beam legend symbol
        usedBeams(beamKey) = plot(ax, NaN, NaN, 'kd', 'MarkerSize', markerSize, 'LineWidth', 1.2);
    end
end

% Legend: beams only
beamFields = keys(usedBeams);
for i = 1:numel(beamFields)
    legendHandles(end+1) = usedBeams(beamFields{i});
    legendLabels{end+1} = beamFields{i};
end

% Geo spot and ray entry legend
legendHandles(end+1) = plot(ax, NaN, NaN, 'kd', 'MarkerSize', markerSize, 'LineWidth', 1.2);
legendLabels{end+1} = 'Geo Spot';
legendHandles(end+1) = plot(ax, NaN, NaN, 'ks', 'MarkerSize', 4, 'LineWidth', 1.0);
legendLabels{end+1} = 'Ray Entry';

legend(ax, legendHandles, legendLabels, 'Location', 'bestoutside', 'FontSize', 9);
xlabel(ax, 'X (voxel index)');
ylabel(ax, 'Y (voxel index)');
title(ax, 'Geometric Spot Positions');
axis(ax, 'equal');
grid(ax, 'on');

if ~isempty(raySpotCubes)
    spotCubes = cat(1, raySpotCubes{:});
    medianSpotCube = median(spotCubes, 1);
else
    medianSpotCube = [NaN NaN NaN];
end
end
