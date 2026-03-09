function ixVOI = matRad_VOIFindIx(cst, aliases)
% matRad_VOIFindIx - Find VOI index in CST matching any alias string
%
% Syntax:
%   ixVOI = matRad_VOIFindIx(cst, aliases)
%
% Description:
%   Searches VOI names in CST (column 2) for the first alias that matches.
%   Matching is case-insensitive and proceeds in stages:
%     1) Find VOIs whose name CONTAINS the alias.
%     2) If multiple matches:
%          a) Prefer exact (case-insensitive) matches on the raw name.
%          b) If still multiple or none, prefer names that equal a
%             "sanitized" version of the alias (no spaces, no non-letters).
%          c) If still multiple, take the FIRST such match.
%
%   This is useful when one VOI is a "base" structure (e.g. 'GTV') and
%   others have extra suffixes (e.g. 'GTV_boost', 'GTV_ring').
%
% Inputs:
%   cst     - CST cell array (VOI names in column 2; char or string)
%   aliases - cell array of alias strings, or a single alias string
%
% Output:
%   ixVOI   - single index of matching VOI (empty if none found)
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% Normalize aliases to cell array of char
if ischar(aliases) || isstring(aliases)
    aliases = cellstr(aliases);
end

% Extract VOI names as lower-case strings
voiNamesRaw = cst(:,2);
% Convert to cellstr of char if they are string objects
if isstring(voiNamesRaw)
    voiNamesRaw = cellstr(voiNamesRaw);
end
voiNames = lower(string(voiNamesRaw));

ixVOI = [];

for iAlias = 1:numel(aliases)
    aliasStr = char(aliases{iAlias});
    aliasLow = lower(string(aliasStr));

    % 1) Partial matches (contains)
    partialMatches = find(contains(voiNames, aliasLow, 'IgnoreCase', true));

    if isempty(partialMatches)
        continue; % try next alias
    end

    % If only one partial match, we're done
    if numel(partialMatches) == 1
        ixVOI = partialMatches;
        return;
    end

    % 2a) Among partial matches, prefer exact name matches
    exactMatches = partialMatches(voiNames(partialMatches) == aliasLow);

    if numel(exactMatches) == 1
        ixVOI = exactMatches;
        return;
    elseif numel(exactMatches) > 1
        % Multiple exact matches: take the first
        ixVOI = exactMatches(1);
        return;
    end

    % 2b) If no exact matches, look for "plain" names:
    %     remove non-letters and non-digits from both VOI names and alias
    sanitize = @(s) regexprep(lower(s), '[^a-z0-9]', '');
    aliasPlain = sanitize(aliasLow);

    voiNamesPlain = arrayfun(@(k) sanitize(voiNames(k)), 1:numel(voiNames), ...
                             'UniformOutput', false);
    voiNamesPlain = string(voiNamesPlain);

    plainMatches = partialMatches(voiNamesPlain(partialMatches) == aliasPlain);

    if ~isempty(plainMatches)
        % If multiple, take the first
        ixVOI = plainMatches(1);
        return;
    end

    % 2c) Fallback: keep first partial match if nothing else distinguishes
    ixVOI = partialMatches(1);
    return;
end

% If we reach here, ixVOI stays empty (no alias matched anything)

end