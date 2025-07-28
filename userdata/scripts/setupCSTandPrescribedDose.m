function [cst, prescribedDose, ixPTV, ixExternal] = setupCSTandPrescribedDose(cst)
% Validates and updates the cst structure for EXTERNAL and retrieves prescription dose from PTV.

VOINames = parseStructureFile('VOINames.txt');
if sum(contains(cst(:,2), VOINames.External)) == 0
    warning('No EXTERNAL structure defined!');
else
    if sum(contains(cst(:,2), VOINames.External)) > 1
        warning('Too many EXTERNAL structures! First one will be used');
    end
    ixExternal = find(contains(cst(:,2), VOINames.External), 1);
    cst{ixExternal, 3}  = 'EXTERNAL';
    cst{ixExternal, 5}.Priority  = size(cst,1)+3;
end

ixPTV = find(contains(cst(:,2), VOINames.PTV), 1);
prescribedDose = cst{ixPTV, 6}{1, 1}.parameters{1};
end