function [report, fullTable] = matRad_planMetrics(cst, doses, doseNames, metrics, varargin)
% matRad_planMetrics - Compute selected + full QI metrics for multiple plans
%
% Syntax:
%   [report, fullTable] = matRad_planMetrics(cst, doses, doseNames, metrics)
%   [report, fullTable] = matRad_planMetrics(..., 'pln', pln)
%   [report, fullTable] = matRad_planMetrics(..., 'fullRefGy', 0:2:30, 'fullRefVol', [2 5 50 80 95 98])
%   [report, fullTable] = matRad_planMetrics(..., 'referenceCI', 18)
%
% Description:
%   Output 1 (report.summaryTable): compact table for exactly the metrics you request.
%   Output 2 (fullTable): broader table with all fields returned by matRad_calcQI
%   (V_*Gy values are converted to percent in fullTable).
%
% Metric rules:
%   - If metric ends with "_target": compute only for TARGET VOIs; others set to NaN.
%   - Otherwise: compute for ALL VOIs (note: CI is still only available for targets
%     because matRad_calcQI only computes CI for targets).
%
% Supported metric specs (case-insensitive):
%   - D2, D80, D95, D2_target ...
%   - V17Gy, V12_5Gy, V20Gy, V17Gy_target ...
%   - Mean, Std, Min, Max, Mean_target ...
%   - CI18Gy, CI18Gy_target ...
%
% Important note about CI:
%   matRad_calcQI computes CI for targets using either:
%     (a) inferred reference dose from objectives, or
%     (b) the scalar 'referenceCI' argument (6th input).
%   If you request CIxxGy metrics, this function will set referenceCI to that xx
%   (only one unique CI dose per call is supported).
%
% Reference entry:
% | `matRad_planMetrics` | `matRad_planMetrics` | Metrics report (selected + full) for multiple plans | `[rep,tbl] = matRad_planMetrics(cst,doses,{'Arc'},{'D2','V17Gy','CI18Gy_target'})` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

%% Parse inputs
p = inputParser;
p.addParameter('pln', []);
p.addParameter('fullRefVol', [2 5 10 20 50 80 90 95 98]);
p.addParameter('fullRefGy', []);
p.addParameter('referenceCI', []); % scalar dose (Gy) forwarded to matRad_calcQI as 6th input
p.parse(varargin{:});

pln         = p.Results.pln;
fullRefVol  = p.Results.fullRefVol;
fullRefGy   = p.Results.fullRefGy;
referenceCI = p.Results.referenceCI;

if isstring(doseNames), doseNames = cellstr(doseNames); end
if isstring(metrics),   metrics   = cellstr(metrics);   end

assert(iscell(doseNames) && all(cellfun(@ischar, doseNames)), 'doseNames must be cellstr.');
assert(iscell(metrics)   && all(cellfun(@ischar, metrics)),   'metrics must be cellstr.');

for i = 1:numel(doseNames)
    assert(isfield(doses, doseNames{i}), 'Dose "%s" not found in doses struct.', doseNames{i});
end

nVOI = size(cst,1);
voiNames = cst(:,2);

%% Identify targets
isTarget = false(nVOI,1);
if exist('matRad_VOITargetFindIx','file') == 2
    isTarget(matRad_VOITargetFindIx(cst)) = true;
else
    for v = 1:nVOI
        if size(cst,2) >= 3
            tag = cst{v,3};
            if ischar(tag) || isstring(tag)
                isTarget(v) = strcmp(tag,'TARGET') || strcmpi(tag,'TARGET');
            end
        end
    end
end

%% Parse metric specs
metricSpecs = local_normalizeMetricSpecs(metrics);

neededRefVol = [];
neededRefGy  = [];
neededCIDose = [];

for m = 1:numel(metricSpecs)
    switch metricSpecs(m).kind
        case "D"
            neededRefVol(end+1) = metricSpecs(m).value; %#ok<AGROW>
        case "V"
            neededRefGy(end+1)  = metricSpecs(m).value; %#ok<AGROW>
        case "CI"
            neededCIDose(end+1) = metricSpecs(m).value; %#ok<AGROW>
    end
end

neededRefVol = unique(neededRefVol);
neededRefGy  = unique(neededRefGy);
neededCIDose = unique(neededCIDose);

%% Decide referenceCI if CI is requested and user didn't pass it
if isempty(referenceCI) && ~isempty(neededCIDose)
    if numel(neededCIDose) ~= 1
        error(['Multiple CI doses requested (%s), but matRad_calcQI supports only one scalar referenceCI. ' ...
            'Call matRad_planMetrics once per CI dose, or remove CI metrics from this call.'], ...
            strjoin(string(neededCIDose), ', '));
    end
    referenceCI = neededCIDose(1);
end

if ~isempty(referenceCI)
    assert(isnumeric(referenceCI) && isscalar(referenceCI) && isfinite(referenceCI) && referenceCI > 0, ...
        '''referenceCI'' must be a positive scalar (Gy).');
end

%% Determine fullRefGy if not provided
maxDoseAll = max(cellfun(@(nm) max(doses.(nm)(:)), doseNames));
if isempty(fullRefGy)
    fullRefGy = 0:2:ceil(maxDoseAll);
end

%% Merge needed + full ref lists (single matRad_calcQI call per plan)
allRefVol = unique([neededRefVol, fullRefVol]);
allRefGy  = unique([neededRefGy,  fullRefGy]);

if isempty(allRefVol), allRefVol = 50; end
if isempty(allRefGy),  allRefGy  = 0;  end

%% Pre-allocate tables
nPlans = numel(doseNames);
nRows  = nPlans * nVOI;

summaryTbl = table( ...
    strings(nRows,1), strings(nRows,1), false(nRows,1), ...
    'VariableNames', {'Plan','VOI','isTarget'} );

for m = 1:numel(metricSpecs)
    summaryTbl.(metricSpecs(m).outName) = nan(nRows,1);
end

fullTable = table( ...
    strings(nRows,1), strings(nRows,1), false(nRows,1), ...
    'VariableNames', {'Plan','VOI','isTarget'} );

%% Compute QI per plan (single call each)
qiPerPlan = cell(nPlans,1);
for pIdx = 1:nPlans
    planName = doseNames{pIdx};
    doseCube = doses.(planName);
    qiPerPlan{pIdx} = matRad_calcQI(cst, pln, doseCube, allRefGy, allRefVol, referenceCI);
end

%% Fill summary table
row = 0;
for pIdx = 1:nPlans
    qi = qiPerPlan{pIdx};
    planName = doseNames{pIdx};

    for v = 1:nVOI
        row = row + 1;

        summaryTbl.Plan(row)     = string(planName);
        summaryTbl.VOI(row)      = string(voiNames{v});
        summaryTbl.isTarget(row) = isTarget(v);

        for m = 1:numel(metricSpecs)
            ms = metricSpecs(m);

            if ms.onlyTargets && ~isTarget(v) % not targets
                summaryTbl.(ms.outName)(row) = NaN;
                continue;
            end

            if ms.kind == "HI_V50" && ~isTarget(v)
                summaryTbl.(ms.outName)(row) = NaN;
                continue;
            end

            summaryTbl.(ms.outName)(row) = local_extractMetric(qi(v), ms);
        end
    end
end

%% Build full table columns (union of all QI fields)
allFields = {};
for pIdx = 1:nPlans
    qip = qiPerPlan{pIdx};
    for v = 1:nVOI
        allFields = union(allFields, fieldnames(qip(v)));
    end
end

% Drop fields we already represent explicitly
allFields = setdiff(allFields, {'name','numOfVoxels'});

for k = 1:numel(allFields)
    fullTable.(matlab.lang.makeValidName(allFields{k})) = nan(nRows,1);
end

%% Fill full table
row = 0;
for pIdx = 1:nPlans
    qi = qiPerPlan{pIdx};
    planName = doseNames{pIdx};

    for v = 1:nVOI
        row = row + 1;

        fullTable.Plan(row)     = string(planName);
        fullTable.VOI(row)      = string(voiNames{v});
        fullTable.isTarget(row) = isTarget(v);

        for k = 1:numel(allFields)
            fn = allFields{k};
            vname = matlab.lang.makeValidName(fn);

            if isfield(qi(v), fn)
                val = qi(v).(fn);
                if isnumeric(val) && isscalar(val)
                    % Convert V_*Gy to %
                    if startsWith(fn, 'V_') && endsWith(fn, 'Gy')
                        fullTable.(vname)(row) = val * 100;
                    else
                        fullTable.(vname)(row) = val;
                    end
                end
            end
        end
    end
end

% Round numeric columns to 2 decimals for display/exports
summaryTbl = local_roundNumericTable(summaryTbl, 2);
fullTable  = local_roundNumericTable(fullTable, 2);

%% Package report
report = struct();
report.summaryTable = summaryTbl;
report.doseNames    = doseNames;
report.metricSpecs  = {metricSpecs.raw};
report.voiNames     = voiNames;
report.isTarget     = isTarget;
report.referenceCI  = referenceCI;

end

%% ========================================================================
% local helpers
%% ========================================================================

function val = local_extractMetric(qiVOI, ms)
switch ms.kind
    case "Mean"
        val = local_getFieldOrNaN(qiVOI, 'mean');

    case "Std"
        val = local_getFieldOrNaN(qiVOI, 'std');

    case "Min"
        val = local_getFieldOrNaN(qiVOI, 'min');

    case "Max"
        val = local_getFieldOrNaN(qiVOI, 'max');

    case "D"
        f = sprintf('D_%g', ms.value);
        f = strrep(f, '.', '_');
        val = local_getFieldOrNaN(qiVOI, f);

    case "V"
        vf = local_vFieldName(ms.value);
        val = local_getFieldOrNaN(qiVOI, vf) * 100; % to %

    case "CI"
        cf = local_ciFieldName(ms.value);
        val = local_getFieldOrNaN(qiVOI, cf);

    case "HI_V50"
        val = local_getFieldOrNaN(qiVOI, 'HI_V50');

    otherwise
        error('Unsupported metric kind: %s', ms.kind);
end
end

function metricSpecs = local_normalizeMetricSpecs(metrics)
metricSpecs = struct('raw',{},'kind',{},'value',{},'onlyTargets',{},'outName',{});

for i = 1:numel(metrics)
    raw = strtrim(metrics{i});
    if isempty(raw), continue; end

    onlyTargets = endsWith(lower(raw), '_target');
    base = raw;
    if onlyTargets
        base = raw(1:end-7); % '_target' = 7 chars
    end
    base = strtrim(base);
    bLow = lower(base);

    ms = struct('raw', raw, 'onlyTargets', onlyTargets);

    if any(strcmp(bLow, {'mean','avg'}))
        ms.kind = "Mean"; ms.value = NaN;
        ms.outName = local_buildOutName("Mean", onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    elseif strcmp(bLow, 'std')
        ms.kind = "Std"; ms.value = NaN;
        ms.outName = local_buildOutName("Std", onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    elseif strcmp(bLow, 'min')
        ms.kind = "Min"; ms.value = NaN;
        ms.outName = local_buildOutName("Min", onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    elseif strcmp(bLow, 'max')
        ms.kind = "Max"; ms.value = NaN;
        ms.outName = local_buildOutName("Max", onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    end

    tok = regexp(bLow, '^d(?<x>\d+(\.\d+)?)$', 'names');
    if ~isempty(tok)
        ms.kind = "D"; ms.value = str2double(tok.x);
        ms.outName = local_buildOutName(sprintf('D%g_Gy', ms.value), onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    end

    tok = regexp(bLow, '^v(?<d>\d+(\.\d+)?)gy$', 'names');
    if ~isempty(tok)
        ms.kind = "V"; ms.value = str2double(tok.d);
        ms.outName = local_buildOutName(sprintf('V%gGy_pct', ms.value), onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    end

    tok = regexp(bLow, '^ci(?<d>\d+(\.\d+)?)gy$', 'names');
    if ~isempty(tok)
        ms.kind = "CI"; ms.value = str2double(tok.d);
        ms.outName = local_buildOutName(sprintf('CI%gGy', ms.value), onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    end


    % tok = regexp(bLow, '^ci(?<d>\d+(\.\d+)?)gy$', 'names');
    if any(strcmp(bLow, {'hi_v50','hiv50','hi50', 'hi', 'HI'}))
        ms.kind = "HI_V50"; ms.value = NaN;
        ms.outName = local_buildOutName("HI_V50", onlyTargets);
        metricSpecs(end+1) = ms; %#ok<AGROW>
        continue;
    end

    error('Unsupported metric spec: "%s". Examples: D2, V17Gy, Mean_target, CI18Gy_target', raw);
end
end

function outName = local_buildOutName(baseName, onlyTargets)
if onlyTargets
    outName = [baseName '_target'];
else
    outName = baseName;
end
outName = matlab.lang.makeValidName(outName);
end

function vField = local_vFieldName(doseGy)
sRef = num2str(doseGy,3);
vField = ['V_' strrep(sRef,'.','_') 'Gy'];
end

function T = local_roundNumericTable(T, nDecimals)
% local_roundNumericTable - Round all numeric variables in a table
%
% Inputs:
%   T         - table
%   nDecimals - number of decimals (e.g., 2)
%
% Output:
%   T - table with numeric columns rounded

vars = T.Properties.VariableNames;

for k = 1:numel(vars)
    v = T.(vars{k});

    % Only round numeric arrays; skip logical, strings, categoricals, cells, etc.
    if isnumeric(v)
        T.(vars{k}) = round(v, nDecimals);
    end
end
end

function T = local_formatNumericTable(T, nDecimals)
% local_formatNumericTable - Convert numeric columns to strings with fixed decimals
fmt = sprintf('%%.%df', nDecimals);

vars = T.Properties.VariableNames;
for k = 1:numel(vars)
    v = T.(vars{k});
    if isnumeric(v)
        % preserve NaNs as <missing>
        s = strings(size(v));
        isOk = isfinite(v);
        s(isOk) = string(compose(fmt, v(isOk)));
        s(~isOk) = missing;
        T.(vars{k}) = s;
    end
end
end

function cField = local_ciFieldName(doseGy)
% Must match matRad_calcQI naming: CI_<regexprep(num2str(round(d*100)/100),'\D','_')>Gy
s = regexprep(num2str(round(doseGy*100)/100), '\D', '_');
cField = ['CI_' s 'Gy'];
end

function val = local_getFieldOrNaN(S, field)
if isfield(S, field)
    val = S.(field);
    if ~(isnumeric(val) && isscalar(val))
        val = NaN;
    end
else
    val = NaN;
end
end