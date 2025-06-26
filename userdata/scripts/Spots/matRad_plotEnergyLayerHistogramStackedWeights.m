function matRad_plotEnergyLayerHistogramStackedWeights(ax, stf)
% Plot a stacked histogram of unnormalized spot weights per energy.
% Stacks all rays (from all beams) with unique ray colors.
%
% INPUT:
%   ax  - Axes handle for plotting
%   stf - Struct of scanned beam treatment fields (with .ray and .perSpot)

if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    return;
end

hold(ax, 'on');

% 1. Collect all energies and count rays
allEnergies = [];
numTotalRays = 0;
for iBeam = 1:numel(stf)
    for iRay = 1:numel(stf(iBeam).ray)
        if isfield(stf(iBeam).ray(iRay).rayTracerInfo, 'perSpot')
            allEnergies = [allEnergies, [stf(iBeam).ray(iRay).rayTracerInfo.perSpot.energy]];
            numTotalRays = numTotalRays + 1;
        end
    end
end
uniqueEnergies = unique(allEnergies);
numEnergies = numel(uniqueEnergies);

% 2. Allocate weight matrix (rays × energies)
weightMatrix = zeros(numTotalRays, numEnergies);
rayLabels = strings(1, numTotalRays);

% 3. Fill weight matrix
rayCounter = 0;
for iBeam = 1:numel(stf)
    for iRay = 1:numel(stf(iBeam).ray)
        rayInfo = stf(iBeam).ray(iRay).rayTracerInfo;
        if ~isfield(rayInfo, 'perSpot')
            continue;
        end
        rayCounter = rayCounter + 1;
        rayLabels(rayCounter) = sprintf('Beam %d - Ray %d', iBeam, iRay);

        for iSpot = 1:numel(rayInfo.perSpot)
            spot = rayInfo.perSpot(iSpot);
            eIdx = find(uniqueEnergies == spot.energy);
            weightMatrix(rayCounter, eIdx) = weightMatrix(rayCounter, eIdx) + spot.weight;
        end
    end
end

% 4. Plot stacked bar chart
colors = jet(numTotalRays);
bar(ax, uniqueEnergies, weightMatrix', 'stacked', 'BarWidth', 0.9);
for i = 1:numTotalRays
    h = findobj(ax, 'Type', 'Bar');
    if ~isempty(h)
        set(h(i), 'FaceColor', colors(i,:), 'EdgeColor', 'none');
    end
end

xlabel(ax, 'Energy (MeV)');
ylabel(ax, 'Total Spot Weight');
title(ax, 'Stacked Spot Weight Histogram (per Ray, per Energy)');
xticks(ax, uniqueEnergies);
xticklabels(ax, string(uniqueEnergies));
legend(ax, rayLabels, 'Location', 'eastoutside');
grid(ax, 'on');
end
