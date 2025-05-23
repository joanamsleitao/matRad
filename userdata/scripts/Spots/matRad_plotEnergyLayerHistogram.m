function matRad_plotEnergyLayerHistogram(ax, stf)
% matRad_plotEnergyLayerHistogram - Plot a histogram of spot counts per energy layer, per beam.
%
% This function visualizes the number of proton (or ion) therapy spots
% delivered at each energy layer, separated by beam. It is useful for
% understanding how energy layers are distributed across multiple fields.
%
% INPUTS:
%   ax  - Axes handle where the histogram will be drawn.
%   stf - Struct array containing scanned beam treatment fields. Each field
%         should contain .ray and .rayTracerInfo.perSpot with energy values.
%
% OUTPUT:
%   A histogram is drawn on the provided axes. Each beam is plotted with a
%   different color, showing how many spots correspond to each energy value.
%
% NOTES:
% - The histogram groups spot counts by energy per beam.
% - Each beam is assigned a color from MATLAB’s `lines` colormap.
% - Energies are sorted numerically along the x-axis.
%
% Example usage:
%   figure;
%   ax = gca;
%   matRad_plotEnergyLayerHistogram(ax, stf);
%
%%
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