%% Example: Proton Treatment Plan with Energy-Layer Analysis
%
% In this example, we demonstrate how to run a treatment plan in matRad
% and then analyze contributions from individual energy layers. We show
% how to call each of the helper functions individually, and finally how
% they are combined in the new wrapper function
%   matRad_EnergyLayerAnalysis.
%

%% set matRad runtime configuration
matRad_rc; % If this throws an error, run it from the parent directory first to set the paths

%% Patient Data Import
load('PROSTATE.mat');

%% Treatment Plan
matRad_cfg.defaults.propOpt.maxIter = 100;
pln = matRad_generatePln(cst, ct, 180, [10 10 10], 'protons');

stf = matRad_generateStf(ct,cst,pln);
dij = matRad_calcDoseInfluence(ct,cst,stf,pln);
resultGUI = matRad_fluenceOptimization(dij,cst,pln);

% Compute spot positions
stf = matRad_computeSpotPositions_Siddon(ct, stf);

%% Energy-Layer Analysis (step-by-step functions)

% --- 1) Weight energy layers ---
% Summarizes layer contributions (weights) for selected VOIs
ixTarget = matRad_VOIfindIndex(cst, 'PTV_68');
ixOAR    = matRad_VOIfindIndex(cst, 'Bladder');
cstSmall = [cst(ixTarget,:); cst(ixOAR,:)];

[layerSummary, topELStruct, ~, ~] = matRad_weightEnergyLayers(cstSmall, stf, dij, resultGUI, ixOAR);

% --- 2) Attach dose cubes per energy layer ---
% Computes dose distribution for each EL separately
topELStruct = matRad_calcDoseCubePerEL(dij, resultGUI, topELStruct);

% --- 3) Attach rays to energy layer struct ---
% Links geometry info (spots/rays) to the energy layer data
topELStruct = matRad_energyLayer_attachRaysToELStruct(topELStruct, stf);

% --- 4) Compute per-VOI, per-EL dose metrics ---
% Generates tables and structs with Dmean, Dmax, Vx, Dx, etc.
[voiDoseByEL, qiByEL] = matRad_energyLayer_perVOIDose(cstSmall, topELStruct, dij, resultGUI.w);

% Example access of qiByEL:
% qiByEL.EL_97_5MeV.PTV_68.mean
% qiByEL.EL_99_8MeV.Bladder.V_2Gy

% --- 5) Visualization ---
% Visualize dose distribution & spot map for each EL
matRad_energyLayer_plotDosePerEL(ct, cst, stf, topELStruct, qiByEL, 'PTV_68');

%% All-in-one wrapper
% Instead of running all steps separately, you can use the new function:
%
%   [voiDoseByEL, qiByEL, topELStruct] = matRad_EnergyLayerAnalysis( ...
%       cst, stf, dij, ct, resultGUI, ixTarget, ixOAR);
%
% This combines steps (1)–(5) into one convenient call.
