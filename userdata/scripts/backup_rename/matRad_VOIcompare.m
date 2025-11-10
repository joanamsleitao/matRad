function [report, relDiffs] = matRad_VOIcompare(cst, qi, qiReference, metricsToCheck, printOnlyFlagged, showObjectives)
% matRad_compareVOI - Compares VOI metrics between a plan and a reference.
%
% Matches VOIs by name (case-insensitive), ensuring correct comparisons even
% if CST, qi, and qiReference have different VOI orders or counts.
%
% If a matching dose objective is found in the CST for a given metric,
% its short string (e.g. 'D_50 minDVH 28.70Gy 250.0') is displayed.
%
% Inputs:
%   cst             - CST (cell array)
%   qi              - Current quality indicators (struct array)
%   qiReference     - Reference quality indicators (struct array)
%   metricsToCheck  - Metrics to compare (cell array, optional)
%   printOnlyFlagged- Only print flagged deviations (logical, optional)
%   showObjectives  - Show CST objectives (logical, optional)
%
% Outputs:
%   report   - Structure of flagged deviations (with metricString)
%   relDiffs - Full comparison table

if nargin < 4 || isempty(metricsToCheck)
    metricsToCheck = {'D_2','D_98','mean'};
end
if nargin < 5
    printOnlyFlagged = false;
end
if nargin < 6
    showObjectives = false;
end

fprintf('\n%-4s %-25s %-10s %-10s %-10s %-10s %-35s\n', ...
    'Idx', 'Structure', 'Metric', 'Ref', 'Curr', 'Diff (%)', 'MetricString');
fprintf('%s\n', repmat('-',1, 120));

relDiffs = struct('idx', {}, 'name', {}, 'metric', {}, ...
    'ref', {}, 'curr', {}, 'percent', {}, ...
    'absDiff', {}, 'metricString', {});
iDiff = 1;

% === Extract CST objective strings ===
try
    [~, objStructs] = matRad_cstExtractDoseObjectives(cst);
catch
    warning('Could not extract CST objectives; metricString output will be blank.');
    objStructs = [];
end

% Create lookup maps for qi and qiReference by name
qiNames = lower(string({qi.name}));
qiRefNames = lower(string({qiReference.name}));

% === Main loop ===
for i = 1:size(cst,1)
    voiName = lower(string(cst{i,2}));
    if strcmpi(voiName, 'external')
        continue;
    end

    idxCurr = find(strcmp(qiNames, voiName), 1);
    idxRef  = find(strcmp(qiRefNames, voiName), 1);
    if isempty(idxCurr) || isempty(idxRef)
        fprintf('Skipping %s (missing in qi or reference)\n', cst{i,2});
        continue;
    end

    qiC = qi(idxCurr);
    qiR = qiReference(idxRef);
    name = qiC.name;

    % --- Get CST objective strings for this VOI ---
    voiMetricStrings = {};
    if ~isempty(objStructs) && numel(objStructs) >= i
        voiMetricStrings = objStructs(i).metrics;  % <-- directly use metrics field
    end

    for j = 1:numel(metricsToCheck)
        m = metricsToCheck{j};
        if isfield(qiC, m) && isfield(qiR, m)
            vC = qiC.(m);
            vR = qiR.(m);
            if isnumeric(vC) && isnumeric(vR) && ~isempty(vR) && vR ~= 0
                diffPercent = 100 * (vC - vR) / vR;
                absDiff = abs(vC - vR);

                % --- Try to find a matching CST objective string ---
                matchedStr = '';
                if ~isempty(voiMetricStrings)
                    for s = 1:numel(voiMetricStrings)
                        if contains(voiMetricStrings{s}, m, 'IgnoreCase', true)
                            matchedStr = voiMetricStrings{s};
                            break;
                        end
                    end
                end

                relDiffs(iDiff).idx = i;
                relDiffs(iDiff).name = name;
                relDiffs(iDiff).metric = m;
                relDiffs(iDiff).ref = vR;
                relDiffs(iDiff).curr = vC;
                relDiffs(iDiff).percent = diffPercent;
                relDiffs(iDiff).absDiff = absDiff;
                relDiffs(iDiff).metricString = matchedStr;
                iDiff = iDiff + 1;
            end
        end
    end
end

% === Flagging and reporting ===
if isempty(relDiffs)
    report = [];
    fprintf('No valid comparisons found.\n');
    return;
end

flagged = abs([relDiffs.percent]) > 15 & [relDiffs.absDiff] > 2;
report = relDiffs(flagged);

uniqueIdx = unique([relDiffs.idx]);
for i = 1:numel(uniqueIdx)
    idx = uniqueIdx(i);
    rows = find([relDiffs.idx] == idx);
    if isempty(printOnlyFlagged) && all(~flagged(rows))
        continue;
    end

    for r = rows
        fprintf('%-4d %-15s %-10s %-10.2f %-10.2f %+8.1f%% %+35s\n', ...
            relDiffs(r).idx, relDiffs(r).name, relDiffs(r).metric, ...
            relDiffs(r).ref, relDiffs(r).curr, relDiffs(r).percent, ...
            relDiffs(r).metricString);
    end

    if showObjectives
        objectives = cst{idx, 6};
        if isempty(objectives)
            fprintf('     [no objectives]\n');
        else
            for iObj = 1:numel(objectives)
                obj = objectives{iObj};
                [className, paramStr, penalty] = formatCSTObjectiveLine(obj);
                fprintf('     -> %-30s Params: %-18s Penalty: %.2f\n', ...
                    className, paramStr, penalty);
            end
        end
    end
end
end


function [className, paramStr, penalty] = formatCSTObjectiveLine(obj)
className = obj.className;
if iscell(obj.parameters)
    paramStr = strjoin(cellfun(@(x) num2str(x, '%.2f'), ...
        obj.parameters, 'UniformOutput', false), ', ');
else
    paramStr = num2str(obj.parameters);
end
penalty = obj.penalty;
end