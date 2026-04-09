function out = matRad_FLASHROIvsDMF_D003cc(patientIDs, varargin)
% matRad_FLASHROIvsDMF - Compute Spine D0.03cc vs DMF curves and FLASH ROI stats
%
% Syntax:
%   out = matRad_FLASHROIvsDMF(patientIDs)
%   out = matRad_FLASHROIvsDMF(patientIDs, 'dmfStep', 0.05)
%   out = matRad_FLASHROIvsDMF(patientIDs, 'dmfRange', [1.1 1.8], 'doseThresholdsGy', [4 6 8])
%
% Description:
%   Loads rescaled dose components via loadPatientICR(patientID,'rescaled'),
%   then computes:
%     - constant D0.03cc(spine) for Arc and combinedNoDMF
%     - variable D0.03cc(spine) for a DMF sweep applied only to FLASH component,
%       for multiple thresholds on flashNoDMF dose.
%
% Inputs:
%   patientIDs - char/string (single) OR cellstr/string array
%
% Name-Value Pairs:
%   'doseThresholdsGy' - [4 6 8] by default
%   'dmfRange'         - [1.1 1.8] by default
%   'dmfStep'          - 0.05 by default
%   'absVolCC'         - absolute volume [cc] for dose metric, default 0.03
%   'spineAliases'     - aliases for matRad_VOIFindIx
%   'includeHealthy'   - default true
%
% Outputs:
%   out - struct array (one per patient):
%         .patientID
%         .spineVoiIx / .spineVoiName
%         .absVolCC                              queried absolute volume [cc]
%         .thresholdsGy
%         .dmf.values / .dmf.range / .dmf.step
%         .D003cc.Arc                            D0.03cc for Arc plan [Gy]
%         .D003cc.combinedNoDMF                  D0.03cc for combined no-DMF [Gy]
%         .D003cc.curves.thr_XGy.doseThresholdGy
%         .D003cc.curves.thr_XGy.values          (1 x nDMF)
%         .maskStats.thr_XGy.doseThresholdGy
%         .maskStats.thr_XGy.nVoxMask
%
% Reference entry:
% | `matRad_FLASHROIvsDMF` | `matRad_FLASHROIvsDMF` | Spine D0.03cc vs DMF + FLASH ROI stats | `out = matRad_FLASHROIvsDMF({'Sp01','Sp02'})` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

%% Options
p = inputParser;
p.addParameter('doseThresholdsGy', [4 6 8], @(x) isnumeric(x) && isvector(x) && all(isfinite(x)) && all(x>0));
p.addParameter('dmfRange', [1.1 1.8], @(x) isnumeric(x) && numel(x)==2 && all(isfinite(x)) && x(2)>x(1));
p.addParameter('dmfStep', 0.05, @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x>0);
p.addParameter('absVolCC', 0.03, @(x) isnumeric(x) && isscalar(x) && x>0);
p.addParameter('spineAliases', {'SpinalCord','spinal cord','spinalcord','SpineCanal','spine canal','spine'}, ...
    @(x) ischar(x) || isstring(x) || iscell(x));
p.addParameter('minIslandVox3D', 3, @(x) isnumeric(x) && isscalar(x) && x>=0); %#ok<NASGU>
p.addParameter('minAreaVox2D', 3, @(x) isnumeric(x) && isscalar(x) && x>=0); %#ok<NASGU>
p.addParameter('includeHealthy', true, @(x) islogical(x) && isscalar(x));
p.parse(varargin{:});
opts = p.Results;

patientIDs = local_toCellstr(patientIDs, 'patientIDs');
patientIDs = local_stripEmpty(patientIDs);
if isempty(patientIDs)
    error('patientIDs cannot be empty.');
end

doseThresholdsGy = unique(opts.doseThresholdsGy(:)', 'stable');
dmfVals = opts.dmfRange(1):opts.dmfStep:opts.dmfRange(2);
dmfVals = round(dmfVals, 10);

nP   = numel(patientIDs);
nThr = numel(doseThresholdsGy);

%% Prealloc output
out = repmat(struct( ...
    'patientID', '', ...
    'spineVoiIx', [], ...
    'spineVoiName', '', ...
    'absVolCC', opts.absVolCC, ...
    'D003cc', struct('Arc', NaN, 'combinedNoDMF', NaN, 'curves', struct()), ...
    'dmf', struct('values', dmfVals, 'range', opts.dmfRange, 'step', opts.dmfStep), ...
    'thresholdsGy', doseThresholdsGy, ...
    'maskStats', struct()), nP, 1);

%% Loop patients
for iP = 1:nP
    patientID = patientIDs{iP};
    out(iP).patientID = patientID;
    out(iP).absVolCC  = opts.absVolCC;

    % Load rescaled dose components
    [ct, cst, dosesRes] = loadPatientICR(patientID, 'rescaled');
    dosesRes.combinedNoDMF = dosesRes.compArc + dosesRes.flashNoDMF;

    % Find spine VOI
    ixSpine = matRad_VOIFindIx(cst, 'Cord');
    if isempty(ixSpine) || ~isscalar(ixSpine)
        error('Could not find a spine VOI for patient %s using aliases: %s', ...
            patientID, local_joinAliases(opts.spineAliases));
    end
    out(iP).spineVoiIx   = ixSpine;
    out(iP).spineVoiName = string(cst{ixSpine,2});

    % Validate required dose fields
    local_assertFieldsExist(dosesRes, {'Arc','combinedNoDMF','compArc','flashNoDMF'}, ...
        sprintf('dosesRes (%s)', patientID));

    % Constant D0.03cc for baseline plans
    out(iP).D003cc.Arc           = local_getDabsVol(dosesRes.Arc,           cst, ixSpine, opts.absVolCC, ct);
    out(iP).D003cc.combinedNoDMF = local_getDabsVol(dosesRes.combinedNoDMF, cst, ixSpine, opts.absVolCC, ct);

    % Threshold curves
    for iT = 1:nThr
        thrGy    = doseThresholdsGy(iT);
        thrField = local_thrFieldName(thrGy);

        % FLASH mask at this threshold
        [flashMask, ~, ~] = matRad_flashVoxels( ...
            cst, dosesRes.flashNoDMF, thrGy, ixSpine, opts.includeHealthy);
        flashMask = logical(flashMask);
        nVoxMask  = nnz(flashMask);

        % Allocate curve
        d003ccVals = nan(size(dmfVals));

        if nVoxMask == 0
            % No FLASH voxels -> dose unchanged for any DMF
            d003ccVals(:) = out(iP).D003cc.combinedNoDMF;
        else
            for iD = 1:numel(dmfVals)
                dmf          = dmfVals(iD);
                flashWithDMF = matRad_flashApplyDMF(dosesRes.flashNoDMF, flashMask, dmf);
                doseTot      = dosesRes.compArc + flashWithDMF;
                d003ccVals(iD) = local_getDabsVol(doseTot, cst, ixSpine, opts.absVolCC, ct);
            end
        end

        % Store curve
        out(iP).D003cc.curves.(thrField).doseThresholdGy = thrGy;
        out(iP).D003cc.curves.(thrField).values          = d003ccVals;

        % Store mask stats
        out(iP).maskStats.(thrField).doseThresholdGy = thrGy;
        out(iP).maskStats.(thrField).nVoxMask        = nVoxMask;
    end
end

end

%% =======================================================================
% Local helpers
% =======================================================================

function val = local_getDabsVol(doseCube, cst, ixVoi, absVolCC, ct)
% Extract D(absVolCC) for a single VOI using matRad_calcDabsVol
res = matRad_calcDabsVol(doseCube, cst(ixVoi,:), absVolCC, ct);
% Get the auto-generated field name (first non-standard field)
flds = fieldnames(res);
metricFld = flds(~ismember(flds, {'name','absVolCC','voxVolCC'}));
if isempty(metricFld)
    val = NaN;
else
    val = res(1).(metricFld{1});
end
end

function s = local_thrFieldName(thrGy)
s = ['thr_' regexprep(num2str(thrGy, 12), '\W', '_') 'Gy'];
end

function c = local_toCellstr(x, label)
if isempty(x), c = {}; return; end
if isstring(x),     c = cellstr(x);
elseif ischar(x),   c = {x};
elseif iscell(x),   c = x;
else, error('%s must be char, string array, cell array, or empty.', label);
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
    if ~isfield(S, names{i}), missing{end+1} = names{i}; end %#ok<AGROW>
end
if ~isempty(missing)
    error('Missing field(s) in %s: %s', structLabel, strjoin(missing, ', '));
end
end

function txt = local_joinAliases(aliases)
if ischar(aliases) || isstring(aliases), txt = char(string(aliases));
elseif iscell(aliases)
    txt = strjoin(cellfun(@(s) char(string(s)), aliases, 'UniformOutput', false), ', ');
else, txt = '<unknown>';
end
end