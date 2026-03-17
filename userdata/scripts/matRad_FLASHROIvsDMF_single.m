function out = matRad_FLASHROIvsDMF_single(cst, dosesRes, varargin)
% matRad_FLASHROIvsDMF_single - Spine D2 vs DMF sweep + FLASH ROI mask stats for ONE patient
%
% Syntax:
%   out = matRad_FLASHROIvsDMF_single(ct, cst, dosesRes)
%   out = matRad_FLASHROIvsDMF_single(ct, cst, dosesRes, 'dmfStep', 0.05)
%   out = matRad_FLASHROIvsDMF_single(ct, cst, dosesRes, 'dmfRange', [1.1 1.8], 'doseThresholdsGy', [4 6 8])
%   out = matRad_FLASHROIvsDMF_single(ct, cst, dosesRes, 'spineVoiIx', 12)
%
% Description:
%   Single-patient version of matRad_FLASHROIvsDMF. Assumes you already have
%   ct, cst, and dose components loaded in the workspace (no I/O).
%   Computes:
%     - D2(spine) for Arc and combinedNoDMF (constants)
%     - D2(spine) vs DMF for multiple FLASH thresholds, where DMF is applied
%       only inside the FLASH mask (derived from flashNoDMF dose)
%     - per-threshold mask size stats (and optional printout for VOI selection)
%
% Inputs:
%   ct       - matRad CT struct (not used here, kept for interface consistency)
%   cst      - matRad CST cell array
%   dosesRes - struct with required fields:
%                .compArc
%                .flashNoDMF
%              Optional (if present they will be used, otherwise computed):
%                .combinedNoDMF = compArc + flashNoDMF
%                .Arc          (if not present, uses combinedNoDMF as placeholder ONLY if you want; see checks)
%
% Name-Value Pairs:
%   'doseThresholdsGy' - default [4 6 8]
%   'dmfRange'         - default [1.1 1.8]
%   'dmfStep'          - default 0.05
%   'spineVoiIx'       - (optional) numeric VOI index in cst. If empty, tries matRad_VOIFindIx(cst,'Cord')
%   'includeHealthy'   - default true
%   'printIfSelection' - default true; prints voxel counts only when a VOI selection is passed to matRad_flashVoxels
%
% Outputs:
%   out - struct:
%         .spineVoiIx
%         .spineVoiName
%         .thresholdsGy
%         .dmf.values / .dmf.range / .dmf.step
%         .D2.Arc
%         .D2.combinedNoDMF
%         .D2.curves.thr_XGy.doseThresholdGy
%         .D2.curves.thr_XGy.values
%         .maskStats.thr_XGy.doseThresholdGy
%         .maskStats.thr_XGy.nVoxMask
%
% Reference entry:
% | `matRad_FLASHROIvsDMF_single` | `matRad_FLASHROIvsDMF_single` | Single-patient Spine D2 vs DMF + FLASH ROI stats | `out = matRad_FLASHROIvsDMF_single(ct,cst,dosesRes)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

%% Options
p = inputParser;
p.addParameter('doseThresholdsGy', [4 6 8], @(x) isnumeric(x) && isvector(x) && all(isfinite(x)) && all(x>0));
p.addParameter('dmfRange', [1.1 1.8], @(x) isnumeric(x) && numel(x)==2 && all(isfinite(x)) && x(2)>x(1));
p.addParameter('dmfStep', 0.05, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x>0);
p.addParameter('spineVoiIx', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x>=1 && x==round(x)));
p.addParameter('includeHealthy', true, @(x) islogical(x) && isscalar(x));
p.addParameter('printIfSelection', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opts = p.Results; %#ok<NASGU>

doseThresholdsGy = unique(p.Results.doseThresholdsGy(:)', 'stable');
dmfVals = p.Results.dmfRange(1):p.Results.dmfStep:p.Results.dmfRange(2);
dmfVals = round(dmfVals, 10);

nThr = numel(doseThresholdsGy);

%% Checks + derived doses
if nargin < 3
    error('You must provide ct, cst, and dosesRes.');
end
if ~iscell(cst) || isempty(cst)
    error('cst must be a non-empty CST cell array.');
end
if ~isstruct(dosesRes)
    error('dosesRes must be a struct with dose components.');
end

local_assertFieldsExist(dosesRes, {'compArc','flashNoDMF'}, 'dosesRes');

if ~isfield(dosesRes,'combinedNoDMF') || isempty(dosesRes.combinedNoDMF)
    dosesRes.combinedNoDMF = dosesRes.compArc + dosesRes.flashNoDMF;
end

% Arc dose: prefer dosesRes.Arc if present, else fall back to compArc (common in your pipeline)
if isfield(dosesRes,'Arc') && ~isempty(dosesRes.Arc)
    doseArc = dosesRes.Arc;
else
    doseArc = dosesRes.compArc;
end

%% Find spine VOI
if isempty(p.Results.spineVoiIx)
    ixSpine = matRad_VOIFindIx(cst, 'Cord');
else
    ixSpine = p.Results.spineVoiIx;
end

if isempty(ixSpine) || ~isscalar(ixSpine)
    error('Could not determine spine VOI index. Provide it via ''spineVoiIx'' or ensure matRad_VOIFindIx(cst,''Cord'') works.');
end

spineVoiName = cst{ixSpine,2};
if iscell(spineVoiName), spineVoiName = spineVoiName{1}; end
spineVoiName = char(string(spineVoiName));

%% Output skeleton
out = struct();
out.spineVoiIx   = ixSpine;
out.spineVoiName = spineVoiName;
out.thresholdsGy = doseThresholdsGy;
out.dmf = struct('values', dmfVals, 'range', p.Results.dmfRange, 'step', p.Results.dmfStep);
out.D2 = struct('Arc', NaN, 'combinedNoDMF', NaN, 'curves', struct());
out.maskStats = struct();

%% Constants
out.D2.Arc           = matRad_getDx(cst(ixSpine, :), doseArc, 1, 2);
out.D2.combinedNoDMF = matRad_getDx(cst(ixSpine, :), dosesRes.combinedNoDMF, 1, 2);

%% Threshold curves + stats
for iT = 1:nThr
    thrGy = doseThresholdsGy(iT);
    thrField = local_thrFieldName(thrGy);

    % FLASH mask from flashNoDMF at this threshold
    % NOTE: voiSelection passed to matRad_flashVoxels is numeric indices in your convention.
    [flashMask, ~, ~] = matRad_flashVoxels( ...
        cst, dosesRes.flashNoDMF, thrGy, ixSpine, ...
        p.Results.includeHealthy);

    flashMask = logical(flashMask);
    nVoxMask  = nnz(flashMask);

    % Allocate D2 curve
    d2vals = nan(size(dmfVals));

    if nVoxMask == 0
        d2vals(:) = out.D2.combinedNoDMF;
    else
        for iD = 1:numel(dmfVals)
            dmf = dmfVals(iD);

            flashWithDMF = matRad_flashApplyDMF(dosesRes.flashNoDMF, flashMask, dmf);
            doseTot      = dosesRes.compArc + flashWithDMF;

            d2vals(iD) = matRad_getDx(cst(ixSpine, :), doseTot, 1, 2);
        end
    end

    % Store
    out.D2.curves.(thrField).doseThresholdGy = thrGy;
    out.D2.curves.(thrField).values          = d2vals;

    out.maskStats.(thrField).doseThresholdGy = thrGy;
    out.maskStats.(thrField).nVoxMask        = nVoxMask;
end

end

%% =======================================================================
% Local helpers
% =======================================================================

function s = local_thrFieldName(thrGy)
s = ['thr_' regexprep(num2str(thrGy, 12), '\W', '_') 'Gy'];
end

function local_assertFieldsExist(S, names, structLabel)
missing = {};
for i = 1:numel(names)
    if ~isfield(S, names{i})
        missing{end+1} = names{i}; %#ok<AGROW>
    end
end
if ~isempty(missing)
    error('Missing field(s) in %s: %s', structLabel, strjoin(missing, ', '));
end
end