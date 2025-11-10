function matRad_plotELhistCW(ax, stf, showLines)
% matRad_plotEnergyLayerHistogramCountsAndWeights
% Stacked histogram of spot *counts* per energy and bar plot of *weights* (unnormalized).
% Optional overlay of normalized ray weights as lines.
%
% INPUTS:
%   ax        - Axes handle
%   stf       - Struct with .ray.rayTracerInfo.perSpot
%   showLines - Boolean to plot normalized weight lines (optional)
%
% USAGE:
%   figure; ax = gca;
%   matRad_plotEnergyLayerHistogramCountsAndWeights(ax, stf, true);

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
allEnergies = [];

% First pass: collect all energies and count total rays
totalRays = 0;
for iBeam = 1:numBeams
    for iRay = 1:numel(stf(iBeam).ray)
        if isfield(stf(iBeam).ray(iRay).rayTracerInfo, 'perSpot')
            allEnergies = [allEnergies, [stf(iBeam).ray(iRay).rayTracerInfo.perSpot.energy]];
            totalRays = totalRays + 1;
        end
    end
end
globalEnergies = unique(allEnergies);
numGlobalEnergies = numel(globalEnergies);

% Allocate matrix
counts = zeros(totalRays, numGlobalEnergies);
weights = zeros(totalRays, numGlobalEnergies);
rayLabels = strings(1, totalRays);

% Second pass: fill in matrices
rayIdx = 0;
for iBeam = 1:numBeams
    for iRay = 1:numel(stf(iBeam).ray)
        rayInfo = stf(iBeam).ray(iRay).rayTracerInfo;
        if ~isfield(rayInfo, 'perSpot')
            continue;
        end
        rayIdx = rayIdx + 1;
        rayLabels(rayIdx) = sprintf('Beam %d - Ray %d', iBeam, iRay);

        for iSpot = 1:numel(rayInfo.perSpot)
            spot = rayInfo.perSpot(iSpot);
            eIdx = find(globalEnergies == spot.energy);
            counts(rayIdx, eIdx) = counts(rayIdx, eIdx) + 1;
            weights(rayIdx, eIdx) = weights(rayIdx, eIdx) + spot.weight;
        end
    end
end

% Create colormap
rayColors = jet(totalRays);

% === Left Y-axis: Counts (stacked bars) ===
yyaxis(ax, 'left');
bar(ax, globalEnergies, counts', 'stacked', 'BarWidth', 0.8);
for i = 1:totalRays
    h = findobj(ax, 'Type', 'Bar');
    if ~isempty(h)
        set(h(i), 'FaceColor', rayColors(i,:), 'EdgeColor', 'none');
    end
end
ylabel(ax, 'Number of Spots');
ax.YColor = [0 0 0];

% === Right Y-axis: Total weight (bar plot per energy) ===
yyaxis(ax, 'right');
totalWeightPerEnergy = sum(weights, 1);
bar(ax, globalEnergies, totalWeightPerEnergy, ...
    'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', [0.3 0.3 0.3]);
ylabel(ax, 'Total Weight (unnormalized)');
ax.YColor = [0 0 0];

% === Optional: overlay per-ray normalized weights ===
if showLines
    for i = 1:totalRays
        w = weights(i, :);
        if max(w) > 0
            normW = w / max(w);
            plot(ax, globalEnergies, normW, '-', ...
                'Color', rayColors(i,:), 'LineWidth', 1.2, ...
                'DisplayName', rayLabels(i) + " (norm w)");
        end
    end
end

% === Final touches ===
xlabel(ax, 'Energy (MeV)');
xticks(ax, globalEnergies);
xticklabels(ax, string(globalEnergies));
title(ax, 'Energy Layer Histogram (Spot Count + Weight per Ray)');
legend(ax, rayLabels, 'Location', 'eastoutside');
grid(ax, 'on');
end
