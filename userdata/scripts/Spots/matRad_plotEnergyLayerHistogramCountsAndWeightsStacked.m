function matRad_plotEnergyLayerHistogramCountsAndWeightsStacked(ax, stf, showLines)
% matRad_plotEnergyLayerHistogramCountsAndWeightsStacked
% Stacked histogram of spot counts per energy layer per beam with optional
% per-ray normalized weight overlay. Ray colors use 'jet' colormap.
%
% INPUTS:
%   ax        - Axes handle
%   stf       - Struct array with beam(i).ray(j).rayTracerInfo.perSpot
%   showLines - Boolean: overlay per-ray normalized weight curves
%
% USAGE:
%   figure; ax = gca;
%   matRad_plotEnergyLayerHistogramCountsAndWeightsStacked(ax, stf, true);

if nargin < 3
    showLines = true;
end

if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    return;
end

hold(ax, 'on');
numBeams = numel(stf);
rayLegendEntries = {};
allEnergiesGlobal = [];

% Collect all unique energies across beams
for iBeam = 1:numBeams
    beam = stf(iBeam);
    for iRay = 1:numel(beam.ray)
        if isfield(beam.ray(iRay).rayTracerInfo, 'perSpot')
            allEnergiesGlobal = [allEnergiesGlobal, [beam.ray(iRay).rayTracerInfo.perSpot.energy]];
        end
    end
end

globalEnergies = unique(allEnergiesGlobal);
numGlobalEnergies = numel(globalEnergies);

yyaxis(ax, 'left');
ylabel(ax, 'Number of Spots');
ax.YColor = [0 0 0];

yyaxis(ax, 'right');
ylabel(ax, 'Normalized Ray Weight');
ax.YColor = [0 0 0];

yyaxis(ax, 'left'); % Back to left for bars

barOffset = 0;

for iBeam = 1:numBeams
    beam = stf(iBeam);
    numRays = numel(beam.ray);
    
    % Create color map for this beam's rays
    rayColors = jet(numRays);
    
    % Initialize count and weight arrays
    counts = zeros(numRays, numGlobalEnergies);
    weights = zeros(numRays, numGlobalEnergies);

    % Fill in counts and weights
    for iRay = 1:numRays
        ray = beam.ray(iRay);
        if ~isfield(ray.rayTracerInfo, 'perSpot')
            continue;
        end
        for iSpot = 1:numel(ray.rayTracerInfo.perSpot)
            spot = ray.rayTracerInfo.perSpot(iSpot);
            eIdx = find(globalEnergies == spot.energy);
            counts(iRay, eIdx) = counts(iRay, eIdx) + 1;
            weights(iRay, eIdx) = weights(iRay, eIdx) + spot.weight;
        end
    end

    % Plot stacked bars per ray
    for iRay = 1:numRays
        bar(ax, globalEnergies + barOffset, counts(iRay,:), ...
            'FaceColor', rayColors(iRay,:), 'EdgeColor', 'none', 'BarWidth', 0.8);
        rayLegendEntries{end+1} = sprintf('Beam %d - Ray %d', iBeam, iRay);
    end

    % Overlay per-ray normalized weight lines
    if showLines
        yyaxis(ax, 'right');
        for iRay = 1:numRays
            w = weights(iRay,:);
            if max(w) > 0
                normW = w / max(w);  % Normalize this ray's weights
                plot(ax, globalEnergies + barOffset, normW, '-', ...
                    'Color', rayColors(iRay,:), 'LineWidth', 1.5, ...
                    'DisplayName', sprintf('Beam %d - Ray %d (w)', iBeam, iRay));
            end
        end
        yyaxis(ax, 'left');
    end

    barOffset = barOffset + 0.5;
end

xlabel(ax, 'Energy (MeV)');
xticks(ax, globalEnergies);
xticklabels(ax, string(globalEnergies));
title(ax, 'Energy Layer Histogram (Spot Count + Normalized Ray Weight)');
legend(ax, rayLegendEntries, 'Location', 'eastoutside');
grid(ax, 'on');
end
