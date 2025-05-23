function matRad_plotEnergyLayerHistogram(ax, stf)
% matRad_plotEnergyLayerHistogram: Plots number of spots per energy layer per beam.
%
% INPUT:
%   ax  - axes handle
%   stf - struct with treatment fields (containing perSpot info)
%
% This function groups spots by energy per beam, and displays a histogram
% of the number of spots per energy layer, per beam, with consistent colors.

if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    return;
end

hold(ax, 'on');
colors = lines(10);  % Up to 10 beams with distinct colors

numBeams = numel(stf);
legendEntries = strings(1, numBeams);

for iBeam = 1:numBeams
    beam = stf(iBeam);
    energyCount = containers.Map('KeyType','double','ValueType','int32');

    for iRay = 1:numel(beam.ray)
        rayInfo = beam.ray(iRay).rayTracerInfo;
        if ~isfield(rayInfo, 'perSpot')
            continue;
        end

        for iSpot = 1:numel(rayInfo.perSpot)
            spot = rayInfo.perSpot(iSpot);
            energy = spot.energy;

            if ~isKey(energyCount, energy)
                energyCount(energy) = 1;
            else
                energyCount(energy) = energyCount(energy) + 1;
            end
        end
    end

    % Sort energies for nice plotting
    energies = cell2mat(energyCount.keys);
    energiesSorted = sort(energies);
    counts = arrayfun(@(e) energyCount(e), energiesSorted);

    % Plot as bar with beam color
    colorIdx = mod(iBeam-1, size(colors,1)) + 1;
    bar(ax, energiesSorted, counts, 'FaceColor', colors(colorIdx,:), 'FaceAlpha', 0.6, 'EdgeColor', 'none');
    legendEntries(iBeam) = "Beam " + string(iBeam);
end

xlabel(ax, 'Energy (MeV)');
ylabel(ax, 'Number of Spots');
title(ax, 'Energy Layer Distribution per Beam');
legend(ax, legendEntries, 'Location', 'bestoutside');
grid(ax, 'on');
end
