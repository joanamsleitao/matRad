function mergedELayerStruct = matRad_mergeEL(topELayerStruct, mergeRange, mergeTol)
% Merge adjacent energy layers into center layers based on proximity and weight similarity.
%
% Inputs:
%   topELayerStruct - Struct with fields per energy layer (from matRad_weightEnergyLayers)
%   mergeRange      - [low high] MeV range around each center (default: [5 5])
%   mergeTol        - Struct with optional fields:
%                       .energyGap    (default: 1 MeV)
%                       .weightRatio  (default: 0.1 = 10%)
%
% Output:
%   mergedELayerStruct - Struct with merged spot masks per center energy layer

    % --- Set defaults ---
    if nargin < 2 || isempty(mergeRange)
        mergeRange = [5 5]; % ±5 MeV default
    end
    if nargin < 3 || isempty(mergeTol)
        mergeTol.energyGap = 1;
        mergeTol.weightRatio = 0.1;
    end

    % --- Extract fields ---
    fields = fieldnames(topELayerStruct);
    n = numel(fields);
    energies = zeros(n,1);
    weights = zeros(n,1);
    isCenter = false(n,1);
    spotMasks = false(numel(topELayerStruct.(fields{1}).spotMask), n);

    for i = 1:n
        el = topELayerStruct.(fields{i});
        energies(i) = el.energy;
        weights(i) = sum(el.spotMask);
        isCenter(i) = isfield(el, 'isCenter') && el.isCenter == 1;
        spotMasks(:,i) = el.spotMask;
    end

    % --- Sort by energy ---
    [energies, sortIdx] = sort(energies);
    weights = weights(sortIdx);
    isCenter = isCenter(sortIdx);
    spotMasks = spotMasks(:,sortIdx);
    fields = fields(sortIdx);

    % --- Track merged layers ---
    alreadyMerged = false(n,1);
    mergedELayerStruct = struct;

    for i = 1:n
        if ~isCenter(i) || alreadyMerged(i)
            continue
        end

        eCenter = energies(i);
        wCenter = weights(i);
        mergedMask = spotMasks(:,i);

        eLow = eCenter - mergeRange(1);
        eHigh = eCenter + mergeRange(2);

        for j = 1:n
            if j == i || alreadyMerged(j)
                continue
            end

            eDiff = abs(energies(j) - eCenter);
            wDiff = abs(weights(j) - wCenter) / wCenter;

            if energies(j) >= eLow && energies(j) <= eHigh && ...
               eDiff <= mergeTol.energyGap && wDiff <= mergeTol.weightRatio

                mergedMask = mergedMask | spotMasks(:,j);
                alreadyMerged(j) = true;
            end
        end

        alreadyMerged(i) = true;

        name = matlab.lang.makeValidName(sprintf('EL_%.1fMeV', eCenter));
        mergedELayerStruct.(name).energy = eCenter;
        mergedELayerStruct.(name).spotMask = mergedMask;
        mergedELayerStruct.(name).isCenter = true;
    end
end
