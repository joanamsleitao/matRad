function [doseHeavy, stats, wHeavy, heavyMaskThisBeam] = matRad_analyzeSpotsPerBeamStats(iBeam, ct, cst, stf, dij, resultGUI, removalMode, threshold)

if nargin < 7, removalMode = 'relative'; end
if nargin < 8
    threshold = strcmp(removalMode, 'absolute') * 6 + ...
        strcmp(removalMode, 'relative') * 0.15;
end

% --- Instantiate and configure spot remover ---
spotRemover = matRad_SpotRemovalDij(dij, resultGUI.w);
spotRemover.removalMode = removalMode;

switch removalMode
    case 'relative'
        spotRemover.propSpotRemoval.relativeThreshold = threshold;
    case 'absolute'
        spotRemover.propSpotRemoval.absoluteThreshold = threshold;
end

logicalMask = spotRemover.getLogical();
wAll = resultGUI.w;
wHeavy = zeros(size(wAll));
wHeavy(logicalMask) = wAll(logicalMask);

% --- Beam-specific mask ---
beamStartIx = sum(arrayfun(@(b) sum(b.numOfBixelsPerRay), stf(1:iBeam-1))) + 1;
beamEndIx = beamStartIx + sum(stf(iBeam).numOfBixelsPerRay) - 1;
beamMask = false(size(wAll));
beamMask(beamStartIx:beamEndIx) = true;

% --- Final mask of kept spots for this beam ---
heavyMaskThisBeam = logicalMask & beamMask;

% --- Weight stats ---
wBeam = wAll(beamStartIx:beamEndIx);
wTop = wAll(heavyMaskThisBeam);

stats.allWeightsMedian = median(wBeam);
stats.allWeightsMax = max(wBeam);
stats.topWeightsMedian = median(wTop);
stats.topWeightsMax = max(wTop);

% --- Recompute dose ---
resultFiltered = matRad_calcCubes(wHeavy, dij);
doseHeavy = resultFiltered.physicalDose;

% --- Analyze per energy ---
energies = [];
weights = [];

ixCounter = 1;
for iRay = 1:stf(iBeam).numOfRays
    nSpots = stf(iBeam).numOfBixelsPerRay(iRay);
    ray = stf(iBeam).ray(iRay);

    for s = 1:nSpots
        globalIx = beamStartIx + ixCounter - 1;
        if heavyMaskThisBeam(globalIx)
            energies(end+1) = ray.rayTracerInfo.perSpot(s).energy; %#ok<AGROW>
            weights(end+1) = wAll(globalIx); %#ok<AGROW>
        end
        ixCounter = ixCounter + 1;
    end
end

% --- Energy stats ---
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

end
