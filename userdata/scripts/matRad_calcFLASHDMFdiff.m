function out = matRad_calcFLASHDMFdiff(patientID, ct, cst, doses, slice, dmfValue, thrGyVec, varargin)
% matRad_calcFLASHDMFdiff - Precompute FLASH mask + DMF-applied dose and delta-dose for multiple thresholds
%
% Syntax:
%   out = matRad_calcFLASHDMFdiff(patientID, ct, cst, doses, slice, dmfValue, thrGyVec)
%   out = matRad_calcFLASHDMFdiff(..., 'voiSelection', ixTarget, 'includeHealthy', true)
%   out = matRad_calcFLASHDMFdiff(..., 'nominalName','combinedNoDMF', 'arcCompName','compArc', 'flashName','flashNoDMF')
%   out = matRad_calcFLASHDMFdiff(..., 'doseWindow',[0 30], 'deltaWindow',[-3 0])
%
% Description:
%   Computes, for each threshold in thrGyVec:
%     - FLASH mask from doses.(flashName) thresholded at thrGy
%     - DMF-applied total dose: doses.(arcCompName) + DMF(doses.(flashName), mask, dmfValue)
%     - Delta dose: DMF-applied total - nominal(noDMF)
%       Negative values => dose reduction due to DMF (labeled as "advantage")
%
% Outputs:
%   out.deltaDose{i} is NEGATIVE where dose is reduced vs nominal.
%
% Reference entry:
% | `matRad_calcFLASHDMFdiff` | `matRad_calcFLASHDMFdiff` | Precompute DMF dose + delta-dose across thresholds | `out=matRad_calcFLASHDMFdiff('Sp03',ct,cst,doses,sl,1.6,[4 6 8])` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

%% Options
p = inputParser;
p.addParameter('voiSelection', [], @(x) isempty(x) || (isnumeric(x) && all(isfinite(x)) && all(x==round(x)) && all(x>=1)));
p.addParameter('includeHealthy', true, @(x) islogical(x) && isscalar(x));
p.addParameter('nominalName', 'combinedNoDMF', @(s) ischar(s) || isstring(s));
p.addParameter('arcCompName', 'compArc', @(s) ischar(s) || isstring(s));
p.addParameter('flashName', 'flashNoDMF', @(s) ischar(s) || isstring(s));
p.addParameter('doseWindow', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.addParameter('deltaWindow', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.parse(varargin{:});
opts = p.Results;

%% Validate core inputs
if ~isnumeric(slice) || ~isscalar(slice) || ~isfinite(slice) || slice < 1 || slice ~= round(slice)
    error('slice must be a positive integer.');
end
if ~isnumeric(dmfValue) || ~isscalar(dmfValue) || ~isfinite(dmfValue) || dmfValue <= 0
    error('dmfValue must be a positive scalar.');
end
if ~isnumeric(thrGyVec) || isempty(thrGyVec) || any(~isfinite(thrGyVec)) || any(thrGyVec <= 0)
    error('thrGyVec must be a non-empty vector of positive thresholds in Gy.');
end

thrGyVec = unique(thrGyVec(:)','stable');
nThr = numel(thrGyVec);

nominalName = char(string(opts.nominalName));
arcCompName = char(string(opts.arcCompName));
flashName   = char(string(opts.flashName));

local_assertFieldsExist(doses, {nominalName, arcCompName, flashName}, 'doses');

nominalDose = doses.(nominalName);
arcComp     = doses.(arcCompName);
flashNoDMF  = doses.(flashName);

%% Compute abs + delta per threshold
flashMask = cell(1,nThr);
absDose   = cell(1,nThr);
deltaDose = cell(1,nThr);
nVoxMask  = zeros(1,nThr);

for iT = 1:nThr
    thrGy = thrGyVec(iT);

    [m, ~, ~] = matRad_flashVoxels(cst, flashNoDMF, thrGy, opts.voiSelection, opts.includeHealthy);
    m = logical(m);

    flashWithDMF = matRad_flashApplyDMF(flashNoDMF, m, dmfValue);
    totWithDMF   = arcComp + flashWithDMF;

    flashMask{iT} = m;
    absDose{iT}   = totWithDMF;

    % NEW sign convention: negative = advantage (lost dose vs nominal)
    deltaDose{iT} = totWithDMF - nominalDose;

    nVoxMask(iT) = nnz(m);
end

%% Windows
if isempty(opts.doseWindow)
    mx = max(nominalDose(:), [], 'omitnan');
    for iT = 1:nThr
        mx = max(mx, max(absDose{iT}(:), [], 'omitnan'));
    end
    if ~isfinite(mx), mx = 0; end
    doseWindow = [0 ceil(mx)];
else
    doseWindow = opts.doseWindow;
end

if isempty(opts.deltaWindow)
    % Expect mostly <= 0; set window [-maxAbs 0]
    mxAbs = 0;
    for iT = 1:nThr
        dd = deltaDose{iT};
        dd = dd(isfinite(dd));
        if ~isempty(dd)
            mxAbs = max(mxAbs, max(abs(dd)));
        end
    end
    if ~isfinite(mxAbs) || mxAbs <= 0
        mxAbs = 1;
    end
    deltaWindow = [-mxAbs 0];
else
    deltaWindow = opts.deltaWindow;
end

%% Pack output
out = struct();
out.patientID      = char(string(patientID));
out.slice          = slice;
out.dmfValue       = dmfValue;
out.thrGyVec       = thrGyVec;

out.nominalName    = nominalName;
out.arcCompName    = arcCompName;
out.flashName      = flashName;

out.voiSelection   = opts.voiSelection;
out.includeHealthy = opts.includeHealthy;

out.doseWindow     = doseWindow;
out.deltaWindow    = deltaWindow;

out.nominalDose    = nominalDose;
out.flashMask      = flashMask;
out.absDose        = absDose;
out.deltaDose      = deltaDose;
out.nVoxMask       = nVoxMask;

% keep for self-contained plotting
out.ct             = ct;
out.cst            = cst;

end

%% =======================================================================
% Local helpers
% =======================================================================

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