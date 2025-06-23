function matRad_plotEnergyLayerHistogramCountsAndWeights(ax, stf)
% matRad_plotEnergyLayerHistogramCountsAndWeights - Plot histogram of spot counts and weights per energy layer, per beam.
%
% This function visualizes the number of proton/ion therapy spots and their
% corresponding total weights per energy layer. Spot counts are shown as bars
% and weights as lines on a shared x-axis (energy), but separate y-axes.
%
% INPUTS:
%   ax  - Axes handle where the histogram will be drawn.
%   stf - Struct array with fields .ray and rayTracerInfo.perSpot, each spot
%         containing .energy and .weight.
%
% Example:
%   figure;
%   ax = gca;
%   matRad_plotEnergyLayerHistogramCountsAndWeights(ax, stf);
%
%%

if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    return;
end

hold(ax, 'on');
colors = lines(10);  % up to 10 beam colors
numBeams = numel(stf);
legendEntries = strings(1, numBeams);

yyaxis(ax, 'left');
ylabel(ax, 'Number of Spots');
ax.YColor = [0 0 0];  % black axis ticks

yyaxis(ax, 'right');
ylabel(ax, 'Total Normalized Weight');
ax.YColor = [0 0 0];

yyaxis(ax, 'left'); % back to left for the bars

for iBeam = 1:numBeams
    beam = stf(iBeam);
    energyCount = containers.Map('KeyType','double','ValueType','int32');
    energyWeight = containers.Map('KeyType','double','ValueType','double');

    for iRay = 1:numel(beam.ray)
        rayInfo = beam.ray(iRay).rayTracerInfo;
        if ~isfield(rayInfo, 'perSpot')
            continue;
        end

        for iSpot = 1:numel(rayInfo.perSpot)
            spot = rayInfo.perSpot(iSpot);
            E = spot.energy;
            w = spot.weight;

            % Count occurrences
            if ~isKey(energyCount, E)
                energyCount(E) = 1;
                energyWeight(E) = w;
            else
                energyCount(E) = energyCount(E) + 1;
                energyWeight(E) = energyWeight(E) + w;
            end
        end
    end

    % Sort energies
    energies = cell2mat(energyCount.keys);
    energiesSorted = sort(energies);
    counts = arrayfun(@(e) energyCount(e), energiesSorted);
    totalWeight = arrayfun(@(e) energyWeight(e), energiesSorted);
    normWeight = totalWeight / max(totalWeight);  % normalize weights

    colorIdx = mod(iBeam-1, size(colors,1)) + 1;
    beamColor = colors(colorIdx,:);

    % Plot spot count (bars)
    yyaxis(ax, 'left');
    bar(ax, energiesSorted, counts, 'FaceColor', beamColor, ...
        'FaceAlpha', 0.5, 'EdgeColor', 'none');

    % Plot normalized weight (line)
    yyaxis(ax, 'right');
    plot(ax, energiesSorted, normWeight, '-', ...
        'Color', beamColor, 'LineWidth', 2, 'DisplayName', ['Beam ' num2str(iBeam)]);

    legendEntries(iBeam) = "Beam " + string(iBeam);
end

xlabel(ax, 'Energy (MeV)');
title(ax, 'Energy Layer Histogram: Spot Counts and Weights');
legend(ax, legendEntries, 'Location', 'bestoutside');
grid(ax, 'on');
end
