function printCSTObjectives(cst, rowIndices)
%PRINTCSTOBJECTIVES Print a table of dose objectives for given CST rows.
%
% Inputs:
%   cst         - Constraint structure table (matRad CST)
%   rowIndices  - Index or indices of rows to inspect (e.g., 3 or [3 7])

    if nargin < 2 || isempty(rowIndices)
        rowIndices = 1:size(cst, 1);
    end

    fprintf('\n%-4s %-25s %-40s %-20s %-8s\n', ...
        'Idx', 'Structure', 'Objective (className)', 'Parameters', 'Penalty');
    fprintf('%s\n', repmat('-', 1, 110));

    for idx = rowIndices(:)'  % ensure it's a row vector
        structureName = cst{idx, 2};
        objectives = cst{idx, 6};

        if isempty(objectives)
            fprintf('%-4d %-25s %-40s %-20s %-8s\n', ...
                idx, structureName, '[no objectives]', '-', '-');
            continue;
        end

        for iObj = 1:numel(objectives)
            obj = objectives{iObj};
            [className, paramStr, penalty] = formatCSTObjectiveLine(obj);

            fprintf('%-4d %-25s %-40s %-20s %-8.2f\n', ...
                idx, structureName, className, paramStr, penalty);
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