function flaggedStruct = reportOARDeviations(cst, qiCurr, qiPat, VOINames, metricsToCheck)
%REPORTOARDEVIATIONS Compare specified OAR metrics and identify significant deviations.
%
%   flaggedStruct = reportOARDeviations(cst, qiCurr, qiPat, VOINames, metricsToCheck)
%
%   Inputs:
%       cst            - Constraint structure table (cell array)
%       qiCurr         - Quality indicators from current plan
%       qiPat          - Reference quality indicators (e.g., original patient plan)
%       VOINames       - Struct with fields like PTV, External, Heart, Spine, etc.
%       metricsToCheck - Cell array of metric names to compare (e.g., {'D_2','D_98','mean'})
%
%   Output:
%       flaggedStruct  - Struct array with deviations >15% for specified metrics
%                        (fields: name, metric, ref, curr, percent)

    if nargin < 5 || isempty(metricsToCheck)
        metricsToCheck = {'D_2','D_98','mean'}; % default metrics
    end

    fprintf('📋 Comparing OAR metrics (vs. reference)...\n\n');

    OARFields = fieldnames(VOINames);
    OARFields = setdiff(OARFields, {'PTV', 'External'});  % exclude PTV and External

    relDiffs = struct('name', {}, 'metric', {}, 'ref', {}, 'curr', {}, 'percent', {});
    iDiff = 1;

    for i = 1:numel(OARFields)
        oarName = OARFields{i};
        matches = contains(cst(:,2), VOINames.(oarName));
        if ~any(matches)
            continue;
        end

        idx = find(matches, 1);
        qiC = qiCurr(idx);
        qiR = qiPat(idx);
        name = qiC.name;

        for j = 1:numel(metricsToCheck)
            m = metricsToCheck{j};
            if isfield(qiC, m) && isfield(qiR, m)
                vC = qiC.(m);
                vR = qiR.(m);
                if isnumeric(vC) && isnumeric(vR) && ~isempty(vR) && vR ~= 0
                    diffPercent = 100 * (vC - vR) / vR;
                    relDiffs(iDiff).name = name;
                    relDiffs(iDiff).metric = m;
                    relDiffs(iDiff).ref = vR;
                    relDiffs(iDiff).curr = vC;
                    relDiffs(iDiff).percent = diffPercent;
                    iDiff = iDiff + 1;
                end
            end
        end
    end

    % Print results
    fprintf('%-25s %-10s %-10s %-10s %-10s\n', 'Structure', 'Metric', 'Ref', 'Curr', 'Diff (%)');
    fprintf('%s\n', repmat('-',1,70));
    for k = 1:numel(relDiffs)
        fprintf('%-25s %-10s %-10.2f %-10.2f %+8.1f%%\n', ...
            relDiffs(k).name, relDiffs(k).metric, ...
            relDiffs(k).ref, relDiffs(k).curr, relDiffs(k).percent);
    end

    % Identify large deviations (>15%)
    flagged = abs([relDiffs.percent]) > 15;
    flaggedStruct = relDiffs(flagged);
end
