function [stf, spotsInfoAll] = matRad_computeSpotPositions_Geo(ct, stf, machine)
% matRad_computeSpotPositionsGeo - Computes geometric world coordinates of each spot
% based on beam setup geometry without using WEPL information.
%
% Inputs:
%   ct        - CT structure (must contain resolution and origin)
%   stf       - Structure containing beam and ray geometry, isocenter info, and spot energies
%   machine   - [optional] Machine structure with energy-dependent beam data (e.g., Bragg peak depths)
%               If not provided, a default machine is loaded from matRad's machine library.
%
% Outputs:
%   stf            - Updated STF including spot positions in RAS and cube space
%   spotsInfoAll   - Linearized list of all computed spot structures across beams
%
% Notes:
%   - This function assumes geometric projection of spots along the beam direction.
%   - Spot positions are returned both in RAS (world) and cube (voxel) coordinates.
%   - This method does not use raytracing or WEPL-based calculation; it relies on
%     peak depth data from the machine and beam directionality.
%   - Beam direction is estimated from source and target position in BEV space.
%
%% %%%

% Load machine if not provided
if nargin < 3 || isempty(machine)
    machineFileName = append(stf.radiationMode, '_', stf.machine);
    machine = load(machineFileName);
    machine = machine.machine;
end

% Define LPS to RAS conversion
LPS_to_RAS = diag([-1, -1, 1]);

% Precompute the list of available energies
energyList = [machine.data(:).energy]';

% Initialize counter for all spots.
% There might be a smarter way to do this
iSpotsAll = 1;

numBeams = numel(stf);
% Loop over all beams
for iBeam = 1:numBeams
    % Beam info, including isoCenter
    gantryBeam = stf(iBeam).gantryAngle;
    couchBeam = stf(iBeam).couchAngle;

    isoCenterWorld = stf(iBeam).isoCenter;  % Isocenter in world coordinates (mm)
    isoCenterCube  = matRad_world2cubeIndex(isoCenterWorld, ct);
    isoCenterCube = isoCenterCube([2 1 3]);

    % Compute rotation matrix for this beam
    rotMat = matRad_getRotationMatrix(gantryBeam, couchBeam);

    numRays = numel(stf(iBeam).ray);
    % Loop over all rays in the current beam
    for iRay = 1:numRays
        rayPos_bev = stf.ray(iRay).rayPos_bev;
        targetPoint_bev = stf.ray(iRay).targetPoint_bev;
        rayPos = stf.ray(iRay).rayPos;
        targetPoint = stf.ray(iRay).targetPoint;

        % rayPos comes in LPS, need to convert it to RAS
        rayPosRelative_LPS = stf(iBeam).ray(iRay).rayPos;  % [x_rel, y_rel] in mm
        rayPosRelative_RAS = (LPS_to_RAS * rayPosRelative_LPS(:))';  % make row vector

        rayPosAbsXY = [rayPosRelative_LPS(1) + isoCenterWorld(1), ...
            rayPosRelative_LPS(2) + isoCenterWorld(2), ...
            isoCenterWorld(3)];  % (x,y,z) where z = isoCenterWorld(3)

        rayPosCube = matRad_world2cubeIndex(rayPosAbsXY, ct);
        rayPosCube = rayPosCube([2,1,3]);  % reorder (y,x,z) for voxel

        rotMat3D = matRad_getRotationMatrix(gantryBeam, couchBeam);

        % Estimate beam direction from sourcePoint_bev
        beamDir = stf.sourcePoint_bev(:)/max(abs(stf.sourcePoint_bev(:)));
        beamDir_LPS = rotMat3D * beamDir;
        beamDir_RAS = LPS_to_RAS * beamDir_LPS;  % Convert to RAS direction

        rayEnergy = stf(iBeam).ray(iRay).energy;
        if isscalar(rayEnergy)
            rayEnergy = rayEnergy(:); % make it a column vector (1 spot case)
        end

        % Preallocate spots
        numSpots = numel(rayEnergy);
        for iSpot = 1:numSpots
            thisEnergy = rayEnergy(iSpot);

            % Find corresponding machine entry
            spotInfoIdx = find(energyList == thisEnergy, 1, 'first');
            if isempty(spotInfoIdx)
                error('Energy %.2f MeV not found in machine definition.', thisEnergy);
            end
            spotInfo = machine.data(spotInfoIdx);

            % Create the spot structure
            spotStruct = struct();
            spotStruct.energy = thisEnergy;
            spotStruct.peakDepth = spotInfo.peakPos;  % peak depth (in mm)

            % Determine beam sign based on ray position
            if rayPos(1) == 0
                m = 0;
            elseif rayPos(1) < 0
                m = -1;
            else
                m = 1;
            end

            % Compute world position of the spot
            spotWorld = rayPosAbsXY - 0.1*spotStruct.peakDepth * beamDir_RAS';

            % Convert spotWorld to cube (voxel) indices
            spotCube = matRad_world2cubeIndex(spotWorld, ct);
            spotCube = spotCube([2,1,3]);  % reorder (y,x,z) for voxel

            % Store calculated fields
            spotStruct.rayPosAbsXY = rayPosAbsXY;
            spotStruct.rayPosCube = rayPosCube;
            spotStruct.spotWorld = spotWorld;
            spotStruct.spotCube = spotCube;

            % % Optional debug plots (can be removed if needed)
            % plot(rayPosCube(1), rayPosCube(2), 'r.', 'MarkerSize', 8, 'LineWidth', 1.2)
            % plot(spotCube(1), spotCube(2), 'y.', 'MarkerSize', 12, 'LineWidth', 1.2)

            % Extract the spot weight (same order as energies)
            if isfield(stf(iBeam).ray(iRay), 'weight')
                rayWeight = stf(iBeam).ray(iRay).weight;
                if numel(rayWeight) == numel(rayEnergy)
                    spotStruct.weight = rayWeight(iSpot);
                else
                    warning('Mismatch between number of energies and weights in ray %d, beam %d.', iRay, iBeam);
                    spotStruct.weight = NaN;
                end
            else
                spotStruct.weight = NaN; % if not available
            end

            spots(iSpot) = spotStruct;

            spotStruct.beam = iBeam;
            spotsInfoAll(iSpotsAll) = spotStruct;
            iSpotsAll = iSpotsAll+1;
        end

        % Store all spots inside the ray
        fieldname = ['ray_', num2str(iRay)];
        rayStruct.(fieldname) = spots;
        stf(iBeam).ray(iRay).spotsInfoGeo = spots;

            clear spots
    end

end
end
