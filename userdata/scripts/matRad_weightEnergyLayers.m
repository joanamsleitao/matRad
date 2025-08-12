function [layerSummary, topELStruct, EL, locs] = matRad_weightEnergyLayers(cst, stf, dij, resultGUI, oarIdx, wThresh)
% MATRAD_WEIGHTENERGYLAYERS - Summarizes spot weights per energy layer and identifies dominant layers.
%
% Inputs:
%   cst       - Constraint structure table (cell array)
%   stf       - Spot scanning field
%   dij       - Dose influence matrix (struct with .physicalDose{1})
%   resultGUI - matRad result structure (must contain .w)
%   oarIdx    - CST row indices corresponding to OARs (optional)
%   wThresh   - Weight threshold for filtering (optional, default = median(w))
%
% Outputs:
%   layerSummary         - Table summarizing each energy layer
%   topELStruct          - Struct with selected top energy layers
%   nEL                  - Number of unique energy layers
%   nTopEL               - Number of top energy layers (based on peak detection)

%% --- Prep
cst = matRad_resizeCstToGrid(cst, dij.ctGrid.x, dij.ctGrid.y, dij.ctGrid.z, ...
    dij.doseGrid.x, dij.doseGrid.y, dij.doseGrid.z);

w = resultGUI.w;
if nargin < 6 || isempty(wThresh)
    wThresh = median(w);
end
nSpots = length(w);

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
wPerEL = zeros(nEL,1);
nTotal = zeros(nEL,1);
nAbove = zeros(nEL,1);
doseSum = zeros(nEL,1);

for i = 1:nEL
    mask = (energyIdx == i);
    wEL = w(mask);
    wPerEL(i) = sum(wEL);
    nTotal(i) = length(wEL);
    nAbove(i) = sum(wEL >= wThresh);

    dijEL = dijMtx(:, mask);
    doseSum(i) = sum(full(dijEL * wEL));
end
nSpotsAboveThresh = sum(nAbove);

%% --- Optional OAR doses
if exist('oarIdx', 'var') && ~isempty(oarIdx)
    oarNames = cst(oarIdx, 2);
    nOAR = numel(oarIdx);
    oarDose = zeros(nEL, nOAR);
    for i = 1:nEL
        mask = (energyIdx == i);
        wEL = w(mask);
        dijEL = dijMtx(:, mask);
        dEL = full(dijEL * wEL);
        for o = 1:nOAR
            vox = cst{oarIdx(o), 4}{1};
            oarDose(i, o) = sum(dEL(vox));
        end
    end
end

%% --- Build table
layerSummary = table(uniqueEnergies, wPerEL, nAbove, nTotal, nAbove./nTotal, ...
    'VariableNames', {'Energy_MeV','TotalWeight','SpotsAbove','SpotsTotal','RatioAbove'});

if exist('oarDose', 'var')
    for o = 1:nOAR
        varName = matlab.lang.makeValidName(oarNames{o});
        layerSummary.(varName) = oarDose(:, o);
    end
end

layerSummary = sortrows(layerSummary, 'TotalWeight', 'descend');

%% --- Plot weight per spot
figure;
scatter(1:nSpots, w, 'filled'); hold on;
scatter(find(w >= wThresh), w(w >= wThresh), 'filled', 'MarkerFaceColor', [0.8500 0.3250 0.0980]);
yline(wThresh, '--', 'Threshold');
title('Spot Weights'); xlabel('Spot Index'); ylabel('Weight');
legend('All weights', 'Weights ≥ threshold'); grid on;

%% --- Plot weight per energy layer
figure;
scatter(uniqueEnergies, wPerEL, 'filled');
title('Energy Layer Weights'); xlabel('Energy (MeV)'); ylabel('Total Weight');
xticks(uniqueEnergies);
xticklabels(arrayfun(@(e,n) sprintf('%g (%d)', round(e), n), uniqueEnergies, nTotal, 'UniformOutput', false));
grid on; hold on;

%% --- Identify top energy layers (peaks)
[pks, locs, wids] = findpeaks(wPerEL, uniqueEnergies, 'MinPeakHeight', median(wPerEL));
findpeaks(wPerEL, uniqueEnergies, 'Annotate', 'extents'); hold on;
yline(median(wPerEL), '--', 'median');

ixpks = zeros(numel(pks),1);

% Limits of the "mountains" -> energy layers to consider
for i = 1:numel(pks)
    ixpks(i) = find(wPerEL == pks(i));
    xline(uniqueEnergies(ixpks(i)) - wids(i)/2, '--');
    xline(uniqueEnergies(ixpks(i)) + wids(i)/2, '--', num2str(pks(i)));
end

EL = [];
topELStruct = struct;
for j = 1:numel(pks)
    centerE = locs(j);
    range = [centerE - wids(j)/2, centerE + wids(j)/2];
    for i = 1:nEL
        e = uniqueEnergies(i);
        if e >= range(1) && e <= range(2)
            mask = (energyIdx == i);
            wEL = w(mask);
            EL = [EL; e];
            spotMask = false(size(w));
            spotMask(mask) = wEL >= wThresh;

            name = matlab.lang.makeValidName(sprintf('EL_%.1fMeV', e));
            topELStruct.(name).energy = e;
            topELStruct.(name).spotMask = spotMask;
            topELStruct.(name).isCenter = (e == centerE);
        end
    end
end

nTopEL = numel(fieldnames(topELStruct));
end
