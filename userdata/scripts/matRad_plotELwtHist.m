function matRad_plotELwtHist(ax, stf, mode)
% matRad_plotEnergyLayerWeights - Plot total spot weights per energy layer, per beam or ray.
%
% INPUTS:
%   ax   - Axes handle where the bar chart is drawn.
%   stf  - Struct array with scanned beam fields and rayTracerInfo.perSpot data.
%   mode - (Optional) 'perBeam' [default] or 'perRay' to show ray-level contributions per energy.
%
% OUTPUT:
%   A bar chart on the provided axes showing total spot weights per energy.
%
% NOTES:
% - In 'perBeam' mode: plots total weight per energy per beam.
% - In 'perRay' mode: plots stacked ray contributions per energy per beam, using different ray colors.
%
% Example:
%   figure; ax = gca;
%   matRad_plotEnergyLayerWeights(ax, stf, 'perRay');
%
%%

if nargin < 3
    mode = 'perBeam';  % default mode
end

if isempty(ax) || ~isvalid(ax)
    warning('Invalid or missing axes handle. Nothing will be plotted.');
    return;
end

hold(ax, 'on');

numBeams = numel(stf);
legendEntries = strings(1, numBeams);
colors = lines(100); % Enough for many rays or beams

for iBeam = 1:numBeams
    beam = stf(iBeam);

    switch lower(mode)
        case 'perbeam'
            % Aggregate total weight per energy (as before)
            energyWeightMap = containers.Map('KeyType', 'double', 'ValueType', 'double');

            for iRay = 1:numel(beam.ray)
                if ~isfield(beam.ray(iRay), 'rayTracerInfo') || ...
                        ~isfield(beam.ray(iRay).rayTracerInfo, 'perSpot')
                    continue;
                end

                perSpot = beam.ray(iRay).rayTracerInfo.perSpot;

                for iSpot = 1:numel(perSpot)
                    energy = perSpot(iSpot).energy;
                    w = perSpot(iSpot).weight;

                    if ~isKey(energyWeightMap, energy)
                        energyWeightMap(energy) = w;
                    else
                        energyWeightMap(energy) = energyWeightMap(energy) + w;
                    end
                end
            end

            % Sort and plot
            energies = cell2mat(energyWeightMap.keys);
            energiesSorted = sort(energies);
            weights = arrayfun(@(e) energyWeightMap(e), energiesSorted);
            colorIdx = mod(iBeam-1, size(colors,1)) + 1;

            bar(ax, energiesSorted, weights, ...
                'FaceColor', colors(colorIdx,:), 'FaceAlpha', 0.6, 'EdgeColor', 'none');
            legendEntries(iBeam) = "Beam " + string(iBeam);

        case 'perray'
            % Aggregate weight per energy per ray
            rayCount = numel(beam.ray);
            rayColors = jet(rayCount);
            energyList = [];

            % First, collect all unique energies across rays
            for iRay = 1:rayCount
                if isfield(beam.ray(iRay), 'rayTracerInfo') && ...
                        isfield(beam.ray(iRay).rayTracerInfo, 'perSpot')
                    energyList = [energyList, [beam.ray(iRay).rayTracerInfo.perSpot.energy]];
                end
            end
            uniqueEnergies = unique(energyList);
            nE = numel(uniqueEnergies);
            energyToIndex = containers.Map(uniqueEnergies, 1:nE);

            % Initialize matrix: [nEnergies x nRays]
            weightMatrix = zeros(nE, rayCount);

            for iRay = 1:rayCount
                if ~isfield(beam.ray(iRay), 'rayTracerInfo') || ...
                        ~isfield(beam.ray(iRay).rayTracerInfo, 'perSpot')
                    continue;
                end

                perSpot = beam.ray(iRay).rayTracerInfo.perSpot;
                for iSpot = 1:numel(perSpot)
                    energy = perSpot(iSpot).energy;
                    w = perSpot(iSpot).weight;
                    rowIdx = energyToIndex(energy);
                    weightMatrix(rowIdx, iRay) = weightMatrix(rowIdx, iRay) + w;
                end
            end

            % Stacked bar chart per ray
            b = bar(ax, uniqueEnergies, weightMatrix, 'stacked');
            for iRay = 1:rayCount
                b(iRay).FaceColor = rayColors(iRay,:);
                b(iRay).EdgeColor = 'none';
                b(iRay).DisplayName = sprintf('Beam %d - Ray %d', iBeam, iRay);
            end
            legendEntries(iBeam) = "Beam " + string(iBeam);

        otherwise
            error('Unknown mode: %s. Use "perBeam" or "perRay".', mode);
    end
end

xlabel(ax, 'Energy (MeV)');
ylabel(ax, 'Total Normalized Weight');
title(ax, sprintf('Energy Layer Weight Distribution (%s)', mode));
if strcmpi(mode, 'perray')
    legend(ax, 'show', 'Location', 'bestoutside');
else
    legend(ax, legendEntries, 'Location', 'bestoutside');
end
grid(ax, 'on');
end
