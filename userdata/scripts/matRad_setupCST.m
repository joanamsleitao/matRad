function [cst, prescribedDose] = matRad_setupCST(cst, VOINames, VOISites, mode)
% matRad_setupCST - Validates and updates CST with colors and structure info
%
% Syntax:  [cst, prescribedDose] = matRad_setupCST(cst, VOINames, VOISites, mode)
%
% Inputs:
%   cst       - Constraint structure table (cell array)
%   VOINames  - Default VOI definitions (struct with .Aliases and .Color)
%   VOISites  - Site-specific VOI info parsed from .txt (struct with .VOIName and .Color)
%   mode      - Operation mode ('STAR', 'SPINE', or '') (string, optional)
%
% Outputs:
%   cst             - Updated CST (cell array)
%   prescribedDose  - Prescribed dose from PTV (double)

if nargin < 4
    mode = '';
end

prescribedDose = [];

%% --- Handle EXTERNAL ---
ixExternalMatches = find(contains(cst(:,2), VOINames.External.Aliases));
if isempty(ixExternalMatches)
    warning('No EXTERNAL structure defined!');
    ixExternal = [];
else
    if numel(ixExternalMatches) > 1
        warning('Multiple EXTERNAL structures found. Using the exact match.');
        exactMatches = find(ismember(cst(:,2), VOINames.External.Aliases));
        if ~isempty(exactMatches)
            ixExternalMatches = exactMatches;
        end
    end

    ixExternal = ixExternalMatches(1);
    cst{ixExternal, 3}  = 'EXTERNAL';
    cst{ixExternal, 5}.Priority  = size(cst,1) + 3;

    % Prefer VOISites color, fallback to VOINames
    if isfield(VOISites, 'External') && ~isempty(VOISites.External.Color)
        cst{ixExternal, 5}.visibleColor = VOISites.External.Color;
    else
        cst{ixExternal, 5}.visibleColor = VOINames.External.Color;
    end
end

%% --- Handle PTV ---
ixPTV = find(contains(cst(:,2), VOINames.PTV.Aliases), 1);
if isempty(ixPTV)
    warning('PTV not found in CST!');
    prescribedDose = [];
else
    if size(cst,2) > 5
        prescribedDose = cst{ixPTV, 6}{1, 1}.parameters{1};
    end
    % Prefer VOISites color, fallback to VOINames
    if isfield(VOISites, 'PTV') && ~isempty(VOISites.PTV.Color)
        cst{ixPTV, 5}.visibleColor = VOISites.PTV.Color;
    else
        cst{ixPTV, 5}.visibleColor = VOINames.PTV.Color;
    end
end

%% --- Clear objectives ---
if size(cst,2) > 5
    cst(:, 6) = [];
end

%% --- Modes (STAR / SPINE) ---
if strcmpi(mode, 'STAR') || strcmpi(mode, 'SPINE')
    allowedNames = VOISites.(mode).VOIName;  % names come from .txt
    newCST = {};
    matched = {};
    missing = {};
    ix = 0;

    for i = 1:numel(allowedNames)
        name = allowedNames{i};
        found = false;

        % Search across VOINames
        for f = fieldnames(VOINames)'
            field = f{1};
            if isfield(VOINames.(field), 'Aliases') && any(strcmpi(name, VOINames.(field).Aliases))
                ixVOI = find(contains(cst(:,2), VOINames.(field).Aliases));

                % Refine multiple matches if necessary
                if numel(ixVOI) > 1
                    exactMatches = find(ismember(cst(:,2), VOINames.(field).Aliases));
                    if numel(exactMatches) >= 1
                        ixVOI = exactMatches(1);
                    end
                end

                if ~isempty(ixVOI)
                    entry = cst(ixVOI,:);
                    entry{1} = ix;   % reindex
                    entry{2} = field; % canonical name

                    % --- Color precedence ---
                    chosenColor = [];
                    if isfield(VOISites, mode)
                        voiList = VOISites.(mode).VOIName;
                        colorList = VOISites.(mode).Color;
                        idxMatch = find(strcmpi(name, voiList), 1);
                        if ~isempty(idxMatch) && ~isempty(colorList{idxMatch})
                            chosenColor = colorList{idxMatch};
                        end
                    end

                    if isempty(chosenColor)
                        chosenColor = VOINames.(field).Color;
                    end

                    entry{5}.visibleColor = chosenColor;

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

    % --- Print summary ---
    fprintf('\n--- %s mode summary ---\n', mode);
    if ~isempty(matched)
        fprintf('Matched VOIs:\n'); fprintf('   ✓ %s\n', matched{:});
    end
    if ~isempty(missing)
        fprintf('Missing VOIs:\n'); fprintf('   ✗ %s\n', missing{:});
    end
    fprintf('--------------------------\n\n');

    cst = newCST;

    % Update PTV / EXTERNAL indices
    ixPTV = find(strcmp(cst(:,2), 'PTV'), 1);
    ixExternal = find(strcmp(cst(:,2), 'External'), 1);
end

end
