function [pln] = matRad_generatePln(cst, ct, gantryAngles, doseGridResolution, modality)
% matRad_generatePln - Create a basic matRad plan structure
%
% Syntax:
%   pln = matRad_generatePln(cst, ct, gantryAngles, doseGridResolution, modality)
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

if ~exist('resolution', 'var') || isempty(doseGridResolution)
    doseGridResolution = [3 3 3];
end

if ~exist('modality', 'var') || isempty(modality)
    modality = 'photons';
end

%%
pln.radiationMode   = modality;
pln.machine = 'Generic';
pln.numOfFractions  = 1;

pln.bioModel = 'none';
pln.multScen = 'nomScen';

pln.propStf.gantryAngles    =  gantryAngles;
pln.propStf.couchAngles     = zeros(1,numel(pln.propStf.gantryAngles));
pln.propStf.bixelWidth      = 5;

pln.propStf.numOfBeams   = numel(pln.propStf.gantryAngles);
pln.propStf.isoCenter    = matRad_getIsoCenter(cst,ct,0);

pln.propDoseCalc.doseGrid.resolution.x = doseGridResolution(1); % [mm]
pln.propDoseCalc.doseGrid.resolution.y = doseGridResolution(2); % [mm]
pln.propDoseCalc.doseGrid.resolution.z = doseGridResolution(3); % [mm]

if ~strcmp(modality, 'photons')
    pln.bioModel = matRad_bioModel(pln.radiationMode,'none');
% pln.propOpt.bioOptimization = 'none';
pln.propDoseCalc.calcLET = 0;
pln.propDoseCalc.engine = 'HongPB';
end

end