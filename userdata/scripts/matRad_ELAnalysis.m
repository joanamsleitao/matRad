function [voiDoseByEL, qiByEL, topELStruct] = matRad_ELAnalysis(cst, stf, dij, ct, resultGUI, ixTarget, ixOAR)
% matRad_runEnergyLayerAnalysis
%   Run per-energy-layer dose and QI analysis, plus visualization
%
% Inputs:
%   cst       - matRad structure table
%   stf       - beam geometry struct
%   dij       - dose influence matrix
%   ct        - patient CT
%   resultGUI - optimization result struct
%   ixTarget     - index of GTV in cst
%   ixOAR    - index of cord in cst
%
% Outputs:
%   voiDoseByEL - table of VOI x energy layer metrics
%   qiByEL      - struct of QIs per VOI & EL
%   topELStruct - energy layer struct with attached doses & rays
%
% Example:
%   [voiDoseByEL, qiByEL, topELStruct] = matRad_runEnergyLayerAnalysis(cst, stf, dij, ct, resultGUI, ixTarget, ixOAR);

%% Extract basic inputs
doseCube = resultGUI.physicalDose;
w        = resultGUI.w;

cstSmall = [cst(ixTarget, :); cst(ixOAR, :);];
ixTargetN = find(strcmp({cstSmall{:,2}}, cst{ixTarget, 2}));
nTarget = cstSmall{ixTargetN, 2};
ixOARN = find(strcmp({cstSmall{:,2}}, cst{ixOAR, 2}));
nOAR = cstSmall{ixOARN, 2};

%% Weighting & energy layer setup
[layerSummary, topELStruct, ~, ~] = matRad_weightEnergyLayers(cstSmall, stf, dij, resultGUI.w, ixOARN);

% attach dose cubes & rays
topELStruct = matRad_calcDoseCubePerEL(dij, resultGUI.w, topELStruct);
topELStruct = matRad_energyLayer_attachRaysToELStruct(topELStruct, stf);

%% Compute per-VOI, per-EL metrics
[voiDoseByEL, qiByEL] = matRad_energyLayer_perVOIDose(cstSmall, topELStruct, dij, w);

%% Visualization: Dose distributions per EL
matRad_energyLayer_plotDosePerEL(ct, cst, stf, topELStruct, qiByEL, nTarget);

end
