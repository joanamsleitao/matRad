function [layerSummary, oarDoseTable] = matRad_weightEnergyLayers(ct, cst, stf, dij, resultGUI, oarIndices, thresholdPercent)
% MATRAD_WEIGHTENERGYLAYERS - Identifies top energy layers by dose contribution and quantifies their impact on given OARs
%
% Syntax:  [layerSummary, oarDoseTable] = matRad_weightEnergyLayers(stf, dij, resultGUI, cst, oarIndices, thresholdPercent)
%
% Inputs:
%   stf              - Spot scanning field structure (struct)
%   dij              - Dose influence matrix (struct with field 'physicalDose')
%   resultGUI        - matRad result structure with spot weights (contains .w)
%   cst              - Constraint structure table (cell array)
%   oarIndices       - Indices of rows in CST corresponding to OARs (vector)
%   thresholdPercent - Percent of cumulative dose to include from top energy layers (default = 5)
%
% Outputs:
%   layerSummary     - Table of energy layers and total dose contribution (sorted)
%   oarDoseTable     - Table of dose contribution to each OAR from selected energy layers
%
% See also: matRad_computeSpotStats, matRad_plotTopDoseLayers

if nargin < 6 || isempty(thresholdPercent)
    thresholdPercent = 5;
end

cst = matRad_resizeCstToGrid(cst,dij.ctGrid.x,dij.ctGrid.y,dij.ctGrid.z,...
    dij.doseGrid.x,dij.doseGrid.y,dij.doseGrid.z);

w = resultGUI.w;
nSpots = length(w);

% --- Step 1: Map each spot index to its energy ---
energies = zeros(nSpots, 1);  % Energy per spot
ix = 1;  % Global spot counter

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

% --- Step 2: Group by energy layer ---
[uniqueEnergies, ~, energyLayerIdx] = unique(energies);
nLayers = numel(uniqueEnergies);
dosePerLayer = zeros(nLayers, 1);

% --- Step 3: Compute dose contribution of each energy layer ---
dijMatrix = dij.physicalDose{1};  % Extract dose influence matrix (voxels x spots)

for i = 1:nLayers
    spotMask = (energyLayerIdx == i);  % indices of spots in this layer
    wLayer = w(spotMask);
    dijLayer = dijMatrix(:, spotMask);
    doseLayer = full(dijLayer * wLayer);
    dosePerLayer(i) = sum(doseLayer);  % total dose (to all voxels) from this layer
end

% --- Step 4: Sort layers by dose contribution and get top N% ---
[sortedDose, sortIdx] = sort(dosePerLayer, 'descend');
sortedEnergies = uniqueEnergies(sortIdx);
cumulativeDose = cumsum(sortedDose);
totalDose = cumulativeDose(end);
cutoffDose = totalDose * (thresholdPercent / 100);

% Include enough top layers to reach threshold %
nTopLayers = find(cumulativeDose >= cutoffDose, 1, 'first');
selectedLayerIdx = sortIdx(1:nTopLayers);

% --- Step 5: Prepare summary table ---
layerSummary = table(uniqueEnergies(selectedLayerIdx), dosePerLayer(selectedLayerIdx), ...
    'VariableNames', {'Energy_MeV', 'TotalDose'});

% --- Step 6: Compute OAR-specific dose from each top layer ---
oarNames = cst(oarIndices, 2);
oarDoseTable = array2table(zeros(numel(selectedLayerIdx), numel(oarIndices)), ...
    'VariableNames', matlab.lang.makeValidName(oarNames), ...
    'RowNames', strcat("E_", strrep(string(uniqueEnergies(selectedLayerIdx)), '.', '_')));

for l = 1:numel(selectedLayerIdx)
    iLayer = selectedLayerIdx(l);
    spotMask = (energyLayerIdx == iLayer);
    wLayer = w(spotMask);
    dijLayer = dijMatrix(:, spotMask);
    doseLayer = full(dijLayer * wLayer);  % full voxel-wise dose from this layer

    for o = 1:numel(oarIndices)
        voxels = cst{oarIndices(o), 4}{1};  % linear voxel indices for this OAR
        oarDoseTable{l, o} = sum(doseLayer(voxels));
    end
end
end
