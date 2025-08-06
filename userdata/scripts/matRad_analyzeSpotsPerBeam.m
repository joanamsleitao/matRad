function [doseHeavy, stats] = matRad_analyzeSpotsPerBeam(iBeam, ct, cst, stf, dij, resultGUI, removalMode, threshold)

% matRad_analyzeSpotsPerBeam - Shows dose from filtered spots of a beam using spotRemover
%
% Inputs:
%   iBeam        - Beam index (e.g. 1)
%   ct, cst      - CT and CST structs
%   stf          - Spot Target File
%   dij          - Dose influence matrix
%   resultGUI    - Result with full w vector
%   removalMode  - 'relative' or 'absolute' (default: 'relative')
%   threshold    - Threshold value for filtering (default: 15% or 6 units)
%
% Outputs:
%   doseHeavy    - Physical dose cube from selected spots
%   stats        - Struct with energy layer analysis and weight stats

if nargin < 7, removalMode = 'relative'; end


% Get global spot index range for current beam
beamStartIx = sum(arrayfun(@(b) sum(b.numOfBixelsPerRay), stf(1:iBeam-1))) + 1;
beamEndIx = beamStartIx + sum(stf(iBeam).numOfBixelsPerRay) - 1;
beamMask = false(size(wAll));
beamMask(beamStartIx:beamEndIx) = true;

% Identify heavy spots in this beam
heavyMaskThisBeam = logicalMask & beamMask;
topSpotIx_global = find(heavyMaskThisBeam);

% Stats
wBeam = wAll(beamStartIx:beamEndIx);
stats.allWeightsMedian = median(wBeam);
stats.allWeightsMax = max(wBeam);

wTop = wAll(topSpotIx_global);
stats.topWeightsMedian = median(wTop);
stats.topWeightsMax = max(wTop);

% Recompute dose
resultGUInew = matRad_calcCubes(wHeavy, dij);
doseHeavy = resultGUInew.physicalDose;

% Plot dose
figure;
matRadJoana_ShowSliceFast(ct, cst, doseHeavy);
title(sprintf('Dose from Filtered Spots (Beam %d, %s threshold = %.2f)', ...
    iBeam, removalMode, threshold));

% % Overlay removed spots (optional visual layer)
% fprintf('→ Plotting removed spots overlay...\n');
% 
% removedSpotMask = beamMask & ~logicalMask;
% removedSpotIx = find(removedSpotMask);
% 
% [xSpots, ySpots] = deal([]);
% ixCounter = 1;
% 
% for iRay = 1:stf(iBeam).numOfRays
%     nSpots = stf(iBeam).numOfBixelsPerRay(iRay);
%     ray = stf(iBeam).ray(iRay);
% 
%     for s = 1:nSpots
%         globalIx = beamStartIx + ixCounter - 1;
%         if ismember(globalIx, removedSpotIx)
%             xSpots(end+1) = ray.rayTracerInfo.perSpot(s).isoPos(1); %#ok<AGROW>
%             ySpots(end+1) = ray.rayTracerInfo.perSpot(s).isoPos(2); %#ok<AGROW>
%         end
%         ixCounter = ixCounter + 1;
%     end
% end
% 
% hold on;
% scatter(xSpots, ySpots, 30, 'rx', 'LineWidth', 1.5); % red X for removed spots
% legend('Dose','Removed spots');


% Analyze energy layers
energies = [];
weights = [];

ixCounter = 1;
for iRay = 1:stf(iBeam).numOfRays
    nSpots = stf(iBeam).numOfBixelsPerRay(iRay);
    ray = stf(iBeam).ray(iRay);

    if isfield(ray.rayTracerInfo, 'perSpot')
        for s = 1:nSpots
            globalIx = beamStartIx + ixCounter - 1;
            if heavyMaskThisBeam(globalIx)
                energies(end+1) = ray.rayTracerInfo.perSpot(s).energy; %#ok<AGROW>
                weights(end+1) = wAll(globalIx); %#ok<AGROW>
            end
            ixCounter = ixCounter + 1;
        end
    else
        ixCounter = ixCounter + nSpots;
    end
end

% Energy layer grouping and stats
[uniqueEnergies, ~, energyLayerIdx] = unique(energies);
counts = accumarray(energyLayerIdx, 1);
sums = accumarray(energyLayerIdx, weights');

[~, idxMostSpots] = max(counts);
[~, idxHeaviest] = max(sums);

stats.energyList = uniqueEnergies;
stats.countsPerEnergy = counts;
stats.weightsPerEnergy = sums;

stats.energyMostSpots.value = uniqueEnergies(idxMostSpots);
stats.energyMostSpots.count = counts(idxMostSpots);
stats.energyMostSpots.weightSum = sums(idxMostSpots);
stats.energyMostSpots.layerIndex = idxMostSpots;

stats.energyHeaviest.value = uniqueEnergies(idxHeaviest);
stats.energyHeaviest.count = counts(idxHeaviest);
stats.energyHeaviest.weightSum = sums(idxHeaviest);
stats.energyHeaviest.layerIndex = idxHeaviest;

% Print summary
fprintf('\nBeam %d: Filtered Spots (%s, threshold = %.2f)\n', iBeam, removalMode, threshold);
fprintf('----------------------------------------------------\n');
fprintf('→ All spots:    median weight = %.4f | max = %.4f\n', ...
    stats.allWeightsMedian, stats.allWeightsMax);
fprintf('→ Heavy spots:  median weight = %.4f | max = %.4f\n', ...
    stats.topWeightsMedian, stats.topWeightsMax);
fprintf('----------------------------------------------------\n');
fprintf('→ Energy layer with MOST heavy spots:\n');
fprintf('   Layer index = %d | Energy = %.2f MeV\n', ...
    stats.energyMostSpots.layerIndex, stats.energyMostSpots.value);
fprintf('   → %d spots, weight sum = %.2f\n', ...
    stats.energyMostSpots.count, stats.energyMostSpots.weightSum);
fprintf('→ Energy layer with HEAVIEST total weight:\n');
fprintf('   Layer index = %d | Energy = %.2f MeV\n', ...
    stats.energyHeaviest.layerIndex, stats.energyHeaviest.value);
fprintf('   → %d spots, weight sum = %.2f\n\n', ...
    stats.energyHeaviest.count, stats.energyHeaviest.weightSum);

end
