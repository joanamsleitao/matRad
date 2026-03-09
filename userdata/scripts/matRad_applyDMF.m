function out = matRad_applyDMF(flashDose, cst, doseThreshold, dmf, varargin)
% matRad_applyDMF - Apply FLASH dose modifying factor (DMF) to non-target voxels
%
% Syntax:
%   flashDMF = matRad_applyDMF(flashDose, cst, doseThreshold, dmf)
%   flashDMF = matRad_applyDMF(..., 'Name', Value)
%
% Description:
%   Applies DMF by DIVISION to FLASH dose component, but ONLY to voxels that:
%     1) Have flashDose >= doseThreshold
%     2) Are NOT inside any target structure
%
%   This models the FLASH sparing effect: biological dose is reduced in
%   normal tissue receiving sufficient FLASH dose, while targets remain
%   at physical dose.
%
% Inputs:
%   flashDose      - 3D dose cube [Gy] (FLASH component, physical dose)
%   cst            - matRad structure set
%   doseThreshold  - Scalar [Gy], minimum dose to trigger FLASH effect
%   dmf            - Scalar DMF value OR [dmfLow dmfHigh] for range
%
% Name-Value Parameters:
%   'targetNameTokens' - Cell array of strings to identify targets by name
%                        Default: {'PTV','GTV','CTV','ITV'}
%   'targetIdx'        - Explicit VOI indices to treat as targets
%                        If provided, overrides targetNameTokens
%   'mode'             - 'divide' (default) or 'multiply'
%                        'divide': doseDMF = dose / DMF (DMF < 1 → sparing)
%
% Outputs:
%   If dmf is scalar:
%     out = flashDoseDMF (3D dose cube with DMF applied)
%
%   If dmf is 2-element vector [low high]:
%     out.low  = flashDoseDMF with dmf(1)
%     out.high = flashDoseDMF with dmf(2)
%
% Example:
%   % Apply DMF = 0.7 to spine voxels receiving >= 6 Gy FLASH
%   flashDMF = matRad_applyDMF(flashDose, cst, 6, 0.7);
%
%   % Get DMF range for uncertainty analysis
%   flashDMF_range = matRad_applyDMF(flashDose, cst, 6, [0.6 0.8]);
%   combinedLow  = compArc + flashDMF_range.low;
%   combinedHigh = compArc + flashDMF_range.high;
%
% Author: [Your Name]
% Date: 2026-01-13

    %% Parse inputs
    p = inputParser;
    p.addParameter('targetNameTokens', {'PTV','GTV','CTV','ITV'}, @iscell);
    p.addParameter('targetIdx', [], @isnumeric);
    p.addParameter('mode', 'divide', @(s) ismember(lower(s), {'divide','multiply'}));
    p.parse(varargin{:});
    opt = p.Results;

    %% Identify target structures
    if isempty(opt.targetIdx)
        targetIdx = matRad_findTargetVOIs(cst, opt.targetNameTokens);
    else
        targetIdx = opt.targetIdx;
    end

    %% Build application mask
    % DMF applies where: (dose >= threshold) AND (not in target)
    targetMask = matRad_buildMaskFromVOIs(size(flashDose), cst, targetIdx);
    applyMask  = (flashDose >= doseThreshold) & ~targetMask;

    %% Apply DMF
    applyOne = @(dmfScalar) local_applyDMF(flashDose, applyMask, dmfScalar, opt.mode);

    if isscalar(dmf)
        out = applyOne(dmf);
    else
        % DMF range provided → return struct with low/high
        dmf = sort(dmf(:));
        out.low  = applyOne(dmf(1));
        out.high = applyOne(dmf(2));
    end
end

%% ========================================================================
% LOCAL HELPER FUNCTIONS
% ========================================================================

function doseOut = local_applyDMF(doseIn, mask, dmf, mode)
% Apply DMF to masked voxels only

    doseOut = doseIn;
    
    switch lower(mode)
        case 'divide'
            doseOut(mask) = doseIn(mask) ./ dmf;
        case 'multiply'
            doseOut(mask) = doseIn(mask) .* dmf;
    end
end

function targetIdx = matRad_findTargetVOIs(cst, targetNameTokens)
% Find VOI indices corresponding to target structures by name matching
%
% Inputs:
%   cst               - matRad structure set
%   targetNameTokens  - Cell array of strings (e.g., {'PTV','GTV'})
%
% Output:
%   targetIdx - Vector of VOI indices

    allIdx = find(~cellfun(@isempty, cst(:,2)));
    names  = cst(allIdx, 2);

    isTarget = false(size(allIdx));
    
    for k = 1:numel(allIdx)
        nm = upper(string(names{k}));
        for t = 1:numel(targetNameTokens)
            if contains(nm, upper(string(targetNameTokens{t})))
                isTarget(k) = true;
                break;
            end
        end
    end

    targetIdx = allIdx(isTarget);
end

function mask = matRad_buildMaskFromVOIs(volSize, cst, voiIdx)
% Build a 3D logical mask from VOI indices
%
% Inputs:
%   volSize - Size of dose cube [nx ny nz]
%   cst     - matRad structure set
%   voiIdx  - Vector of VOI indices to include in mask
%
% Output:
%   mask - Logical array (same size as dose cube)

    mask = false(volSize);
    voiIdx = voiIdx(~isnan(voiIdx) & voiIdx > 0);

    for ii = 1:numel(voiIdx)
        idx = voiIdx(ii);
        
        if idx > size(cst,1) || isempty(cst{idx,4})
            continue;
        end

        % Collect all voxel indices for this VOI
        vox = [];
        for k = 1:numel(cst{idx,4})
            vox = [vox; cst{idx,4}{k}(:)];
        end
        vox = unique(vox);
        
        mask(vox) = true;
    end
end

function affectedIdx = matRad_findAffectedNonTargetVOIs(cst, flashDose, doseThreshold, targetIdx)
% Find non-target VOIs that contain voxels where DMF would be applied
%
% Inputs:
%   cst           - matRad structure set
%   flashDose     - 3D FLASH dose cube
%   doseThreshold - Dose threshold for DMF application
%   targetIdx     - Vector of target VOI indices
%
% Output:
%   affectedIdx - Vector of non-target VOI indices that are affected by DMF

    targetIdx = unique(targetIdx(:));
    allIdx = find(~cellfun(@isempty, cst(:,2)));
    nonTargetIdx = setdiff(allIdx, targetIdx);

    targetMask = matRad_buildMaskFromVOIs(size(flashDose), cst, targetIdx);
    applyMask  = (flashDose >= doseThreshold) & ~targetMask;

    affected = false(size(nonTargetIdx));

    for i = 1:numel(nonTargetIdx)
        idx = nonTargetIdx(i);
        
        if isempty(cst{idx,4})
            continue;
        end

        % Get voxels for this VOI
        vox = [];
        for k = 1:numel(cst{idx,4})
            vox = [vox; cst{idx,4}{k}(:)];
        end
        vox = unique(vox);

        % Check if any voxel in this VOI would receive DMF
        affected(i) = any(applyMask(vox));
    end

    affectedIdx = nonTargetIdx(affected);
end


function [x, y] = local_dvhXY(dvh)
% Extract dose and volume vectors from DVH struct
% Handles different matRad field naming conventions

    if isfield(dvh, 'doseGrid')
        x = dvh.doseGrid;
    elseif isfield(dvh, 'dose')
        x = dvh.dose;
    else
        error('DVH struct missing dose grid field');
    end

    if isfield(dvh, 'volumePoints')
        y = dvh.volumePoints;
    elseif isfield(dvh, 'volume')
        y = dvh.volume;
    else
        error('DVH struct missing volume field');
    end
end