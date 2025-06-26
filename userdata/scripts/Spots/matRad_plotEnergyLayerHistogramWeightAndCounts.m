function matRad_plotEnergyLayerHistogramWeightAndCounts(ax, stf)
% matRad_plotEnergyLayerHistogramWeightAndCounts
% Shows stacked histogram of total (unnormalized) spot weights per energy layer (per ray),
% with a blue line showing total number of spots per energy (across all beams/rays).
%
% INPUTS:
%   ax  - Axes handle
%   stf - Struct with beam(i).ray(j).rayTracerInfo.perSpot
%
% USAGE:
%   figure; ax = gca;
%   matRad_plotEnergyLayerHistogramWeightAndCounts(ax, stf);

if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    return;
end

hold(ax, 'on');
numBeams = numel(stf);
rayLegendEntries = {};
allEnergies = [];

% --- Gather all used energies globally
for iBeam = 1:numBeams
    for iRay = 1:numel(stf(iBeam).ray)
        if isfield(stf(iBeam).ray(iRay).rayTracerInfo, 'perSpot')
            allEnergies = [allEnergies, [stf(iBeam).ray(iRay).rayTracerInfo.perSpot.energy]];
        end
    end
end

globalEnergies = unique(allEnergies);
numEnergies = numel(globalEnergies);

% --- Set up dual y-axis
yyaxis(ax, 'left');
ylabel(ax, 'Total Spot Weight (unnormalized)');
ax.YColor = [0 0 0];

yyaxis(ax, 'right');
ylabel(ax, 'Number of Spots');
ax.YColor = [0 0 0];

yyaxis(ax, 'left');  % Plot histogram bars on left axis

barOffset = 0;  % Optional horizontal offset per beam
totalSpotCounts = zeros(1, numEnergies);  % For right-y axis line plot

% --- Loop through beams
for iBeam = 1:numBeams
    beam = stf(iBeam);
    numRays = numel(beam.ray);
    rayColors = jet(numRays);

    rayWeights = zeros(numRays, numEnergies);

    % --- Accumulate weights and counts per ray and energy
    for iRay = 1:numRays
        if ~isfield(beam.ray(iRay).rayTracerInfo, 'perSpot')
            continue;
        end
        spots = beam.ray(iRay).rayTracerInfo.perSpot;
        for iSpot = 1:numel(spots)
            spot = spots(iSpot);
            eIdx = find(globalEnergies == spot.energy);
            rayWeights(iRay, eIdx) = rayWeights(iRay, eIdx) + spot.weight;
            totalSpotCounts(eIdx) = totalSpotCounts(eIdx) + 1;
        end
    end

    % --- Stack histogram bars per ray using bar with 'stacked' option
    dataToPlot = rayWeights'; % transpose so rows=energies, columns=rays
    h = bar(ax, globalEnergies + barOffset, dataToPlot, 'stacked', 'BarWidth', 0.8);

    % Color each ray's bar segment and add legend entry
    for iRay = 1:numRays
        h(iRay).FaceColor = rayColors(iRay,:);
        h(iRay).EdgeColor = 'none';
        rayLegendEntries{end+1} = sprintf('Beam %d - Ray %d', iBeam, iRay);
    end

    barOffset = barOffset + 0.5;  % Shift bars per beam horizontally (optional)
end

% --- Overlay spot count line (blue) on right axis
yyaxis(ax, 'right');
plot(ax, globalEnergies, totalSpotCounts, '-o', ...
    'Color', [0 0.447 0.741], 'LineWidth', 1.5, ...
    'DisplayName', 'Total Spot Count');

% --- Final plot setup
xlabel(ax, 'Energy (MeV)');
xticks(ax, globalEnergies);
xticklabels(ax, string(globalEnergies));
title(ax, 'Energy Layer Histogram: Spot Weight (stacked bars) and Count (line)');
legend(ax, rayLegendEntries, 'Location', 'eastoutside');
grid(ax, 'on');
end
