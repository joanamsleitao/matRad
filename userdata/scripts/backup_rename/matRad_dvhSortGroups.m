function dvhGroups = matRad_dvhSortGroups(dvhAll, dvhRef, nPerGroup)
% groupDVHs - group DVH phases into sets of N
%
% Usage:
%   dvhGroups = groupDVHs(dvhAll, nPerGroup)
%
% Inputs:
%   dvhAll      - struct with fields 'phase1', 'phase2', etc.
%   nPerGroup   - number of phases per group (e.g. 3)
%
% Output:
%   dvhGroups   - struct with grouped DVHs:
%                 dvhGroups.group1 = struct with phase1..phase3
%                 dvhGroups.group2 = struct with phase4..phase6
%                 etc.
%
% Example:
%   dvhGroups = groupDVHs(dvhAll, 3);
%   fieldnames(dvhGroups)
%   % -> {'group1', 'group2', 'group3'}
%
% Notes:
%   - Works for any number of phases
%   - Groups the last incomplete set as well (if total not multiple of nPerGroup)

    if nargin < 3
        nPerGroup = 3;
    end

    phaseNames = fieldnames(dvhAll);
    nPhases = numel(phaseNames);

    nGroups = ceil(nPhases / nPerGroup);
    dvhGroups = struct();

    for g = 1:nGroups
        startIdx = (g-1)*nPerGroup + 1;
        endIdx   = min(g*nPerGroup, nPhases);

        phasesInGroup = phaseNames(startIdx:endIdx);
        groupStruct = struct();
groupStruct.planning = dvhRef;
        for p = 1:numel(phasesInGroup)
            thisPhase = phasesInGroup{p};
            groupStruct.(thisPhase) = dvhAll.(thisPhase);
        end
        dvhGroups.(['group' num2str(g)]) = groupStruct;
    end
end
