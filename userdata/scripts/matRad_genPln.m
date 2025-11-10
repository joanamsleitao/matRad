function [pln] = matRad_genPln(cst, ct, gantryAngles, doseGridResolution, modality)
% matRad_genPln - Create a basic matRad plan structure
%
% Syntax:
%   pln = matRad_genPln(cst, ct, gantryAngles, doseGridResolution, modality)
%
% Inputs:
%   cst               - matRad CST structure
%   ct                - matRad CT structure
%   gantryAngles      - Optional vector of gantry angles [deg] (default: [0])
%   doseGridResolution- Optional [dx dy dz] dose resolution in mm (default: [3 3 3])
%   modality          - Optional radiation mode ('photons', 'protons', etc.)
%
% Outputs:
%   pln - matRad plan struct with initialized geometry, grid, and dose settings
%
% Description:
%   Generates a minimal but valid matRad plan struct suitable for further
%   dose calculation or beam geometry generation.
%
% Other m-files required: matRad_getIsoCenter, matRad_bioModel
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_generateStf, matRadJoana_generateStfOneEL
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if ~exist('gantryAngles', 'var') || isempty(gantryAngles)
    gantryAngles = [0];
end

if ~exist('doseGridResolution', 'var') || isempty(doseGridResolution)
    doseGridResolution = [3 3 3];
end

if ~exist('modality', 'var') || isempty(modality)
    modality = 'photons';
end

%%
pln.radiationMode   = modality;
pln.machine = 'Generic';
pln.numOfFractions  = 1;

% pln.bioModel = 'none';
pln.multScen = 'nomScen';
pln.bioModel = matRad_bioModel(pln.radiationMode, 'constRBE');

pln.propStf.gantryAngles    =  gantryAngles;
pln.propStf.couchAngles     = zeros(1,numel(pln.propStf.gantryAngles));
pln.propStf.bixelWidth      = 5;

pln.propStf.numOfBeams   = numel(pln.propStf.gantryAngles);
pln.propStf.isoCenter       = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);

% OR
% pln.propStf.isoCenter     = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);

pln.propDoseCalc.doseGrid.resolution.x = doseGridResolution(1); % [mm]
pln.propDoseCalc.doseGrid.resolution.y = doseGridResolution(2); % [mm]
pln.propDoseCalc.doseGrid.resolution.z = doseGridResolution(3); % [mm]

pln.propDoseCalc.calcLET = 0;
pln.propDoseCalc.engine = 'HongPB';

%Optimization Settings
pln.propOpt.quantityOpt = 'RBExDose';
pln.propOpt.runDAO        = 0;

pln.propSeq.runSequencing = 0;

if strcmp(modality, 'photons')
    %     pln.bioModel = matRad_bioModel(pln.radiationMode,'none');
    % % pln.propOpt.bioOptimization = 'none';
    % pln.propDoseCalc.engine = 'HongPB';

    pln.radiationMode           = 'photons';
    pln.machine                 = 'Generic';
    % % Enable sequencing and direct aperture optimization (DAO).
    % pln.propOpt.runSequencing   = 1;
    % pln.propOpt.runDAO          = 1;

    pln.propOpt.quantityOpt    = 'physicalDose';
    modelName      = 'none';

    % retrieve bio model parameters
    % pln.bioModel = matRad_bioModel(pln.radiationMode, 'none');

    % retrieve scenarios for dose calculation and optimziation
    pln.multScen = matRad_NominalScenario(ct);

end

end