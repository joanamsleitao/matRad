function [doseCubeFinal, wFinal, info] = optimizeFlaggedOARs(cst, pln, qiPat, qiInit, flaggedStruct, dij, doseCubeInit, wInit, ...
    basePenalty, maxIter, tolerance)
% OPTIMIZEFLAGGEDOARS - Optimizes flagged OARs while preserving PTV goals
%
% Syntax:  [doseCubeFinal, wFinal, info] = optimizeFlaggedOARs(cst, pln, qiPat, qiInit, flaggedStruct, dij, doseCubeInit, wInit, ...
%    basePenalty, maxIter, tolerance)
%
% Inputs:
%   cst           - CST cell array (cell array)
%   pln           - Plan structure (struct)
%   qiPat         - Reference quality indicators (struct)
%   qiInit        - Initial quality indicators (struct)
%   flaggedStruct - Flagged OAR deviations (struct array)
%   dij           - Dose influence matrix (struct)
%   doseCubeInit  - Initial dose cube (3D array)
%   wInit         - Initial weights (vector)
%   basePenalty   - Base penalty value (double, optional)
%   maxIter       - Maximum iterations (integer, optional)
%   tolerance     - Tolerance percentage (double, optional)
%
% Outputs:
%   doseCubeFinal - Final dose cube (3D array)
%   wFinal        - Final weights (vector)
%   info          - Optimization info (struct)
%
% Other m-files required: matRad_fluenceOptimization.m, matRadJoana_calcQualityIndicators.m
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_fluenceOptimization, matRadJoana_calcQualityIndicators
%
if nargin < 9 || isempty(basePenalty), basePenalty = 10; end
if nargin < 10 || isempty(maxIter), maxIter = 10; end
if nargin < 11 || isempty(tolerance), tolerance = 50; end

% Parse VOINames
VOINames = parseStructureFile('VOINames.txt');

% Find PTV index in cst
ixPTV = find(contains(cst(:,2), VOINames.PTV), 1);
if isempty(ixPTV)
    error('PTV structure not found in constraints.');
end

% Extract PTV dose limits from clinical plan (qiPat)
minDoseGoalPTV = floor(qiPat(ixPTV).D_98);
maxDoseGoalPTV = ceil(qiPat(ixPTV).D_2);
PTVLimits.minD98 = minDoseGoalPTV;
PTVLimits.maxD2 = maxDoseGoalPTV;

% Update flagged OAR constraints with given penalty and dose goals
for i = 1:numel(flaggedStruct)
    flag = flaggedStruct(i);
    ixOAR = find(contains(cst(:,2), flag.name), 1);
    if isempty(ixOAR)
        warning('OAR %s not found in constraints, skipping.', flag.name);
        continue;
    end
    metric = flag.metric;

    % % Set penalty for this OAR objective
    % cst{ixOAR,6}{1,1}.penalty = basePenalty;

    % Set dose goal based on metric and reference value
    switch metric
        case 'D_2' % 1, 'DoseObjectives.matRad_SquaredOverdosing';
            cst{ixOAR, 6}{1, 1}.penalty =  cst{ixOAR, 6}{1, 1}.penalty * basePenalty;
        case 'D_98' % 2, 'DoseObjectives.matRad_SquaredUnderdosing';
            cst{ixOAR, 6}{1, 1}.penalty = cst{ixOAR, 6}{1, 2}.penalty * basePenalty;
        case 'mean' % 3, 'DoseObjectives.matRad_SquaredDeviation';
            cst{ixOAR, 6}{1, 3}.penalty = cst{ixOAR, 6}{1, 3}.penalty * basePenalty;
        otherwise
            warning('Metric %s not recognized for OAR %s, skipping.', metric, flag.name);
    end
end

% Initialization for optimization
doseCubeFinal = doseCubeInit;
wFinal = wInit;
qiCurrent = qiInit;
bestDoseCube = doseCubeInit;
bestW = wInit;
bestScore = Inf; % sum of abs deviations (PTV + flagged OARs)
success = false;

wOpt = wInit;
fprintf('Starting optimization on flagged OARs with PTV constraints preserved...\n');

for iter = 1:maxIter
    % Optimize fluence
    resultOpt = matRad_fluenceOptimization(dij, cst, pln, wOpt);
    wOpt = resultOpt.w;
    doseCubeOpt = resultOpt.physicalDose;
    clear resultOpt

    % Calculate quality indicators
    qiOpt = matRadJoana_calcQualityIndicators(cst, pln, doseCubeOpt);

    % PTV indices and metrics
    ixPTV_opt = find(contains({qiOpt.name}, VOINames.PTV), 1);
    d98_PTV = qiOpt(ixPTV_opt).D_98;
    d2_PTV = qiOpt(ixPTV_opt).D_2;

    % Check PTV limits
    ptvOK = d98_PTV >= PTVLimits.minD98 && d2_PTV <= PTVLimits.maxD2;

    % Check flagged OARs
    oarOK = true;
    oarDevs = zeros(numel(flaggedStruct),1);

    for i = 1:numel(flaggedStruct)
        flag = flaggedStruct(i);
        ixOAR_opt = find(contains({qiOpt.name}, flag.name), 1);
        if isempty(ixOAR_opt)
            warning('OAR %s not found in quality indicators at iteration %d', flag.name, iter);
            oarOK = false;
            continue;
        end

        metric = flag.metric;
        refVal = flag.ref;
        currVal = qiOpt(ixOAR_opt).(metric);

        relDev = 100 * (currVal - refVal) / refVal;
        oarDevs(i) = relDev;

        if abs(relDev) > tolerance
            oarOK = false;
        end
    end

    % Compute overall deviation score
    ptvDevScore = abs(100 * (d98_PTV - PTVLimits.minD98) / PTVLimits.minD98) + ...
        abs(100 * (d2_PTV - PTVLimits.maxD2) / PTVLimits.maxD2);
    totalScore = ptvDevScore + sum(abs(oarDevs));

    fprintf('Iter %d: PTV D98=%.2f (goal≥%.2f), D2=%.2f (goal≤%.2f), OAR max dev=%.1f%%, total score=%.2f\n', ...
        iter, d98_PTV, PTVLimits.minD98, d2_PTV, PTVLimits.maxD2, max(abs(oarDevs)), totalScore);

    % Update best plan if improved and PTV still OK
    if totalScore < bestScore && ptvOK
        bestScore = totalScore;
        bestDoseCube = doseCubeOpt;
        bestW = wOpt;
    end

    if ptvOK && oarOK
        fprintf('All constraints met within tolerance at iteration %d.\n', iter);
        doseCubeFinal = doseCubeOpt;
        wFinal = wOpt;
        success = true;
        break;
    end
end

if ~success
    warning('Constraints not fully met after %d iterations. Returning closest plan.', maxIter);
    doseCubeFinal = bestDoseCube;
    wFinal = bestW;
end

% Return info
info.success = success;
info.bestScore = bestScore;
info.iterations = iter;
info.finalPTV = struct('D_98', d98_PTV, 'D_2', d2_PTV);
info.finalOARDevs = oarDevs;
end
