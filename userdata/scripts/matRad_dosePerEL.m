function dosePerLayerCubes = matRad_dosePerEL(ct, cst, stf, dij, resultGUI, thresholdPercent)
% MATRAD_SEPARATEDOSEPERENERGYLAYER - Computes per-energy-layer dose in CT grid using matRad_calcCubes
%
% Inputs:
%   ct               - CT struct (for reference grid)
%   cst              - Constraint structure
%   stf              - Spot field
%   dij              - DIJ struct (includes doseGrid and ctGrid)
%   resultGUI        - matRad result struct (must contain .w)
%   thresholdPercent - Only keep layers contributing top X% of dose (optional)
%
% Output:
%   dosePerLayerCubes - Cell array of dose cubes [X×Y×Z] in CT grid, one per selected energy layer

    if nargin < 6 || isempty(thresholdPercent)
        thresholdPercent = 100;  % default: include all
    end

    w = resultGUI.w;
    nSpots = length(w);
    dijMatrix = dij.physicalDose{1};  % [voxels x spots]

    % --- Step 1: Extract energy per spot ---
    energies = zeros(nSpots, 1);
    ix = 1;
    for b = 1:numel(stf)
        for r = 1:stf(b).numOfRays
            ray = stf(b).ray(r);
            n = stf(b).numOfBixelsPerRay(r);
            if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot')
                for s = 1:n
                    energies(ix) = ray.rayTracerInfo.perSpot(s).energy;
                    ix = ix + 1;
                end
            else
                ix = ix + n;
            end
        end
    end

    [uniqueEnergies, ~, energyLayerIdx] = unique(energies);
    nLayers = numel(uniqueEnergies);
    totalDosePerLayer = zeros(nLayers, 1);

    % --- Step 2: Compute dose contribution per layer (in dij space) ---
    for i = 1:nLayers
        spotMask = (energyLayerIdx == i);
        wLayer = w(spotMask);
        dijLayer = dijMatrix(:, spotMask);
        doseLayer = full(dijLayer * wLayer);
        totalDosePerLayer(i) = sum(doseLayer);
    end

    % --- Step 3: Select top energy layers based on cumulative dose ---
    [sortedDose, sortIdx] = sort(totalDosePerLayer, 'descend');
    cumulativeDose = cumsum(sortedDose);
    totalDose = cumulativeDose(end);
    cutoffDose = totalDose * (thresholdPercent / 100);
    nTopLayers = find(cumulativeDose >= cutoffDose, 1, 'first');
    selectedIdx = sortIdx(1:nTopLayers);

    % --- Step 4: Compute per-layer dose using matRad_calcCubes ---
    dosePerLayerCubes = cell(nTopLayers, 1);

    for l = 1:nTopLayers
        iLayer = selectedIdx(l);
        spotMask = (energyLayerIdx == iLayer);

        % Create full-size weight vector: only selected layer has non-zero weights
        wMask = zeros(size(w));
        wMask(spotMask) = w(spotMask);

        % Compute dose for that layer using matRad's interpolation to CT grid
        doseCT = matRad_calcCubes(wMask, dij);
        dosePerLayerCubes{l} = doseCT;
    end
end
