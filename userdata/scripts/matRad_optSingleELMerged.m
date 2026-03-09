function [doseELOpt, wELOpt, weightsFiltered, mergedELStruct] = matRad_optSingleELMerged(dij, cst, pln, wAll, topELStruct, doMerge, mergeRange, mergeTol)
% matRad_optSingleELMerged - Reoptimize energy layers with optional merging
%
% Syntax:
%   [doseELOpt, wELOpt, weightsFiltered] = matRad_optSingleELMerged(dij, cst, pln, wAll, topELStruct)
%   [doseELOpt, wELOpt, weightsFiltered, mergedELStruct] = matRad_optSingleELMerged(..., doMerge, mergeRange, mergeTol)
%
% Description:
%   Optionally merges adjacent energy layers in topELStruct based on energy
%   and weight similarity, then reoptimizes the merged layer(s) using
%   matRad_SpotRemovalDij. If doMerge is false, behaves like matRad_optSingleEL.
%
% Inputs:
%   dij         - matRad dij struct
%   cst         - CST cell array
%   pln         - plan struct
%   wAll        - global weight vector (e.g. wRBE)
%   topELStruct - struct with multiple ELs (or single EL if no merge)
%   doMerge     - (optional) boolean, default false
%   mergeRange  - (optional) [low high] MeV range around center (default [5 5])
%   mergeTol    - (optional) struct with .energyGap and .weightRatio
%
% Outputs:
%   doseELOpt       - optimized dose cube (rescaled)
%   wELOpt          - optimized weights (rescaled)
%   weightsFiltered - initial filtered weights
%   mergedELStruct  - (optional) merged EL struct if doMerge=true
%
% Example:
%   % Without merging (single EL):
%   [doseOpt, wOpt] = matRad_optSingleELMerged(dij, cst, pln, wRBE, topELStruct_single);
%
%   % With merging (multiple ELs):
%   [doseOpt, wOpt, wFilt, merged] = matRad_optSingleELMerged(dij, cst, pln, wRBE, topELStruct_top5, true, [3 3]);
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_optSingleELMerged` | `matRad_optSingleELMerged` | Reoptimize ELs with optional merging | `[doseELOpt, wELOpt, weightsFiltered, mergedELStruct] = matRad_optSingleELMerged(dij, cst, pln, wAll, topELStruct, doMerge, mergeRange, mergeTol)` | 🟢 |
% -------------------------------------------------------------------------

if nargin < 6 || isempty(doMerge)
    doMerge = false;
end
if nargin < 7 || isempty(mergeRange)
    mergeRange = [5 5];
end
if nargin < 8 || isempty(mergeTol)
    mergeTol.energyGap = 1;
    mergeTol.weightRatio = 0.1;
end

% -------------------------------------------------------------------------
% Step 1: Optionally merge layers
% -------------------------------------------------------------------------
if doMerge
    mergedELStruct = matRad_mergeEL(topELStruct, mergeRange, mergeTol);
    fprintf('Merged %d layers into %d center layers.\n', ...
            numel(fieldnames(topELStruct)), numel(fieldnames(mergedELStruct)));
    workingStruct = mergedELStruct;
else
    mergedELStruct = struct();
    workingStruct = topELStruct;
end

% -------------------------------------------------------------------------
% Step 2: Build combined spotMask and dose reference
% -------------------------------------------------------------------------
ELNames = fieldnames(workingStruct);
nEL = numel(ELNames);

% Initialize combined mask
spotMaskCombined = false(numel(wAll), 1);
doseRefSum = [];

for i = 1:nEL
    layer = ELNames{i};
    el = workingStruct.(layer);
    
    % Merge spot masks
    if isfield(el, 'spotMask')
        spotMaskCombined = spotMaskCombined | el.spotMask;
    else
        error('matRad_optSingleELMerged:MissingSpotMask', ...
              'Layer "%s" missing spotMask field.', layer);
    end
    
    % Sum dose cubes for reference (if available)
    if isfield(el, 'RBExDose') && ~isempty(el.RBExDose)
        if isempty(doseRefSum)
            doseRefSum = el.RBExDose;
        else
            doseRefSum = doseRefSum + el.RBExDose;
        end
    end
end

if isempty(doseRefSum)
    error('matRad_optSingleELMerged:MissingDose', ...
          'No RBExDose found in any layer.');
end

% -------------------------------------------------------------------------
% Step 3: Filter weights and reoptimize
% -------------------------------------------------------------------------
weightsFiltered = wAll;
weightsFiltered(~spotMaskCombined) = 0;

spotRemover = matRad_SpotRemovalDij(dij, weightsFiltered);
resultELOpt = spotRemover.reoptimize(cst, pln);

% -------------------------------------------------------------------------
% Step 4: Rescale to match original max dose
% -------------------------------------------------------------------------
doseELOpt_raw = resultELOpt.RBExDose;
f = max(doseRefSum(:)) / max(doseELOpt_raw(:));

doseELOpt = f * doseELOpt_raw;
wELOpt    = f * resultELOpt.w;

end