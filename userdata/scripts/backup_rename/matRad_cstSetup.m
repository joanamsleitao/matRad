function [cst, prescribedDose, ixPTV, ixExternal] = matRad_cstSetup(cst, VOINames, VOISites, mode)
% matRad_cstSetup - Validates and updates CST with colors and structure info
%
% Syntax:
%   [cst, prescribedDose, ixPTV, ixExternal] = matRad_cstSetup(cst, VOINames, VOISites, mode)
%
% Inputs:
%   cst        - Constraint structure table (cell array)
%   VOINames   - Struct defining canonical VOIs (fields with .Aliases and .Color)
%   VOISites   - Struct defining site-specific VOI lists (fields: mode.VOIName and optional .Color)
%   mode       - String (e.g., 'STAR', 'SPINE', or '')
%
% Outputs:
%   cst             - Updated CST (cell array)
%   prescribedDose  - Prescribed dose from PTV (double)
%   ixPTV           - Index of PTV in CST
%   ixExternal      - Index of External structure in CST
%
% Author: Joana Leitão + GPT-5, 2025
% -------------------------------------------------------------------------

if nargin < 4
    mode = '';
end

%% --- Handle EXTERNAL structure ---
ixExternalMatches = find(contains(cst(:,2), VOINames.External.Aliases));
if isempty(ixExternalMatches)
    warning('No EXTERNAL structure defined!');
    ixExternal = [];
else
    if numel(ixExternalMatches) > 1
        exactMatches = find(ismember(cst(:,2), VOINames.External.Aliases));
        if ~isempty(exactMatches)
            ixExternalMatches = exactMatches;
        end
    end
    ixExternal = ixExternalMatches(1);
    cst{ixExternal, 3} = 'EXTERNAL';
    cst{ixExternal, 5}.Priority = size(cst,1) + 3;
    cst{ixExternal, 5}.visibleColor = VOINames.External.Color;
end

%% --- Handle PTV ---
ixPTV = find(contains(cst(:,2), 'PTV'), 1);
if isempty(ixPTV)
    warning('PTV not found in CST!');
    prescribedDose = 0;
else
    % prescribedDose = cst{ixPTV, 6}{1,1}.parameters{1};
    cst{ixPTV, 5}.visibleColor = [1 0.5000 0];
end

%% --- Handle Mode (STAR, SPINE, etc.) ---
if ~isempty(mode) && isfield(VOISites, mode)
    allowedNames = VOISites.(mode).VOIName;
    siteHasColor = isfield(VOISites.(mode), 'Color') && ~isempty(VOISites.(mode).Color);
    newCST = {};
    matched = {};
    missing = {};

    for i = 1:numel(allowedNames)
        name = allowedNames{i};
        found = false;
        siteColor = [];
        if siteHasColor && numel(VOISites.(mode).Color) >= i
            siteColor = VOISites.(mode).Color{i};
        end

        for f = fieldnames(VOINames)'
            field = f{1};
            if isfield(VOINames.(field), 'Aliases') && any(strcmpi(name, VOINames.(field).Aliases))
                ixVOI = find(contains(cst(:,2), VOINames.(field).Aliases));

                % refine if multiple matches
                if numel(ixVOI) > 1
                    exactMatches = find(ismember(cst(:,2), VOINames.(field).Aliases));
                    if ~isempty(exactMatches)
                        ixVOI = exactMatches;
                    end
                end

                if ~isempty(ixVOI)
                    entry = cst(ixVOI(1),:);
                    entry{2} = field;  % canonical name

                    % --- Assign color priority: VOISites.(mode) > VOINames
                    if ~isempty(siteColor)
                        entry{5}.visibleColor = siteColor;
                    elseif isfield(VOINames.(field), 'Color')
                        entry{5}.visibleColor = VOINames.(field).Color;
                    end

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

    % --- Print summary
    fprintf('\n--- %s mode summary ---\n', upper(mode));
    if ~isempty(matched)
        fprintf('Matched VOIs:\n'); fprintf('   ✓ %s\n', matched{:});
    else
        fprintf('No VOIs matched!\n');
    end
    if ~isempty(missing)
        fprintf('Missing VOIs:\n'); fprintf('   ✗ %s\n', missing{:});
    end
    if siteHasColor
        fprintf('Colors from VOISites.%s used.\n', mode);
    else
        fprintf('Colors from VOINames used.\n');
    end
    fprintf('--------------------------\n\n');

    % --- Finalize CST
    cst = newCST;
    ixPTV = find(strcmpi(cst(:,2), 'PTV'), 1);
    ixExternal = find(strcmpi(cst(:,2), 'External'), 1);
end
end
