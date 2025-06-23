function matRad_plotEnergyLayerHistogramCountsAndWeightsStacked(ax, stf, showLines)
% matRad_plotEnergyLayerHistogramCountsAndWeightsStacked
% Plot stacked bar chart of spot counts per energy layer per beam,
% with each ray shown as a separate stack section. Optionally overlay
% normalized total weight as lines.
%
% INPUTS:
%   ax        - Axes handle
%   stf       - Struct array (1xN beams), each with ray(i).rayTracerInfo.perSpot
%   showLines - Boolean (true to overlay normalized total weight)
%
% USAGE:
%   figure; ax = gca;
%   matRad_plotEnergyLayerHistogramCountsAndWeightsStacked(ax, stf, true);
%
% OUTPUT:
%   Combined bar and line plot (per energy), stacked per ray, with legend.

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
rayColors = lines(100); % Large enough for many rays

yyaxis(ax, 'left');
ylabel(ax, 'Number of Spots');
ax.YColor = [0 0 0];  % black ticks

yyaxis(ax, 'right');
ylabel(ax, 'Normalized Total Weight');
ax.YColor = [0 0 0];

% Start back on the left for bars
yyaxis(ax, 'left');

% Offset for stacked bars
barOffset = 0;

for iBeam = 1:numBeams
    beam = stf(iBeam);
    numRays = numel(beam.ray);
    
    % Collect all energies used in this beam
    allEnergies = [];
    for iRay = 1:numRays
        if isfield(beam.ray(iRay).rayTracerInfo, 'perSpot')
            energies = [beam.ray(iRay).rayTracerInfo.perSpot.energy];
            allEnergies = [allEnergies, energies];
        end
    end
    uniqueEnergies = unique(allEnergies);
    numEnergies = numel(uniqueEnergies);
    
    % Initialize per-ray count and weight matrices
    counts = zeros(numRays, numEnergies);
    weights = zeros(1, numEnergies);

    for iRay = 1:numRays
        ray = beam.ray(iRay);
        if ~isfield(ray.rayTracerInfo, 'perSpot')
            continue;
        end

        for iSpot = 1:numel(ray.rayTracerInfo.perSpot)
            spot = ray.rayTracerInfo.perSpot(iSpot);
            eIdx = find(uniqueEnergies == spot.energy);
            counts(iRay, eIdx) = counts(iRay, eIdx) + 1;
            weights(eIdx) = weights(eIdx) + spot.weight;
        end
    end

    % Normalize weights for this beam
    normWeights = weights / max(weights + eps);

    % Assign ray colors from colormap
    rayColorIdx = 1;

    % Plot stacked bars per ray
    for iRay = 1:numRays
        b = bar(ax, uniqueEnergies + barOffset, counts(iRay,:), ...
            'FaceColor', rayColors(rayColorIdx,:), 'EdgeColor', 'none', 'BarWidth', 0.8);
        rayLegendEntries{end+1} = sprintf('Beam %d - Ray %d', iBeam, iRay);
        rayColorIdx = rayColorIdx + 1;
    end

    % Overlay line (optional)
    if showLines
        yyaxis(ax, 'right');
        plot(ax, uniqueEnergies + barOffset, normWeights, '-', ...
            'Color', [0 0 0], 'LineWidth', 2, ...
            'DisplayName', sprintf('Beam %d - Total Weight', iBeam));
        yyaxis(ax, 'left');
    end

    barOffset = barOffset + 0.5; % Slight shift for each beam
end

xlabel(ax, 'Energy (MeV)');
title(ax, 'Energy Layer Histogram: Ray-wise Spot Count (stacked) & Weights (lines)');
legend(ax, rayLegendEntries, 'Location', 'eastoutside');
grid(ax, 'on');

end
