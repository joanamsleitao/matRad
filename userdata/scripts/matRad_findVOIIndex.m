function ixVOI = matRad_findVOIIndex(cst, aliases)
% FINDVOIINDEXBYALIASES Find VOI index in CST matching any alias string
%
% ixVOI = findVOIIndexByAliases(cst, aliases)
%
% Inputs:
%   cst     - CST cell array (with VOI names in column 2)
%   aliases - cell array of strings or a single string to match VOI names
%
% Output:
%   ixVOI   - index (or indices) of matching VOIs (empty if none found)
%
% Behavior:
%   - First searches for partial matches (contains)
%   - If multiple found, tries to refine by exact matches (ismember)
%   - Returns all matches if exact match is empty

if ischar(aliases)
    aliases = {aliases};
end

ixVOI = [];
for i = 1:numel(aliases)
    % Partial match search
    partialMatches = find(contains(cst(:,2), aliases{i}, 'IgnoreCase', true));
    if ~isempty(partialMatches)
        % If multiple, try exact match
        if numel(partialMatches) > 1
            exactMatches = find(ismember(lower(cst(:,2)), lower(aliases{i})));
            if ~isempty(exactMatches)
                ixVOI = exactMatches;
            else
                ixVOI = partialMatches;
            end
        else
            ixVOI = partialMatches;
        end
        break; % stop after first alias match
    end
end
end
