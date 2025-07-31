function [doseCube, wNew, qiNew, flaggedStruct] = analyzePlanDose(ct, cst, dij, pln, wInit, ixPTV, qiPat, VOINames)
% ANALYZEPLANDOSE
%
% Computes the dose distribution for a given plan and spot weights,
% evaluates quality indicators, prints dose objectives for PTV,
% and reports deviations in OARs relative to reference indicators.
%
% This function encapsulates the forward dose calculation, 
% quality evaluation, and OAR deviation reporting in one call.
%
% INPUTS:
%   ct       - CT data structure (required)
%   cst      - CST cell array (required)
%   dij      - dij structure containing beamlet data (required)
%   pln      - Plan structure (required)
%   wInit    - Initial spot weights vector (required)
%   ixPTV    - Index (or vector of indices) of PTV(s) in CST for printing dose objectives (required)
%   qiPat    - Reference quality indicators struct for comparison (required)
%   VOINames - Cell array of VOI names corresponding to CST entries (required)
%
% OUTPUTS:
%   doseCube     - Calculated physical dose cube [Gy]
%   wNew         - Updated spot weights after forward dose calculation
%   qiNew        - Calculated quality indicators struct for current dose
%   flaggedStruct - Structure listing OARs flagged for deviations compared to qiPat
%
% EXAMPLE:
%   [doseCube, wNew, qiNew, flaggedStruct] = analyzePlanDose(ct, cst, dij, pln, wInit, ixPTV, qiPat, VOINames);
%

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
