function [doseCube, wInit, qi] = matRadJoana_findBestDoseCubeMatch(cst, pln, GoalPTV, dij, doseCube, wInit, qi)
% matRadJoana_findBestDoseCubeMatch - Iteratively optimize dose to match PTV constraints
%
% Syntax:
%   [doseCube, wInit, qi] = matRadJoana_findBestDoseCubeMatch(cst, pln, GoalPTV, dij, doseCube, wInit, qi)
%
% Inputs:
%   cst       - matRad CST structure
%   pln       - matRad plan structure
%   GoalPTV   - 1x2 vector [D_98_min, D_2_max] goals for PTV (Gy)
%   dij       - Dose influence matrix
%   doseCube  - Current physical dose cube
%   wInit     - Current fluence weights
%   qi        - Initial quality indicator struct
%
% Outputs:
%   doseCube  - Updated physical dose cube
%   wInit     - Updated fluence weights
%   qi        - Updated quality indicators after optimization
%
% Description:
%   Applies repeated fluence optimization trials with increasing penalty
%   until the D_98 and D_2 criteria for the PTV are satisfied.
%
% Other m-files required: matRad_fluenceOptimization, matRad_calcQualityIndicators
% Subfunctions: none
% MAT-files required: none
%
% See also: checkDoseCubeMatch, optimizeReplicatedPlan
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Initialization
maxTrials = 50;
penaltyFactor = 1.5;
ixPTV = find(strcmp(cst(:,2), 'PTV'), 1);
minDoseGoalPTV = GoalPTV(1);
maxDoseGoalPTV = GoalPTV(2);
% minDoseGoalPTV = floor(qi(ixPTV).D_98);
% maxDoseGoalPTV = ceil(qi(ixPTV).D_2);

for i = 1:maxTrials
    % Check condition for penalty adjustment
    if ~(qi(ixPTV).D_98 > minDoseGoalPTV && qi(ixPTV).D_2 < maxDoseGoalPTV)
        % Increase penalty dynamically
        cst{ixPTV, 6}{1, 1}.penalty = cst{ixPTV, 6}{1, 1}.penalty * penaltyFactor;

        % Perform Fluence Optimization
        % wInit = resultGUI.w;
        [resultGUI, wInit] = matRad_fluenceOptimization(dij, cst, pln, wInit);
        doseCube = resultGUI.physicalDose;
        clear resultGUI

        % Calculate Quality Indicators
        qi = matRad_calcQualityIndicators(cst, pln, doseCube);

        % % Save just in case matlab crashes
        % trialName = sprintf('Trial_PTVMin%d', i - 1);
        % save(fullfile('/home/joana/KIT Ablation/NewResultsOptimization/', trialName), 'cst');

    end

    % Check condition for saving and exiting
    if qi(ixPTV).D_98 > minDoseGoalPTV && qi(ixPTV).D_2 < maxDoseGoalPTV
        % trialName = sprintf('Trial_Constraints_25Res', i - 1);
        % save(fullfile('/home/joana/KIT Ablation/NewResultsOptimization/', trialName), 'cst', 'resultGUI');
        % fprintf('Saved results for trial: %s\n', trialName);
        % fprintf('Saved results for trial: %s\n', trialName);
        sprintf('We did it!!')
        return; % Exit the loop
    end
end
%

end