function ixTargets = matRad_VOITargetFindIx(cst)
% matRad_VOITargetFindIx
% -------------------------------------------------------------------------
% Find the index (or indices) of Targets VOIs 
%
% SYNTAX:
%   ixTargets = matRad_OARFindIx(cst, aliases)
%
% INPUTS:
%   cst      - Cell array representing the current structure table (CST)
%              where column 1 optionally contains VOI type (e.g., 'OAR')
%              and column 2 contains VOI names.
%
% OUTPUT:
%   ixTargets    - Index (or indices) of matching Targets VOIs in CST.
%              Empty if no matches are found.
%
% DESCRIPTION:
%   The function performs a case-insensitive search for Targets names that 
%   partially or exactly match any of the provided aliases.
%
% -------------------------------------------------------------------------

    ixTargets = [];

    % Try to identify which rows are OARs (if VOI type exists)
    if size(cst,2) >= 1 && iscellstr(cst(:,3))
        oarMask = contains(cst(:,3), 'TARGET', 'IgnoreCase', true);
        ixTargets = find(oarMask);
    else
        fprintf('Could not find any TARGETs! \n')
    end
end
