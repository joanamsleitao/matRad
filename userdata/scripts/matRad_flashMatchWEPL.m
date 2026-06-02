function [rayMatch, energySummary] = matRad_flashMatchWEPL(stf, cst, ixInterface, beamModel, tolWEPL)
% matRad_flashMatchWEPL - Match ray-wise interface WEPL windows to spot energies
%
% Syntax:
%   [rayMatch, energySummary] = matRad_flashMatchWEPL(stf, cst, ixInterface, beamModel)
%   [rayMatch, energySummary] = matRad_flashMatchWEPL(stf, cst, ixInterface, beamModel, tolWEPL)
%
% Description:
%   For each ray in stf, this function finds where the ray intersects the
%   Interface VOI and converts that intersection into a WEPL window using
%   rayTracerInfo.wepl_segments. It then compares the available spot
%   energies in that ray against a machine beam model lookup table and
%   identifies which spots are compatible with the Interface WEPL window.
%
%   This is a fast geometric/depth screening step for Stage 1 FLASH
%   feasibility. It does not compute dose. Instead, it determines which
%   spot energies are depth-compatible with the FLASH aiming region.
%
% Inputs:
%   stf          - matRad STF struct after matRad_spotsPosSiddon
%   cst          - matRad CST cell array containing the Interface VOI
%   ixInterface  - CST row index of the Interface VOI
%   beamModel    - table with at least:
%                  beamModel.range   : energy key matching stf(...).energy
%                  beamModel.peakPos : depth/WEPL proxy for that energy
%   tolWEPL      - optional WEPL tolerance [same units as peakPos/wepl],
%                  default = 0
%
% Outputs:
%   rayMatch     - struct array with one entry per intersecting ray:
%     .iBeam           - beam index
%     .iRay            - ray index
%     .gantryAngle     - gantry angle [deg]
%     .nHits           - number of ray-trace samples inside Interface
%     .weplEnter       - first WEPL inside Interface
%     .weplExit        - last WEPL inside Interface
%     .weplCenter      - center WEPL of Interface segment
%     .weplWidth       - WEPL thickness across Interface
%     .spotEnergy      - spot energies available in this ray
%     .spotPeakPos     - mapped peak positions from beamModel
%     .isCandidate     - logical vector, true for compatible spots
%     .candidateSpotIx - indices of compatible spots in this ray
%     .candidateEnergy - energies of compatible spots
%
%   energySummary - table summarizing compatible energies across all rays:
%     energy          - nominal energy key
%     peakPos         - mapped peak position
%     nRaysMatched    - number of rays where this energy is compatible
%     nSpotsMatched   - number of compatible spots total
%
% Notes:
%   - The relevant quantity is the Interface WEPL interval seen by each ray,
%     not the global size of ixInterface.
%   - This version uses the full Interface hit extent in the ray:
%       [weplEnter, weplExit]
%     If needed later, this can be refined to multiple disjoint Interface
%     segments per ray.
%   - Matching criterion:
%       peakPos in [weplEnter - tolWEPL, weplExit + tolWEPL]
%   - Assumption for now:
%       beamModel.range matches stf(...).ray(...).energy
%       beamModel.peakPos is the depth metric to compare to WEPL
%
% Reference entry:
%   | `matRad_flashMatchWEPL` | `matRad_flashMatchWEPL` | Match Interface WEPL windows to available spot energies | `[rayMatch, energySummary] = matRad_flashMatchWEPL(stf, cst, ixInterface, beamModel, tolWEPL)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 5 || isempty(tolWEPL)
    tolWEPL = 0;
end

validateattributes(ixInterface, {'numeric'}, {'scalar','integer','positive'}, mfilename, 'ixInterface', 3);
validateattributes(tolWEPL, {'numeric'}, {'scalar','nonnegative'}, mfilename, 'tolWEPL', 5);

if ~istable(beamModel) && ~isstruct(beamModel)
    error('beamModel must be a table or a struct array.');
end

reqVars = {'range','peakPos'};
for iVar = 1:numel(reqVars)
    if ~ismember(reqVars{iVar}, beamModel.Properties.VariableNames)
        error('beamModel must contain the column ''%s''.', reqVars{iVar});
    end
end

voxInterface = cst{ixInterface,4}{1};
voxInterface = unique(voxInterface(:));

rayMatch = struct( ...
    'iBeam', {}, ...
    'iRay', {}, ...
    'gantryAngle', {}, ...
    'nHits', {}, ...
    'weplEnter', {}, ...
    'weplExit', {}, ...
    'weplCenter', {}, ...
    'weplWidth', {}, ...
    'spotEnergy', {}, ...
    'spotPeakPos', {}, ...
    'isCandidate', {}, ...
    'candidateSpotIx', {}, ...
    'candidateEnergy', {} );

allCandidateEnergy = [];
allCandidatePeak   = [];
allCandidateBeam   = [];
allCandidateRay    = [];

if istable(beamModel)
    bmRange = beamModel.range(:);
    bmPeak  = beamModel.peakPos(:);
else
    % assume struct array
    bmRange = [beamModel.range];
    bmPeak  = [beamModel.peakPos];
end

for iBeam = 1:numel(stf)
    for iRay = 1:numel(stf(iBeam).ray)

        rt = stf(iBeam).ray(iRay).rayTracerInfo;

        if ~isfield(rt, 'ix') || ~isfield(rt, 'wepl_segments')
            warning('Beam %d Ray %d skipped: missing rayTracerInfo.ix or wepl_segments.', iBeam, iRay);
            continue
        end

        rayIx   = rt.ix(:);
        weplSeg = rt.wepl_segments(:);

        if numel(rayIx) ~= numel(weplSeg)
            warning('Beam %d Ray %d skipped: ix and wepl_segments size mismatch.', iBeam, iRay);
            continue
        end

        hitMask = ismember(rayIx, voxInterface);

        if ~any(hitMask)
            continue
        end

        cumWEPL = cumsum(weplSeg);

        hitWEPL = cumWEPL(hitMask);

        weplEnter  = min(hitWEPL);
        weplExit   = max(hitWEPL);
        weplCenter = 0.5 * (weplEnter + weplExit);
        weplWidth  = weplExit - weplEnter;

        spotEnergy = stf(iBeam).ray(iRay).energy(:);
        nSpots     = numel(spotEnergy);
        spotPeak   = nan(nSpots,1);
        isCand     = false(nSpots,1);

        for iSpot = 1:nSpots
            ixBM = find(abs(bmRange - spotEnergy(iSpot)) < 1e-6, 1, 'first');

            if isempty(ixBM)
                continue
            end

            spotPeak(iSpot) = bmPeak(ixBM);

            if spotPeak(iSpot) >= (weplEnter - tolWEPL) && ...
               spotPeak(iSpot) <= (weplExit  + tolWEPL)
                isCand(iSpot) = true;
            end
        end

        candIx     = find(isCand);
        candEnergy = spotEnergy(candIx);

        s = struct();
        s.iBeam           = iBeam;
        s.iRay            = iRay;
        s.gantryAngle     = stf(iBeam).gantryAngle;
        s.nHits           = nnz(hitMask);
        s.weplEnter       = weplEnter;
        s.weplExit        = weplExit;
        s.weplCenter      = weplCenter;
        s.weplWidth       = weplWidth;
        s.spotEnergy      = spotEnergy;
        s.spotPeakPos     = spotPeak;
        s.isCandidate     = isCand;
        s.candidateSpotIx = candIx;
        s.candidateEnergy = candEnergy;

        rayMatch(end+1) = s; %#ok<AGROW>

        if ~isempty(candIx)
            allCandidateEnergy = [allCandidateEnergy; candEnergy(:)]; %#ok<AGROW>
            allCandidatePeak   = [allCandidatePeak; spotPeak(candIx)]; %#ok<AGROW>
            allCandidateBeam   = [allCandidateBeam; iBeam*ones(numel(candIx),1)]; %#ok<AGROW>
            allCandidateRay    = [allCandidateRay; iRay*ones(numel(candIx),1)]; %#ok<AGROW>
        end
    end
end

if isempty(allCandidateEnergy)
    energySummary = table([], [], [], [], ...
        'VariableNames', {'energy','peakPos','nRaysMatched','nSpotsMatched'});
    fprintf('[matRad_flashMatchWEPL] No compatible spot energies found.\n');
    return
end

[uEnergy, ~, ic] = unique(allCandidateEnergy);
nE = numel(uEnergy);

peakPos      = nan(nE,1);
nRaysMatched = zeros(nE,1);
nSpotsMatch  = zeros(nE,1);

for iE = 1:nE
    thisMask = (ic == iE);
    peakPos(iE) = mean(allCandidatePeak(thisMask), 'omitnan');
    nSpotsMatch(iE) = nnz(thisMask);

    rayPairs = unique([allCandidateBeam(thisMask), allCandidateRay(thisMask)], 'rows');
    nRaysMatched(iE) = size(rayPairs, 1);
end

energySummary = table(uEnergy, peakPos, nRaysMatched, nSpotsMatch, ...
    'VariableNames', {'energy','peakPos','nRaysMatched','nSpotsMatched'});

energySummary = sortrows(energySummary, {'nRaysMatched','nSpotsMatched'}, {'descend','descend'});

fprintf('[matRad_flashMatchWEPL] %d intersecting ray(s), %d unique compatible energy layer(s)\n', ...
    numel(rayMatch), height(energySummary));

nShow = min(5, height(energySummary));
for i = 1:nShow
    fprintf('  %.4f MeV | peakPos=%.3f | matched rays=%d | matched spots=%d\n', ...
        energySummary.energy(i), energySummary.peakPos(i), ...
        energySummary.nRaysMatched(i), energySummary.nSpotsMatched(i));
end

end