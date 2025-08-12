function [doseCube, wNew, qiNew, flaggedStruct] = analyzePlanDose(ct, cst, dij, pln, wInit, ixPTV, qiPat, VOINames)
% ANALYZEPLANDOSE - Computes dose distribution and evaluates quality indicators
%
% Syntax:  [doseCube, wNew, qiNew, flaggedStruct] = analyzePlanDose(ct, cst, dij, pln, wInit, ixPTV, qiPat, VOINames)
%
% Inputs:
%   ct          - CT data structure (struct)
%   cst         - CST cell array (cell array)
%   dij         - dij structure containing beamlet data (struct)
%   pln         - Plan structure (struct)
%   wInit       - Initial spot weights vector (double array)
%   ixPTV       - Index/indices of PTV(s) in CST (integer array)
%   qiPat       - Reference quality indicators struct (struct)
%   VOINames    - VOI names corresponding to CST entries (cell array)
%
% Outputs:
%   doseCube        - Calculated physical dose cube [Gy] (double array)
%   wNew            - Updated spot weights (double array)
%   qiNew           - Calculated quality indicators (struct)
%   flaggedStruct   - OARs flagged for deviations (struct)
%
% Other m-files required: matRad_fluenceOptimization.m, 
%                         matRadJoana_calcQualityIndicators.m
% Subfunctions: printCSTObjectives, reportOARDeviations
% MAT-files required: none
%
% See also: addOverdoseConstraint, createReplicatedPlan

    % ---- Input validation ----
    narginchk(8,8); % Require exactly 8 inputs
    
    if isempty(ct) || isempty(cst) || isempty(dij) || isempty(pln)
        error('CT, CST, DIJ, and PLN inputs must be non-empty.');
    end
    
    if ~isnumeric(wInit) || isempty(wInit)
        error('Initial spot weights wInit must be a non-empty numeric vector.');
    end
    
    if isempty(ixPTV) || ~all(ismember(ixPTV, 1:size(cst,1)))
        error('ixPTV must be valid indices within CST.');
    end
    
    if ~isstruct(qiPat)
        error('qiPat must be a struct of reference quality indicators.');
    end
    
    % if ~iscell(VOINames) || numel(VOINames) ~= size(cst,1)
    %     error('VOINames must be a cell array matching number of CST entries.');
    % end
    
    % ---- Forward dose calculation ----
    resultGUICurrent = matRad_fluenceOptimization(dij, cst, pln, wInit);
    doseCube = resultGUICurrent.physicalDose;
    wNew = resultGUICurrent.w;
    clear resultGUICurrent
    
    % ---- Calculate quality indicators for current dose ----
    qiNew = matRadJoana_calcQualityIndicators(cst, pln, doseCube, [], []);
    
    % ---- Print dose objectives for the PTV(s) ----
    fprintf('\n--- Dose objectives for PTV(s) ---\n');
    printCSTObjectives(cst, ixPTV);
    
    % ---- Report OAR deviations vs reference ----
    fprintf('\n--- Reporting OAR deviations compared to reference ---\n');
    flaggedStruct = reportOARDeviations(cst, qiNew, qiPat);
    
end
