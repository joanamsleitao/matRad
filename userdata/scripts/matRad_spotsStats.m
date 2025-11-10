function stats = matRad_spotsStats(stf, resultGUI, iBeam, print)
% MATRAD_COMPUTESPOTSTATS - Computes weight and energy layer statistics per beam
%
% Syntax:  stats = matRad_computeSpotStats(stf, resultGUI, iBeam, print)
%
% Inputs:
%   stf       - Spot scanning field structure (struct)
%   resultGUI - matRad result structure (contains .w) (struct)
%   iBeam     - Optional beam index to analyze (integer). If omitted, analyze all beams.
%   print     - Optional flag to print summary (logical). Default: false.
%
% Outputs:
%   stats     - Struct array containing weight and energy layer statistics for each beam
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_analyzeSpotsPerBeam, matRad_plotEnergyLayerHistogram
%

    if nargin < 3 || isempty(iBeam)
        beamIndices = 1:numel(stf);
    else
        beamIndices = iBeam;
    end

    if nargin < 4 || isempty(print)
        print = false;
    end

    % Global weight vector
    wAll = resultGUI.w;

    % Preallocate output
    stats = repmat(struct(), 1, numel(beamIndices));

    % Global bixel offset counter
    globalOffset = 0;

    for b = 1:numel(stf)
        stf(b).globalStartIx = globalOffset + 1;
        globalOffset = globalOffset + sum(stf(b).numOfBixelsPerRay);
        stf(b).globalEndIx = globalOffset;
    end

    % Analyze each selected beam
    for idx = 1:numel(beamIndices)
        b = beamIndices(idx);
        beam = stf(b);
        beamStartIx = beam.globalStartIx;
        beamEndIx = beam.globalEndIx;

        wBeam = wAll(beamStartIx:beamEndIx);

        % --- Weight stats ---
        stats(idx).iBeam = b;
        stats(idx).allWeightsMedian = median(wBeam);
        stats(idx).allWeightsMax = max(wBeam);

        % --- Energy layer analysis ---
        energies = [];
        weights = [];
        ixCounter = 1;

        for iRay = 1:beam.numOfRays
            nSpots = beam.numOfBixelsPerRay(iRay);
            ray = beam.ray(iRay);

            if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot')
                for s = 1:nSpots
                    globalIx = beamStartIx + ixCounter - 1;
                    energies(end+1) = ray.rayTracerInfo.perSpot(s).energy; %#ok<AGROW>
                    weights(end+1) = wAll(globalIx); %#ok<AGROW>
                    ixCounter = ixCounter + 1;
                end
            else
                ixCounter = ixCounter + nSpots;
            end
        end

        % Group energies and compute stats
        [uniqueEnergies, ~, energyLayerIdx] = unique(energies);
        counts = accumarray(energyLayerIdx, 1);
        sums = accumarray(energyLayerIdx, weights');

        [~, idxMostSpots] = max(counts);
        [~, idxHeaviest] = max(sums);

        stats(idx).energyList = uniqueEnergies;
        stats(idx).countsPerEnergy = counts;
        stats(idx).weightsPerEnergy = sums;

        stats(idx).energyMostSpots.value = uniqueEnergies(idxMostSpots);
        stats(idx).energyMostSpots.count = counts(idxMostSpots);
        stats(idx).energyMostSpots.weightSum = sums(idxMostSpots);
        stats(idx).energyMostSpots.layerIndex = idxMostSpots;

        stats(idx).energyHeaviest.value = uniqueEnergies(idxHeaviest);
        stats(idx).energyHeaviest.count = counts(idxHeaviest);
        stats(idx).energyHeaviest.weightSum = sums(idxHeaviest);
        stats(idx).energyHeaviest.layerIndex = idxHeaviest;

        % Optional print summary
        if print
            fprintf('\nBeam %d\n', b);
            fprintf('----------------------------------------------------\n');
            fprintf('→ All spots:    median weight = %.4f | max = %.4f\n', ...
                stats(idx).allWeightsMedian, stats(idx).allWeightsMax);
            fprintf('----------------------------------------------------\n');
            fprintf('→ Energy layer with MOST heavy spots:\n');
            fprintf('   Layer index = %d | Energy = %.2f MeV\n', ...
                stats(idx).energyMostSpots.layerIndex, stats(idx).energyMostSpots.value);
            fprintf('   → %d spots, weight sum = %.2f\n', ...
                stats(idx).energyMostSpots.count, stats(idx).energyMostSpots.weightSum);
            fprintf('→ Energy layer with HEAVIEST total weight:\n');
            fprintf('   Layer index = %d | Energy = %.2f MeV\n', ...
                stats(idx).energyHeaviest.layerIndex, stats(idx).energyHeaviest.value);
            fprintf('   → %d spots, weight sum = %.2f\n\n', ...
                stats(idx).energyHeaviest.count, stats(idx).energyHeaviest.weightSum);
        end
    end
end
