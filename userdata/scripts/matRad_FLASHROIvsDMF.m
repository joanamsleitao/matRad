function out = matRad_FLASHROIvsDMF(patientIDs, varargin)
% matRad_calcSpineD2vsDMF - Compute Spine D2 vs DMF curves for multiple patients
%
% Syntax:
%   out = matRad_calcSpineD2vsDMF(patientIDs)
%   out = matRad_calcSpineD2vsDMF(patientIDs, 'dmfStep', 0.05)
%   out = matRad_calcSpineD2vsDMF(patientIDs, 'dmfRange', [1.1 1.8], 'doseThresholdsGy', [4 6 8])
%
% Description:
%   Loads dose components via loadPatientICR(patientID,'rescaled'), then computes:
%     - constant D2(spine) for Arc and combinedNoDMF
%     - variable D2(spine) for DMF sweep applied only to FLASH component, for
%       multiple thresholds (4/6/8 Gy) on flashNoDMF dose.
%
% Inputs:
%   patientIDs - char/string (single) OR cellstr/string array
%
% Name-Value Pairs:
%   'doseThresholdsGy' - [4 6 8] by default
%   'dmfRange'         - [1.1 1.8] by default
%   'dmfStep'          - 0.05 by default
%   'spineAliases'     - aliases for matRad_VOIFindIx (default prefers spinal cord)
%   'minIslandVox3D'   - default 3
%   'minAreaVox2D'     - default 3
%   'includeHealthy'   - default true
%
% Outputs:
%   out - struct array (one per patient):
%         .patientID
%         .spineVoiIx
%         .spineVoiName
%         .thresholdsGy
%         .dmf.values / .dmf.range / .dmf.step
%         .D2.Arc
%         .D2.combinedNoDMF
%         .D2.curves.thr_XGy.doseThresholdGy
%         .D2.curves.thr_XGy.values  (1 x nDMF)
%
% Reference entry:
% | `matRad_calcSpineD2vsDMF` | `matRad_calcSpineD2vsDMF` | Compute spine D2 vs DMF sweep | `out = matRad_calcSpineD2vsDMF({'Sp01','Sp02'})` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------
%
% minIslandVox3D = 3;     % min 3D connected component size (voxels)
% minAreaVox2D   = 3;     % min 2D area threshold per-slice (voxels)
% includeHealthy = true;  % allow mask in non-target healthy tissue

%% Options
p = inputParser;
p.addParameter('doseThresholdsGy', [4 6 8], @(x) isnumeric(x) && isvector(x) && all(isfinite(x)) && all(x>0));
p.addParameter('dmfRange', [1.1 1.8], @(x) isnumeric(x) && numel(x)==2 && all(isfinite(x)) && x(2)>x(1));
p.addParameter('dmfStep', 0.05, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x>0);
p.addParameter('spineAliases', {'SpinalCord','spinal cord','spinalcord','SpineCanal','spine canal','spine'}, ...
    @(x) ischar(x) || isstring(x) || iscell(x));
p.addParameter('minIslandVox3D', 3, @(x) isnumeric(x) && isscalar(x) && x>=0);
p.addParameter('minAreaVox2D', 3, @(x) isnumeric(x) && isscalar(x) && x>=0);
p.addParameter('includeHealthy', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opts = p.Results;

patientIDs = local_toCellstr(patientIDs, 'patientIDs');
patientIDs = local_stripEmpty(patientIDs);
if isempty(patientIDs)
    error('patientIDs cannot be empty.');
end

doseThresholdsGy = unique(opts.doseThresholdsGy(:)','stable');
dmfVals = opts.dmfRange(1):opts.dmfStep:opts.dmfRange(2);
dmfVals = round(dmfVals, 10);

nP   = numel(patientIDs);
nThr = numel(doseThresholdsGy);

%% Prealloc output
out = repmat(struct( ...
    'patientID', '', ...
    'spineVoiIx', [], ...
    'spineVoiName', '', ...
    'D2', struct('Arc', NaN, 'combinedNoDMF', NaN, 'curves', struct()), ...
    'dmf', struct('values', dmfVals, 'range', opts.dmfRange, 'step', opts.dmfStep), ...
    'thresholdsGy', doseThresholdsGy), nP, 1);

%% Loop patients
for iP = 1:nP
    patientID = patientIDs{iP};
    out(iP).patientID = patientID;

    % Load rescaled dose components
    [~, cst, dosesRes] = loadPatientICR(patientID, 'rescaled'); %#ok<ASGLU>
    dosesRes.combinedNoDMF = dosesRes.compArc + dosesRes.flashNoDMF;
    
    % Find spine VOI (prefer SpinalCord)
    ixSpine = matRad_VOIFindIx(cst, 'Cord');
    if isempty(ixSpine) || ~isscalar(ixSpine)
        error('Could not find a spine VOI for patient %s using aliases: %s', ...
            patientID, local_joinAliases(opts.spineAliases));
    end
    out(iP).spineVoiIx   = ixSpine;
    out(iP).spineVoiName = string(cst{ixSpine,2});

    % Dose fields needed
    local_assertFieldsExist(dosesRes, {'Arc','combinedNoDMF','compArc','flashNoDMF'}, sprintf('dosesRes (%s)', patientID));

    % Constants
    out(iP).D2.Arc           = matRad_getDx(cst(ixSpine, :), dosesRes.Arc, 1, 2);
    out(iP).D2.combinedNoDMF = matRad_getDx(cst(ixSpine, :), dosesRes.combinedNoDMF, 1, 2);

    % Threshold curves
    for iT = 1:nThr
        thrGy = doseThresholdsGy(iT);

        % FLASH mask from flashNoDMF at this threshold
        [flashMask, ~, ~] = matRad_flashVoxels( ...
            cst, dosesRes.flashNoDMF, thrGy, [], ...
            opts.includeHealthy, 1, 1);

        d2vals = nan(size(dmfVals));
        for iD = 1:numel(dmfVals)
            dmf = dmfVals(iD);

            flashWithDMF = matRad_flashApplyDMF(dosesRes.flashNoDMF, flashMask, dmf);
            doseTot      = dosesRes.compArc + flashWithDMF;

            d2vals(iD) = matRad_getDx(cst(ixSpine, :), doseTot, 1, 2);

        end

        thrField = local_thrFieldName(thrGy);
        out(iP).D2.curves.(thrField).doseThresholdGy = thrGy;
        out(iP).D2.curves.(thrField).values          = d2vals;
    end
end

end

%% =======================================================================
% Local helpers
% =======================================================================

function s = local_thrFieldName(thrGy)
s = ['thr_' regexprep(num2str(thrGy, 12), '\W', '_') 'Gy'];
end

function c = local_toCellstr(x, label)
if isempty(x)
    c = {};
    return;
end
if isstring(x)
    c = cellstr(x);
elseif ischar(x)
    c = {x};
elseif iscell(x)
    c = x;
else
    error('%s must be char, string array, cell array, or empty.', label);
end
end

function c = local_stripEmpty(c)
if isempty(c), return; end
c = c(:)';
c = c(~cellfun(@(s) isempty(s) || (isstring(s) && strlength(s)==0), c));
for i = 1:numel(c)
    if isstring(c{i}), c{i} = char(c{i}); end
end
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

function txt = local_joinAliases(aliases)
if ischar(aliases) || isstring(aliases)
    txt = char(string(aliases));
elseif iscell(aliases)
    tmp = cellfun(@(s) char(string(s)), aliases, 'UniformOutput', false);
    txt = strjoin(tmp, ', ');
else
    txt = '<unknown>';
end
end