function [cst, prescribedDose, ixPTV, ixExternal] = setupCSTandPrescribedDose(cst, mode)
% setupCSTandPrescribedDose - Validates and updates the CST, identifies EXTERNAL and PTV structures,
% and assigns fixed RGB colors to matched VOIs.
%
% If mode is 'STAR', only specific VOIs will be retained and renamed to their canonical names.
%
% Inputs:
%   cst  - the CST cell array
%   mode - optional string ('STAR') to restrict VOIs and apply renaming
%
% Outputs:
%   cst             - updated CST with colors and filtered VOIs (if STAR mode)
%   prescribedDose  - dose extracted from the PTV objective
%   ixPTV           - index of the PTV in the CST
%   ixExternal      - index of the External structure in the CST

if nargin < 2
    mode = '';
end

VOINames = parseStructureFile('VOINames.txt');

% Handle EXTERNAL structure
ixExternalMatches = find(contains(cst(:,2), VOINames.External.Aliases));
if isempty(ixExternalMatches)
    warning('No EXTERNAL structure defined!');
    ixExternal = [];
else
    if numel(ixExternalMatches) > 1
        warning('Multiple EXTERNAL structures found. Using the first one.');
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

% Handle STAR mode
if strcmpi(mode, 'STAR')
    allowedNames = {'Body','Aorta','Herz','LungLeft','LungRight','Oesophagus','Stomach','PTV'};
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
end
end
