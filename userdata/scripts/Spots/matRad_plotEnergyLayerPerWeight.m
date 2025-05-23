function matRad_plotEnergyLayerPerWeight(ax, ct, stf, markerSize, machine, showRayTracing)
% matRad_plotEnergyLayerPerWeight - Visualize energy layers by plotting the most weighted spot per energy level per beam.
%
% This function plots, for each beam in a proton (or ion) therapy plan,
% the spot with the highest weight for each energy layer. The spots are
% color-coded by energy using a predefined color map, and marker shapes
% differentiate the beams. Optionally, it can also display the ray paths
% used during dose calculation.
%
% INPUTS:
%   ax            - Axes handle where the plot will be drawn.
%   ct            - CT struct used for coordinate transformations.
%   stf           - Struct containing the scanned beam treatment plan (with .ray and .rayTracerInfo fields).
%   markerSize    - (Optional) Size of the spot markers. Default is 6.
%   machine       - (Optional) Machine struct defining energy layers and settings.
%                   If not provided, the function attempts to load it using stf.machine and stf.radiationMode.
%   showRayTracing - (Optional) Boolean flag to plot ray paths used for dose computation. Default is false.
%
% OUTPUT:
%   A plot is rendered to the specified axes `ax`, displaying the
%   most-weighted spot per energy layer, color-coded by energy and
%   shaped by beam. The legend is automatically sorted in increasing
%   order of energy.
%
% NOTE:
% - Each spot is plotted using CT voxel indices (in-plane only).
% - Legend entries are organized first by increasing energy, then by beam.
%
% Example usage:
%   figure;
%   ax = gca;
%   matRad_plotEnergyLayerPerWeight(ax, ct, stf);
%
%%
% Load machine if not provided
if nargin < 5 || isempty(machine)
    machineFileName = append(stf.radiationMode, '_', stf.machine);
    machine = load(machineFileName);
    machine = machine.machine;
end

if ~exist('markerSize','var') || isempty(markerSize)
    markerSize = 6;
end
if ~exist('showRayTracing','var') || isempty(showRayTracing)
    showRayTracing = false;
end

%%
% % Energy list for machine (e.g., protons_generic)
% machineEnergies = [31.7289801158557;36.7985653919357;41.3788233252735;... % shorten if needed
%                    234.958213631876;236.107017981299];
machineEnergies = [machine.data(:).energy];
energyColorMap = matRad_getMachineEnergyColorMap(stf);

shapes = {'o', '+', 's', '^', 'v', 'x', 'd', 'p', 'h', '*'};
numBeams = numel(stf);
hold(ax, 'on');

usedEnergies = struct();
usedBeams = struct();

for iBeam = 1:numBeams
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
        repSpot = spots(maxIdx, :);  % most weighted

        if isKey(energyColorMap, e)
            c = energyColorMap(e);
        else
            c = [0.5,0.5,0.5]; % fallback gray
        end

        plot(ax, repSpot(1), repSpot(2), shape, ...
            'Color', c, 'MarkerSize', markerSize, 'LineWidth', 1.5);

        % Legend handles
        energyKey = strrep(sprintf('e%.4f', e), ".", "_");
        if ~isfield(usedEnergies, energyKey)
            usedEnergies.(energyKey) = plot(ax, NaN, NaN, 'o', ...
                'Color', c, 'MarkerFaceColor', c, ...
                'MarkerSize', 8, 'LineWidth', 1.5);
        end
    end

    beamKey = sprintf('beam%d', iBeam);
    if ~isfield(usedBeams, beamKey)
        usedBeams.(beamKey) = plot(ax, NaN, NaN, shape, ...
            'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.5);
    end
end

% Sort energy keys numerically
energyFields = fieldnames(usedEnergies);
energyVals = cellfun(@(f) str2double(erase(f, 'e')), energyFields);
[~, sortedIdx] = sort(energyVals);
sortedEnergyFields = energyFields(sortedIdx);

beamFields = fieldnames(usedBeams);

% Build legend
legendLabels = {};
legendHandles = [];

for i = 1:numel(sortedEnergyFields)
    energyStr = erase(sortedEnergyFields{i}, 'e');
    energyStr = strrep(energyStr, '_', '.');
    legendLabels{end+1} = ['Energy ' energyStr];
    legendHandles(end+1) = usedEnergies.(sortedEnergyFields{i});
end
%    energyStr = erase(strrep(sortedEnergyFields{i}, ".", "_"), 'e');

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
end
