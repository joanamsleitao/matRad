function allELStruct = matRad_attachRays(allELStruct, stf)
% matRad_buildELperSpot - Add perSpot field to each EL struct (flat list of spots)
%
% INPUTS:
%   allELStruct - structure with one field per energy layer (EL_XX_XMeV)
%   stf         - matRad spot target file with rayTracerInfo.perSpot populated
%
% OUTPUT:
%   allELStruct - same structure, now with .perSpot field per EL
%
% DESCRIPTION:
%   For each energy layer (EL), this function collects all spots from stf
%   that belong to that energy and appends them into a flat list:
%
%       allELStruct.EL_xxx.perSpot = [struct struct ...]
%
%   Each perSpot entry includes:
%       energy, spotCube, spotWorld, weight, beamIdx, rayIdx
%
%   This makes it easy to loop over all spots for a given EL without going
%   through beams/rays manually.
%
% EXAMPLE:
%   allELStruct = matRad_buildELperSpot(allELStruct, stf);
%   allELStruct.EL_97_5MeV.perSpot(3)

% Get all EL names
ELfields = fieldnames(allELStruct);

for iEL = 1:numel(ELfields)
    ELname = ELfields{iEL};
    ELdata = allELStruct.(ELname);
    targetEnergy = ELdata.energy;
    
    % Init container for spots in this EL
    perSpotList = [];
    
    % Loop over all beams and rays in STF
    for iBeam = 1:numel(stf)
        for iRay = 1:numel(stf(iBeam).ray)
            raySpots = stf(iBeam).ray(iRay).rayTracerInfo.perSpot;
            
            % Keep only spots with this EL's energy (match within tolerance)
            matchIdx = find(abs([raySpots.energy] - targetEnergy) < 1e-6);
            
            for m = matchIdx
                newSpot = struct( ...
                    'energy',    raySpots(m).energy, ...
                    'spotCube',  raySpots(m).spotCube, ...
                    'spotWorld', raySpots(m).spotWorld, ...
                    'weight',    raySpots(m).weight, ...
                    'beamIdx',   iBeam, ...
                    'rayIdx',    iRay );
                
                perSpotList = [perSpotList; newSpot]; %#ok<AGROW>
            end
        end
    end
    
    % Save into EL struct
    allELStruct.(ELname).perSpot = perSpotList;
end
end
