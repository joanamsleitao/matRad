function matRad_evaluateFLASHBeams(beamSearch, cst, ptvAlias, flashAlias, oarAliases, prescribedDose)
% EVALUATEFLASHPLANS - Evaluate multiple FLASH proton plans by metrics
%
% Syntax:
%   matRad_evaluateFLASHBeams(beamSearch, cst, ptvAlias, flashAlias, oarAliases, prescribedDose)
%
% Inputs:
%   beamSearch     - Struct with fields for each beam angle, containing doseCube, w, info
%   cst            - Constraint structure table
%   ptvAlias       - String or cell array with alias for PTV
%   flashAlias     - String or cell array with alias for FLASH target
%   oarAliases     - Cell array with aliases of OARs to include
%   prescribedDose - (optional) Prescribed dose in Gy; if not given, uses SquaredDeviation obj
%
% Output:
%   Prints a summary table comparing each plan

if nargin < 6
    prescribedDose = getPrescribedDoseFromCST(cst, flashAlias);
end

% Find VOI indices
ixPTV   = matRad_findVOIIndex(cst, ptvAlias);
ixFLASH = matRad_findVOIIndex(cst, flashAlias);
ixOARs  = cellfun(@(alias) matRad_findVOIIndex(cst, alias), oarAliases);

% Column headers
fprintf('\n%-10s %-8s %-8s %-8s %-8s', 'Beam', 'PTV_D2', 'PTV_D98', 'FLASH_D2', 'FLASH_D98');
for i = 1:numel(ixOARs)
    fprintf(' %-10s %-10s', sprintf('OAR%d_D2',i), sprintf('OAR%d_D98',i));
end
fprintf(' %-8s %-12s\n', 'CI', 'Objective');

fprintf('%s\n', repmat('-',1,90 + 20*numel(ixOARs)));

% Iterate over beams
beamNames = fieldnames(beamSearch);
for i = 1:numel(beamNames)
    beamName = beamNames{i};
    plan = beamSearch.(beamName);
    doseCube = plan.doseCube;
    
    % Dose stats
    ptvDose   = doseCube(cst{ixPTV, 4}{1});
    flashDose = doseCube(cst{ixFLASH, 4}{1});
    
    ptvD2   = prctile(ptvDose, 98);   % D2
    ptvD98  = prctile(ptvDose, 2);    % D98
    flashD2 = prctile(flashDose, 98);
    flashD98= prctile(flashDose, 2);
    
    % OAR stats
    oarD2   = zeros(1, numel(ixOARs));
    oarD98  = zeros(1, numel(ixOARs));
    for j = 1:numel(ixOARs)
        oarDose = doseCube(cst{ixOARs(j), 4}{1});
        oarD2(j)  = prctile(oarDose, 98);
        oarD98(j) = prctile(oarDose, 2);
    end
    
    % Conformity Index (CI)
    flashBin = doseCube >= prescribedDose;
    V_Rx = sum(flashBin(:));                    % Volume receiving Rx or more
    V_target = numel(cst{ixFLASH, 4}{1});          % FLASH volume
    V_overlap = sum(flashBin(cst{ixFLASH, 4}{1})); % Overlap
    
    CI = (V_overlap^2) / (V_target * V_Rx);     % CI as in ICRU
    
    % Objective value
    objVal = plan.info.objective;
    
    % Print row
    fprintf('%-10s %-8.1f %-8.1f %-8.1f %-8.1f', beamName, ptvD2, ptvD98, flashD2, flashD98);
    for j = 1:numel(ixOARs)
        fprintf(' %-10.1f %-10.1f', oarD2(j), oarD98(j));
    end
    fprintf(' %-8.2f %-12.2f\n', CI, objVal);
end

end

function dose = getPrescribedDoseFromCST(cst, flashAlias)
    ix = matRad_findVOIIndex(cst, flashAlias);
    dose = NaN;
    objs = cst{ix,6};
    for i = 1:numel(objs)
        if contains(objs{i}.className, 'SquaredDeviation')
            dose = objs{i}.parameters{1};
            return;
        end
    end
    error('Prescribed dose not found in SquaredDeviation objective for FLASH VOI.');
end
