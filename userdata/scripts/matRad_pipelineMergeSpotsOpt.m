function matRad_pipelineMergeSpotsOpt(ct, cst, stf, dij, pln, wRBE, doseCubeRBE, voiDoseByEL, topELStruct, qiByEL, nTop, doMerge)
% matRad_pipelineMergeSpotsOpt - Full pipeline: select top ELs, merge, optimize, plot
%
% Syntax:
%   matRad_pipelineMergeSpotsOpt(ct, cst, stf, dij, pln, wRBE, doseCubeRBE, voiDoseByEL, topELStruct, qiByEL, nTop, doMerge)
%
% Description:
%   End-to-end pipeline that:
%     1) Sorts voiDoseByEL by MaxDose
%     2) Extracts top-N ELs
%     3) Optionally merges them
%     4) Reoptimizes
%     5) Plots comparison
%
% Inputs:
%   ct, cst, stf, dij, pln - standard matRad structs
%   wRBE                   - global weight vector
%   doseCubeRBE            - full plan dose
%   voiDoseByEL            - table from matRad_dosePerVOI
%   topELStruct            - all EL structs
%   qiByEL                 - quality indices per EL
%   nTop                   - number of top ELs to use
%   doMerge                - boolean, merge adjacent ELs?
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_pipelineMergeSpotsOpt` | `matRad_pipelineMergeSpotsOpt` | Full pipeline: select, merge, optimize, plot ELs | `matRad_pipelineMergeSpotsOpt(ct, cst, stf, dij, pln, wRBE, doseCubeRBE, voiDoseByEL, topELStruct, qiByEL, nTop, doMerge)` | 🟢 |
% -------------------------------------------------------------------------

% Sort and extract top N
voiDoseByEL_sorted = sortrows(voiDoseByEL, 'MaxDose', 'descend');
topELStruct_topN   = matRad_getTopELStruct(voiDoseByEL_sorted, topELStruct, nTop);

% Optimize (with or without merge)
[doseELOpt, wELOpt, wFilt, mergedStruct] = ...
    matRad_optSingleELMerged(dij, cst, pln, wRBE, topELStruct_topN, doMerge);

% Get original dose for comparison
if nTop == 1
    elName = voiDoseByEL_sorted.EL_Name{1};
    doseELorig = topELStruct.(elName).RBExDose;
else
    % Sum top-N doses
    ELNames = fieldnames(topELStruct_topN);
    doseELorig = zeros(size(doseCubeRBE));
    for i = 1:numel(ELNames)
        doseELorig = doseELorig + topELStruct_topN.(ELNames{i}).RBExDose;
    end
end

% Plot comparison
matRad_plotELCompare(ct, cst, doseCubeRBE, doseELorig, doseELOpt, [0 12]);

% Optional: visualize spot weights
matRad_wtEL(cst, stf, dij, wFilt, []); % assuming ixCord optional

end