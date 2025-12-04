function ixOARs = matRad_VOIOARFindIx(cst)
% matRad_OARFindIx
% -------------------------------------------------------------------------
% Find the index (or indices) of OAR VOIs 
%
% SYNTAX:
%   ixOAR = matRad_OARFindIx(cst, aliases)
%
% INPUTS:
%   cst      - Cell array representing the current structure table (CST)
%              where column 1 optionally contains VOI type (e.g., 'OAR')
%              and column 2 contains VOI names.
%
% OUTPUT:
%   ixOAR    - Index (or indices) of matching OAR VOIs in CST.
%              Empty if no matches are found.
%
% DESCRIPTION:
%   The function performs a case-insensitive search for OAR names that 
%   partially or exactly match any of the provided aliases.
%
% -------------------------------------------------------------------------

    ixOARs = [];

    % Try to identify which rows are OARs (if VOI type exists)
    if size(cst,2) >= 1 && iscellstr(cst(:,3))
        oarMask = contains(cst(:,3), 'OAR', 'IgnoreCase', true);
        ixOARs = find(oarMask);
    else
        fprintf('Could not find any OARs! \n')
    end
end
