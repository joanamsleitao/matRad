function matRad_plotELW(ax, ct, stf, markerSize, machine, showRayTracing, beamSelection)
% matRad_plotEnergyLayerPerWeight - Visualize energy layers by plotting the most weighted spot per energy level per beam.
%
% This function plots, for each selected beam in a proton (or ion) therapy plan,
% the spot with the highest weight for each energy layer. The spots are
% color-coded by energy using a predefined color map, and marker shapes
% differentiate the beams. Optionally, it can also display the ray paths
% used during dose calculation.
%
% INPUTS:
%   ax              - Axes handle where the plot will be drawn.
%   ct              - CT struct used for coordinate transformations.
%   stf             - Struct containing the scanned beam treatment plan.
%   markerSize      - (Optional) Base size of the spot markers. Default is 6.
%   machine         - (Optional) Machine struct. If not provided, loaded from stf.
%   showRayTracing  - (Optional) Boolean to plot ray paths. Default is false.
%   beamSelection   - (Optional) Vector of beam indices to plot. Default: all beams.
%
% OUTPUT:
%   A plot is rendered to the specified axes, displaying the
%   most-weighted spot per energy layer, color-coded by energy and
%   shaped by beam. A legend shows both energy and beam information.

if nargin < 4 || isempty(markerSize)
    markerSize = 6;
end
if nargin < 5 || isempty(machine)
    machineFileName = append(stf(1).radiationMode, '_', stf(1).machine);
    machine = load(machineFileName);
    machine = machine.machine;
end
if nargin < 6 || isempty(showRayTracing)
    showRayTracing = false;
end
if nargin < 7 || isempty(beamSelection)
    beamSelection = 1:numel(stf);
end

% Get color map for energies
energyColorMap = matRad_getMachineEnergyColorMap(stf);
shapes = {'o', '+', 's', '^', 'v', 'x', 'd', 'p', 'h', '*'};
hold(ax, 'on');

usedEnergies = struct();
usedBeams = struct();

for iBeamIdx = 1:numel(beamSelection)
    iBeam = beamSelection(iBeamIdx);
    shape = shapes{mod(iBeam-1, numel(shapes)) + 1};
    rayList = stf(iBeam).ray;
    energySpots = struct();

    for iRay = 1:numel(rayList)
        tracer = rayList(iRay).rayTracerInfo;

        if showRayTracing && isfield(tracer, 'ix')
            for idx = 1:numel(tracer.ix)
                p = matRad_world2cubeIndex(matRad_cubeIndex2worldCoords(tracer.ix(idx), ct), ct);
                plot(ax, p(2), p(1), 'b.', 'MarkerSize', 1);
            end
        end

        for iSpot = 1:numel(tracer.perSpot)
            spot = tracer.perSpot(iSpot);
            if ~isfield(spot, 'spotCube')
                continue;
            end
            energy = spot.energy;
            key = strrep(sprintf('e%.4f', energy), ".", "_");

            if ~isfield(energySpots, key)
                energySpots.(key).positions = [];
                energySpots.(key).weights = [];
                energySpots.(key).energy = energy;
            end

            energySpots.(key).positions(end+1,:) = spot.spotCube;
            energySpots.(key).weights(end+1) = spot.weight;
        end
    end

    energyKeys = fieldnames(energySpots);
    for i = 1:numel(energyKeys)
        key = energyKeys{i};
        e = energySpots.(key).energy;
        spots = energySpots.(key).positions;
        weights = energySpots.(key).weights;

        [~, maxIdx] = max(weights);
        repSpot = spots(maxIdx, :);
        repWeight = weights(maxIdx);
        scaledMarkerSize = markerSize + 10 * repWeight;

        if isKey(energyColorMap, e)
            c = energyColorMap(e);
        else
            c = [0.5, 0.5, 0.5]; % fallback color
        end

        plot(ax, repSpot(1), repSpot(2), shape, ...
            'Color', c, 'MarkerSize', markerSize, 'LineWidth', 1.5);

        energyKey = strrep(sprintf('e%.4f', e), ".", "_");
        if ~isfield(usedEnergies, energyKey)
            usedEnergies.(energyKey) = plot(ax, NaN, NaN, 'o', 'Color', c, ...
                'MarkerFaceColor', c, 'MarkerSize', 8, 'LineWidth', 1.5);
        end
    end

    beamKey = sprintf('beam%d', iBeam);
    if ~isfield(usedBeams, beamKey)
        usedBeams.(beamKey) = plot(ax, NaN, NaN, shape, 'Color', 'k', ...
            'MarkerSize', 8, 'LineWidth', 1.5);
    end
end

% Build legend
energyFields = fieldnames(usedEnergies);
energyVals = cellfun(@(f) str2double(strrep(strrep(f, 'e', ''), '_', '.')), energyFields);
[~, sortedIdx] = sort(energyVals);
sortedEnergyFields = energyFields(sortedIdx);
beamFields = fieldnames(usedBeams);

legendLabels = {};
legendHandles = [];

for i = 1:numel(sortedEnergyFields)
    energyStr = strrep(strrep(sortedEnergyFields{i}, 'e', ''), '_', '.');
    legendLabels{end+1} = ['Energy ' energyStr];
    legendHandles(end+1) = usedEnergies.(sortedEnergyFields{i});
end
for i = 1:numel(beamFields)
    legendLabels{end+1} = ['Beam ' strrep(beamFields{i}, 'beam', '')];
    legendHandles(end+1) = usedBeams.(beamFields{i});
end

legend(ax, legendHandles, legendLabels, 'Location', 'bestoutside', 'FontSize', 9);
title(ax, 'Energy Layer Visualization (Most Weighted Spots)');
xlabel(ax, 'X (voxel index)');
ylabel(ax, 'Y (voxel index)');
axis(ax, 'equal');
grid(ax, 'on');

% Add weight scale bar
addWeightScaleBar(ax, markerSize);

end

function addWeightScaleBar(ax, baseSize)
    axPos = get(ax, 'Position');
    insetAx = axes('Position', [axPos(1)+0.05, axPos(2)+axPos(4)-0.15, 0.15, 0.15]);
    hold(insetAx, 'on'); box(insetAx, 'on');

    weights = [0.2, 0.5, 1.0];
    for i = 1:length(weights)
        sz = baseSize + 10 * weights(i);
        plot(insetAx, i, 1, 'ko', 'MarkerSize', sz, 'MarkerFaceColor', 'k');
        text(insetAx, i, 0.6, sprintf('w=%.1f', weights(i)), 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
    axis(insetAx, [0.5, length(weights)+0.5, 0.4, 1.6]);
    axis(insetAx, 'off');
    title(insetAx, 'Weight scale');
end
