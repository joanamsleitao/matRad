function [doseCubeFinal, wFinal, qiFinal] = optimizeReplicatedPlan(cst, pln, qiPat, dij, doseCubeInit, wInit, qiInit)
%OPTIMIZEREPLICATEDPLAN Tune PTV penalties to replicate D_98, D_2, mean dose from clinical plan.
%
% Inputs:
%   cst          - Constraint structure table
%   pln          - Plan structure
%   qiPat        - Reference (clinical) quality indicators
%   dij          - Dose influence matrix
%   doseCubeInit - Initial dose
%   wInit        - Initial weights
%   qiInit       - Initial quality indicators
%
% Outputs:
%   doseCubeFinal - Final dose
%   wFinal        - Final weights
%   qiFinal       - Final quality indicators

    %% Settings
    maxIter = 10;
    penaltyIncreaseFactor = 0.25;
    meanTolerancePct = 2;
    VxToleranceAbs = 3;  % absolute difference allowed in Vx values (e.g. V10 within 3%)

    %% Get PTV index and name
    VOINames = parseStructureFile('VOINames.txt');
    ixPTV = find(contains(cst(:,2), VOINames.PTV), 1);
    ptvName = cst{ixPTV, 2};

    %% Get clinical reference values
    D_98_goal  = qiPat(ixPTV).D_98;
    D_2_goal   = qiPat(ixPTV).D_2;
    mean_goal  = qiPat(ixPTV).mean;

    % Get list of Vx fields in the reference
    VxFields = fieldnames(qiPat(ixPTV));
    VxFields = VxFields(contains(VxFields, 'V_') & endsWith(VxFields, 'Gy'));

    % Store best result
    bestScore = inf;
    doseCubeFinal = doseCubeInit;
    wFinal = wInit;
    qiFinal = qiInit;

    doseCubeOpt = doseCubeInit;
    wOpt = wInit;
    objectiveOpt = 100000;
    for iter = 1:maxIter
        % Evaluate current metrics
        qi = matRadJoana_calcQualityIndicators(cst, pln, doseCubeOpt);
        D_98 = qi(ixPTV).D_98;
        D_2 = qi(ixPTV).D_2;
        meanD = qi(ixPTV).mean;

        relDevMean = 100 * abs(meanD - mean_goal) / mean_goal;
        score = abs(D_98 - D_98_goal) + abs(D_2 - D_2_goal) + relDevMean;

        % Add Vx score (optional)
        for f = 1:numel(VxFields)
            fName = VxFields{f};
            if isfield(qi(ixPTV), fName)
                Vx_val = qi(ixPTV).(fName);
                Vx_goal = qiPat(ixPTV).(fName);
                score = score + min(abs(Vx_val - Vx_goal), VxToleranceAbs);
            end
        end

        if score < bestScore
            bestScore = score;
            doseCubeFinal = doseCubeInit;
            wFinal = wInit;
            qiFinal = qi;
        end

        % Check if within acceptable tolerance
        if D_98 >= D_98_goal && D_2 <= D_2_goal && relDevMean <= meanTolerancePct
            fprintf('✓ Iteration %d: PTV goals met (D98=%.2f, D2=%.2f, mean=%.2f)\n', iter, D_98, D_2, meanD);
            return;
        elseif objectiveOpt < 10
            fprintf('Iteration %d: Opt value below 10. Breaking here. (D98=%.2f, D2=%.2f, mean=%.2f)\n', iter, D_98, D_2, meanD);
            return;
        else
            fprintf('✗ Iter %d: D98=%.2f/%.2f, D2=%.2f/%.2f, Mean=%.2f (dev=%.1f%%)\n', ...
                    iter, D_98, D_98_goal, D_2, D_2_goal, meanD, relDevMean);
        end

        % Adjust penalties on all PTV objectives
        for o = 1:numel(cst{ixPTV,6})
            if isfield(cst{ixPTV,6}{o}, 'penalty')
                oldPenalty = cst{ixPTV,6}{o}.penalty;
                cst{ixPTV,6}{o}.penalty = oldPenalty * (1 + penaltyIncreaseFactor);
                fprintf('    -> Adjusted penalty on objective %d from %.2f to %.2f\n', ...
                        o, oldPenalty, cst{ixPTV,6}{o}.penalty);
            end
        end

        % Re-optimize
        result = matRad_fluenceOptimization(dij, cst, pln, wOpt);
        wOpt = result.w;
        doseCubeOpt = result.physicalDose;
        objectiveOpt = result.info.eval.objective;
    end

    warning('⚠ Could not reach all PTV goals after %d iterations. Best result returned.', maxIter);
end