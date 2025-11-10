function [layerSummary, topELStruct, allELStruct, locs] = matRad_wtEL(cst, stf, dij, weights, oarIdx, wThresh)
% MATRAD_WEIGHTENERGYLAYERS - Summarizes spot weights per energy layer,
% dose contributions, and slice indices from stf spot positions.
%
% Inputs:
%   cst       - Constraint structure table (cell array)
%   stf       - Spot scanning field (with rayTracerInfo.perSpot populated)
%   dij       - Dose influence matrix (struct with .physicalDose{1})
%   weights   - matRad result structure (must contain .w)
%   oarIdx    - CST row indices corresponding to OARs (optional)
%   wThresh   - Weight threshold for filtering (default = median(w))
%
% Outputs:
%   layerSummary  - Table summarizing each energy layer
%   topELStruct   - Struct with selected top energy layers (incl. slices)
%   EL            - List of energy layers selected as dominant
%   locs          - Energy positions of identified peaks

%% --- Prep
cst = matRad_resizeCstToGrid(cst, dij.ctGrid.x, dij.ctGrid.y, dij.ctGrid.z, ...
    dij.doseGrid.x, dij.doseGrid.y, dij.doseGrid.z);

if nargin < 6 || isempty(wThresh)
    wThresh = median(weights);
end
nSpots = length(weights);

%% --- Extract energies per spot
energies = zeros(nSpots, 1);
ix = 1;
for b = 1:numel(stf)
    for r = 1:stf(b).numOfRays
        ray = stf(b).ray(r);
        nBix = stf(b).numOfBixelsPerRay(r);

        if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot')
            for s = 1:nBix
                energies(ix) = ray.rayTracerInfo.perSpot(s).energy;
                ix = ix + 1;
            end
        else
            ix = ix + nBix;
        end
    end
end

%% --- Group by energy
[uniqueEnergies, ~, energyIdx] = unique(energies);
nEL = numel(uniqueEnergies);

dijMtx = dij.physicalDose{1};
wPerEL   = zeros(nEL,1);
nTotal   = zeros(nEL,1);
nAbove   = zeros(nEL,1);
doseSum  = zeros(nEL,1);
sliceInfo = cell(nEL,1);

for i = 1:nEL
    mask = (energyIdx == i);
    wEL = weights(mask);
    wPerEL(i) = sum(wEL);
    nTotal(i) = length(wEL);
    nAbove(i) = sum(wEL >= wThresh);

    % --- Dose contribution
    dijEL = dijMtx(:, mask);
    dEL   = full(dijEL * wEL);
    doseSum(i) = sum(dEL);

    % --- Slice indices directly from stf spot positions
    sliceIdx = [];
    for b = 1:numel(stf)
        for r = 1:stf(b).numOfRays
            ray = stf(b).ray(r);
            if isfield(ray,'rayTracerInfo') && isfield(ray.rayTracerInfo,'perSpot')
                for s = 1:numel(ray.rayTracerInfo.perSpot)
                    if abs(ray.rayTracerInfo.perSpot(s).energy - uniqueEnergies(i)) < 1e-3
                        sliceIdx(end+1) = round(ray.rayTracerInfo.perSpot(s).spotCube(3));
                    end
                end
            end
        end
    end
    sliceInfo{i} = unique(sliceIdx);
end

%% --- Optional OAR doses
if exist('oarIdx', 'var') && ~isempty(oarIdx)
    oarNames = cst(oarIdx, 2);
    nOAR = numel(oarIdx);
    oarDose = zeros(nEL, nOAR);
    for i = 1:nEL
        mask = (energyIdx == i);
        wEL = weights(mask);
        dijEL = dijMtx(:, mask);
        dEL = full(dijEL * wEL);
        for o = 1:nOAR
            vox = cst{oarIdx(o), 4}{1};
            oarDose(i, o) = sum(dEL(vox));
        end
    end
end

%% --- Build summary table
layerSummary = table(uniqueEnergies, wPerEL, nAbove, nTotal, nAbove./nTotal, sliceInfo, ...
    'VariableNames', {'Energy_MeV','TotalWeight','SpotsAbove','SpotsTotal','RatioAbove','Slices'});

if exist('oarDose', 'var')
    for o = 1:nOAR
        varName = matlab.lang.makeValidName(oarNames{o});
        layerSummary.(varName) = oarDose(:, o);
    end
end

layerSummary = sortrows(layerSummary, 'TotalWeight', 'descend');

%% --- Plot weight per spot
figure;
tiledlayout(1, 2)
nexttile
scatter(1:nSpots, weights, 'filled'); hold on;
scatter(find(weights >= wThresh), weights(weights >= wThresh), 'filled', 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
yline(wThresh, '--', 'Threshold');
title('Spot Weights'); xlabel('Spot Index'); ylabel('Weight');
legend('All weights', 'Weights ≥ threshold'); grid on;

%% --- Plot weight per energy layer
nexttile
scatter(uniqueEnergies, wPerEL, 'filled');
title('Energy Layer Weights'); xlabel('Energy (MeV)'); ylabel('Total Weight');
xticks(uniqueEnergies);
xticklabels(arrayfun(@(e,n) sprintf('%g (%d)', round(e), n), uniqueEnergies, nTotal, 'UniformOutput', false));
grid on; hold on;

%% --- Identify top energy layers (peaks)
[pks, locs, wids] = findpeaks(wPerEL, uniqueEnergies, 'MinPeakHeight', median(wPerEL));
findpeaks(wPerEL, uniqueEnergies, 'Annotate', 'extents'); hold on;
yline(median(wPerEL), '--', 'median');

%% --- Collect top energy layer info
topELStruct = struct;
allELStruct = struct;

for j = 1:numel(pks)
    centerE = locs(j);
    range = [centerE - wids(j)/2, centerE + wids(j)/2];
    for i = 1:nEL
        e = uniqueEnergies(i);
        mask = (energyIdx == i);
        wEL = weights(mask);
        spotMask = false(size(weights));
        spotMask(mask) = wEL >= wThresh;

        name = matlab.lang.makeValidName(sprintf('EL_%.1fMeV', e));
        allELStruct.(name).energy    = e;
        allELStruct.(name).spotMask  = spotMask;
        allELStruct.(name).isCenter  = (e == centerE);
        allELStruct.(name).slices    = sliceInfo{i};  % <-- from stf

        if e >= range(1) && e <= range(2)
            topELStruct.(name).energy    = e;
            topELStruct.(name).spotMask  = spotMask;
            topELStruct.(name).isCenter  = (e == centerE);
            topELStruct.(name).slices    = sliceInfo{i};  % <-- from stf
        end
    end
end

end
