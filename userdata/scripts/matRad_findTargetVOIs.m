function targetIdx = matRad_findTargetVOIs(cst, targetNameTokens)
% matRad_findTargetVOIs - Find VOI indices corresponding to target structures
%
% Inputs:
%   cst              - matRad CST
%   targetNameTokens - Cell array of target name patterns (e.g., {'PTV','GTV'})
%
% Output:
%   targetIdx - Vector of CST row indices for target VOIs

    allIdx = find(~cellfun(@isempty, cst(:,2)));
    names  = cst(allIdx, 2);
    
    isTarget = false(size(allIdx));
    
    for k = 1:numel(allIdx)
        nm = upper(string(names{k}));
        for t = 1:numel(targetNameTokens)
            if contains(nm, upper(string(targetNameTokens{t})))
                isTarget(k) = true;
                break;
            end
        end
    end
    
    targetIdx = allIdx(isTarget);
end