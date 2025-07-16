function [doseCubeFinal, wFinal, qiFinal] = optimizeReplicatedPlan(cst, pln, qiPat, dij, doseCubeInit, wInit, qiInit)
%OPTIMIZEREPLICATEDPLAN Improve initial plan to meet PTV goals by adjusting PTV penalty.
%   This function compares initial plan quality indicators against goals
%   from the original plan, and iteratively increases the penalty on the
%   PTV if D_98 and D_2 values do not meet constraints.
%
%   INPUTS:
%       cst          - Cell structure table containing constraints
%       pln          - Plan structure
%       qiPat        - Quality indicators from the original plan (reference)
%       dij          - Dose influence matrix
%       doseCubeInit - Initial dose distribution of replicated plan
%       wInit        - Initial beamlet weights of replicated plan
%       qiInit       - Initial quality indicators of replicated plan
%
%   OUTPUTS:
%       doseCubeFinal - Final (possibly optimized) doseCube
%       wFinal         - Final (possibly optimized) weights
%
%   The optimization iteratively increases the PTV penalty by a fixed factor
%   and performs fluence optimization until the clinical constraints are met
%   or a maximum number of iterations is reached.

%% Settings
maxIter = 10;                    % Maximum optimization attempts
penaltyIncreaseFactor = 0.2;     % Penalty scaling factor per iteration

%% Extract VOINames and Indices
VOINames = parseStructureFile('VOINames.txt');
ixPTV = find(contains(cst(:,2), VOINames.PTV), 1);
ixExternal = find(contains(cst(:,2), VOINames.External), 1);

%% Define Dose Goals from Clinical Plan
minDoseGoalPTV = floor(qiPat(ixPTV).D_98);
maxDoseGoalPTV = ceil(qiPat(ixPTV).D_2);

%% Check Initial Plan
minD98 = qiInit(ixPTV).D_98;
maxD2  = qiInit(ixPTV).D_2;
success = minD98 > minDoseGoalPTV && maxD2 < maxDoseGoalPTV;

if success
    disp('Initial plan meets PTV clinical goals.');
    doseCubeFinal = doseCubeInit;
    wFinal = wInit;
   qiFinal = qiInit;

else
    disp('Initial plan does not meet PTV clinical goals.');
    disp(['  Initial D_98 = ', num2str(minD98), ', D_2 = ', num2str(maxD2)]);
    disp('Starting iterative penalty optimization on PTV...');

    improved = false;

    for iter = 1:maxIter
        % Increase penalty on PTV
        oldPenalty = cst{ixPTV, 6}{1, 1}.penalty;
        cst{ixPTV, 6}{1, 1}.penalty = oldPenalty * (1 + penaltyIncreaseFactor);
        newPenalty = cst{ixPTV, 6}{1, 1}.penalty;

        fprintf('  Iteration %d: Increased PTV penalty from %.2f to %.2f\n', iter, oldPenalty, newPenalty);

        % Re-optimize and evaluate
        resultOpt = matRad_fluenceOptimization(dij, cst, pln);
        wOpt = resultOpt.w;
        doseCubeOpt = resultOpt.physicalDose;
        clear resultOpt

        qiOpt = matRadJoana_calcQualityIndicators(cst, pln, doseCubeOpt);
        minD98 = qiOpt(ixPTV).D_98;
        maxD2  = qiOpt(ixPTV).D_2;
        success = minD98 > minDoseGoalPTV && maxD2 < maxDoseGoalPTV;

        if success
            disp('Clinical goals for PTV met after penalty optimization:');
            fprintf('  D_98 = %.2f (goal > %.2f), D_2 = %.2f (goal < %.2f)\n', minD98, minDoseGoalPTV, maxD2, maxDoseGoalPTV);
            doseCubeFinal = doseCubeOpt;
            wFinal = wOpt;
            qiFinal = qiOpt;
            improved = true;
            break;
        else
            fprintf('  Still not within goals: D_98 = %.2f, D_2 = %.2f\n', minD98, maxD2);
        end
    end

    if ~improved
        warning('Could not meet PTV goals after %d iterations.', maxIter);
        doseCubeFinal = doseCubeInit;
        wFinal = wInit;
        qiFinal = qiInit;
    end
end