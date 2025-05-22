% matRad script
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% set matRad runtime configuration
matRad_rc

%% load patient data, i.e. ct, voi, cst
load TG119.mat
%load HEAD_AND_NECK
%load PROSTATE.mat
%load LIVER.mat
%load BOXPHANTOM.mat

% meta information for treatment plan
pln.numOfFractions  = 30;
pln.radiationMode   = 'protons';            % either photons / protons / helium / carbon / brachy
pln.machine         = 'Generic';            % generic for RT / LDR or HDR for BT

% beam geometry settings
pln.propStf.bixelWidth      = 5; % [mm] / also corresponds to lateral spot spacing for particles
pln.propStf.gantryAngles    = 0; % [°] ;
pln.propStf.couchAngles     = 0; % [°] ; 
pln.propStf.numOfBeams      = numel(pln.propStf.gantryAngles);
pln.propStf.isoCenter       = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);
% optimization settings
pln.propOpt.runDAO          = false;      % 1/true: run DAO, 0/false: don't / will be ignored for particles
pln.propOpt.runSequencing   = false;      % 1/true: run sequencing, 0/false: don't / will be ignored for particles and also triggered by runDAO below

quantityOpt  = 'RBExD';     % options: physicalDose, effect, RBExD
modelName    = 'constRBE';             % none: for photons, protons, carbon, brachy    % constRBE: constant RBE for photons and protons 
                                   % MCN: McNamara-variable RBE model for protons  % WED: Wedenberg-variable RBE model for protons 
                                   % LEM: Local Effect Model for carbon ions       % HEL: data-driven RBE parametrization for helium
% dose calculation settings
pln.propDoseCalc.doseGrid.resolution.x = 5; % [mm]
pln.propDoseCalc.doseGrid.resolution.y = 5; % [mm]
pln.propDoseCalc.doseGrid.resolution.z = 5; % [mm]                                   

% retrieve bio model parameters
pln.bioParam = matRad_bioModel(pln.radiationMode,quantityOpt, modelName);

% nominal scenario
pln.multScen = matRad_multScen(ct,'nomScen');

%% initial visualization and change objective function settings if desired
matRadGUI

%% generate steering file 
stf = matRad_generateStf(ct,cst,pln);

%% dose calculation
dij = matRad_calcDoseInfluence(ct, cst, stf, pln);

%% inverse planning for imrt
resultGUI  = matRad_fluenceOptimization(dij,cst,pln);

%% indicator calculation and show DVH and QI without robustness
resultGUI = matRad_planAnalysis(resultGUI,ct,cst,stf,pln);

%% Enable a worst case model
pln.multScen = matRad_WorstCaseScenarios(ct);
%Parameters
pln.multScen.rangeRelSD = 3.5;      %relative range error standard deviation in percent
pln.multScen.rangeAbsSD = 1;        %absolute range shift standard deviation in mm
pln.multScen.shiftSD    = [3 3 3];  %absolute isocenter shift standard deviation in [x y z] in mm
pln.multScen.wcSigma    = 2;        %Our worst case definition in multiples of standard deviation (for example, a worst-case shift in the WorstCaseScenario model will be calculated as wcSigma*shiftSD)

resultGUI = matRad_calcDoseForward(ct,cst,stf,pln,resultGUI.w);
resultGUI = matRad_planAnalysis(resultGUI,ct,cst,stf,pln);

%% Second option: random model
pln.multScen = matRad_RandomScenarios(ct);
pln.multScen.rangeRelSD = 3.5;      %relative range error standard deviation in percent
pln.multScen.rangeAbsSD = 1;        %absolute range shift standard deviation in mm
pln.multScen.shiftSD    = [3 3 3];  %absolute isocenter shift standard deviation in [x y z] in mm
pln.multScen.nSamples   = 25;       %Here we need to define the number of random samples we are going to pick

resultGUI = matRad_calcDoseForward(ct,cst,stf,pln,resultGUI.w);
resultGUI = matRad_planAnalysis(resultGUI,ct,cst,stf,pln);


