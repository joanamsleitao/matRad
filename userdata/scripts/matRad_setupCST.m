function [cst, prescribedDose] = matRad_setupCST(cst, VOINames, VOISites, mode)
% matRad_setupCST - Validates and updates CST with colors and structure info
%
% Syntax:  [cst, prescribedDose, ixPTV, ixExternal] = setupCSTandPrescribedDose(cst, mode)
%
% Inputs:
%   cst  - Constraint structure table (cell array)
%   mode - Operation mode ('STAR' or empty) (string, optional)
%
% Outputs:
%   cst             - Updated CST (cell array)
%   prescribedDose  - Prescribed dose from PTV (double)
%   ixPTV           - Index of PTV in CST (integer)
%   ixExternal      - Index of External structure in CST (integer)
%
% Other m-files required: parseStructureFile.m
% Subfunctions: none
% MAT-files required: none
%
% See also: parseStructureFile
%
if nargin < 4
    mode = '';
end

% Handle EXTERNAL structure
ixExternalMatches = find(contains(cst(:,2), VOINames.External.Aliases));
               
if isempty(ixExternalMatches)
    warning('No EXTERNAL structure defined!');
    ixExternal = [];
else
    if numel(ixExternalMatches) > 1
        warning('Multiple EXTERNAL structures found. Using the exact match.');
    end
    % If multiple matches, try to refine using exact match
    if numel(ixExternalMatches) > 1
        exactMatches = find(ismember(cst(:,2), VOINames.External.Aliases));
        if ~isempty(exactMatches)
            ixExternalMatches = exactMatches;
        end
    end

    ixExternal = ixExternalMatches(1);
    cst{ixExternal, 3}  = 'EXTERNAL';
    cst{ixExternal, 5}.Priority  = size(cst,1) + 3;
    cst{ixExternal, 5}.visibleColor = VOINames.External.Color;
end

% Handle PTV structure
ixPTV = find(contains(cst(:,2), VOINames.PTV.Aliases), 1);
if isempty(ixPTV) || ixPTV == 0
    warning('PTV not found in CST!');
    prescribedDose = 0;
else
    prescribedDose = cst{ixPTV, 6}{1, 1}.parameters{1};
    cst{ixPTV, 5}.visibleColor = VOINames.PTV.Color;
end

% Cleans all previous objectives
cst(:, 6) = [];

%% Modes
% Handle STAR mode
if strcmpi(mode, 'STAR')
    allowedNames = VOISites.(mode);
    newCST = {};
    matched = {};
    missing = {};

    for i = 1:numel(allowedNames)
        name = allowedNames{i};
        found = false;
        for f = fieldnames(VOINames)'
            field = f{1};
            if isfield(VOINames.(field), 'Aliases') && any(strcmpi(name, VOINames.(field).Aliases))
                ixVOI = find(contains(cst(:,2), VOINames.(field).Aliases), 1);
                if ~isempty(ixVOI)
                    entry = cst(ixVOI,:);
                    entry{2} = field;  % Rename to canonical name
                    entry{5}.visibleColor = VOINames.(field).Color;  % Assign color
                    newCST = [newCST; entry];
                    matched{end+1} = name;
                    found = true;
                    break;
                end
            end
        end
        if ~found
            missing{end+1} = name;
        end
    end
    fprintf('\n--- STAR mode summary ---\n');
    fprintf('Matched VOIs:\n'); fprintf('   ✓ %s\n', matched{:});
    fprintf('Missing VOIs:\n'); fprintf('   ✗ %s\n', missing{:});
    fprintf('--------------------------\n\n');

    cst = newCST;
    % Update PTV index after filtering
    ixPTV = find(strcmp(cst(:,2), 'PTV'), 1);
    ixExternal = find(strcmp(cst(:,2), 'External'), 1);

    % Handle STAR mode
elseif strcmpi(mode, 'SPINE')
    allowedNames = VOISites.(mode);
    newCST = {};
    matched = {};
    missing = {};

    ix = 0;
    for i = 1:numel(allowedNames)
        name = allowedNames{i};
        found = false;
        for f = fieldnames(VOINames)'
            field = f{1};
            if isfield(VOINames.(field), 'Aliases') && any(strcmpi(name, VOINames.(field).Aliases))
                ixVOI = find(contains(cst(:,2), VOINames.(field).Aliases));

                % If multiple matches, try to refine using exact match
                if numel(ixVOI) > 1
                    exactMatches = find(ismember(cst(:,2), VOINames.(field).Aliases));
                    if ~isempty(exactMatches)
                        ixVOI = exactMatches;
                    end
                end
                if ~isempty(ixVOI)
                    entry = cst(ixVOI,:);
                    entry{1} = ix;
                    entry{2} = field;  % Rename to canonical name
                    entry{5}.visibleColor = VOINames.(field).Color;  % Assign color
                    newCST = [newCST; entry];
                    matched{end+1} = name;
                    found = true;
                    ix = ix + 1;
                    break;
                end
            end
        end
        if ~found
            missing{end+1} = name;
        end
    end
    fprintf('\n--- Spine mode summary ---\n');
    fprintf('Matched VOIs:\n'); fprintf('   ✓ %s\n', matched{:});
    fprintf('Missing VOIs:\n'); fprintf('   ✗ %s\n', missing{:});
    fprintf('--------------------------\n\n');

    cst = newCST;
    % Update PTV index after filtering
    ixPTV = find(strcmp(cst(:,2), 'PTV'), 1);
    ixExternal = find(strcmp(cst(:,2), 'External'), 1);


end


end
