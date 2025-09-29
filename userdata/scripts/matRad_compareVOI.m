function [report, relDiffs] = matRad_compareVOI(cst, qi, qiReference, metricsToCheck, printOnlyFlagged, showObjectives)
% matRad_compareVOI - Compares OAR metrics and optionally prints CST objectives
%
% Syntax:  report = matRad_compareVOI(cst, qi, qiReference, metricsToCheck, printOnlyFlagged, showObjectives)
%
% Inputs:
%   cst             - Constraint structure table (cell array)
%   qi              - Current quality indicators (struct)
%   qiReference     - Reference quality indicators (struct)
%   metricsToCheck  - Metrics to compare (cell array, optional)
%   printOnlyFlagged- Only print flagged deviations (logical, optional)
%   showObjectives  - Show CST objectives (logical, optional)
%
% Outputs:
%   report   - Structure of flagged deviations (struct array)
%
% Other m-files required: none
% Subfunctions: formatCSTObjectiveLine
% MAT-files required: none
%
% See also: printCSTObjectives
%
    if nargin < 4 || isempty(metricsToCheck)
        metricsToCheck = {'D_2','D_98','mean'}; 
    end
    if nargin < 5
        printOnlyFlagged = false;
    end
    if nargin < 6
        showObjectives = false;
    end

    fprintf('\n%-4s %-25s %-10s %-10s %-10s %-10s\n', ...
        'Idx', 'Structure', 'Metric', 'Ref', 'Curr', 'Diff (%)');
    fprintf('%s\n', repmat('-',1, 80));

        VOIFields = cst(:, 2);
    % VOIFields = setdiff(cst(:, 2), {'External'});
    relDiffs = struct('idx', {}, 'name', {}, 'metric', {}, ...
                      'ref', {}, 'curr', {}, 'percent', {}, 'absDiff', {});
    iDiff = 1;

    % Process all OARs
    for i = 1:numel(VOIFields)
        oarName = VOIFields{i};
        matches = contains(cst(:,2), oarName); % VOINames.(oarName).Aliases);

        if ~any(matches)
            continue;
        end

        idx = find(matches, 1);
        qiC = qi(idx);
        qiR = qiReference(idx);
        name = qiC.name;

        for j = 1:numel(metricsToCheck)
            m = metricsToCheck{j};
            if isfield(qiC, m) && isfield(qiR, m)
                vC = qiC.(m);
                vR = qiR.(m);
                if isnumeric(vC) && isnumeric(vR) && ~isempty(vR) && vR ~= 0
                    diffPercent = 100 * (vC - vR) / vR;
                    absDiff = abs(vC - vR);
                    relDiffs(iDiff).idx = idx;
                    relDiffs(iDiff).name = name;
                    relDiffs(iDiff).metric = m;
                    relDiffs(iDiff).ref = vR;
                    relDiffs(iDiff).curr = vC;
                    relDiffs(iDiff).percent = diffPercent;
                    relDiffs(iDiff).absDiff = absDiff;
                    iDiff = iDiff + 1;
                end
            end
        end
    end

    % Determine which entries are flagged
    flagged = abs([relDiffs.percent]) > 15 & [relDiffs.absDiff] > 2;
    report = relDiffs(flagged);

    % Group results by VOI idx
    if isempty(relDiffs)
        return;
    end

    uniqueIdx = unique([relDiffs.idx]);

    for i = 1:numel(uniqueIdx)
        idx = uniqueIdx(i);
        rows = find([relDiffs.idx] == idx);

        % Skip if all unflagged and we're only printing flagged
        if printOnlyFlagged && all(~flagged(rows))
            continue;
        end

        for r = rows
            fprintf('%-4d %-25s %-10s %-10.2f %-10.2f %+8.1f%%\n', ...
                relDiffs(r).idx, relDiffs(r).name, relDiffs(r).metric, ...
                relDiffs(r).ref, relDiffs(r).curr, relDiffs(r).percent);
        end

        % Print objectives once per VOI
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
        paramStr = strjoin(cellfun(@(x) num2str(x, '%.2f'), obj.parameters, 'UniformOutput', false), ', ');
    else
        paramStr = num2str(obj.parameters);
    end

    penalty = obj.penalty;
end