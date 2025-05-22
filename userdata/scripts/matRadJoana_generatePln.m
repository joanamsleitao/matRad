function [pln] = matRadJoana_generatePln(cst,ct, gantryAngles, doseGridResolution, modality)
%Creates a very basic pln

if ~exist('gantryAngles', 'var') || isempty(gantryAngles)
    gantryAngles = [0];
end

if ~exist('resolution', 'var') || isempty(doseGridResolution)
    doseGridResolution = [3 3 3];
end

if ~exist('modality', 'var') || isempty(modality)
    modality = 'photons';
else
    if modality == 1
        modality = 'photons';
    elseif modality == 2
        modality = 'protons';
    elseif modality == 3
        modality = 'carbons';
    else
        modality = 'photons';
    end
end

%%
pln.radiationMode   = modality;
pln.machine = 'Generic';
pln.numOfFractions  = 1;

pln.bioModel = 'none';
pln.multScen = 'nomScen';
pln.quantityOpt = 'none';

pln.propStf.gantryAngles    =  gantryAngles;
pln.propStf.couchAngles     = zeros(1,numel(pln.propStf.gantryAngles));
pln.propStf.bixelWidth      = 5;

pln.propStf.numOfBeams   = numel(pln.propStf.gantryAngles);
pln.propStf.isoCenter    = matRad_getIsoCenter(cst,ct,0);

pln.propDoseCalc.doseGrid.resolution.x = doseGridResolution(1); % [mm]
pln.propDoseCalc.doseGrid.resolution.y = doseGridResolution(2); % [mm]
pln.propDoseCalc.doseGrid.resolution.z = doseGridResolution(3); % [mm]
end