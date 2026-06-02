function [stf] = matRad_spotsPosSiddon(ct, stf, machine)
% matRad_computeSpotPositions_Siddon - Computes spot positions and ray tracing info for matRad STF structure.
%
% Inputs:
%   ct        - CT structure containing resolution, origin, and voxel grid
%   stf       - Spot target file (STF) structure containing beam and ray geometry
%   machine   - Machine data structure, including energy and peak position information
%
% Outputs:
%   stf             - Updated STF structure, now including rayTracerInfo per ray and per-spot position data
%   spotsInfoAll    - (currently unused) Placeholder for returning all spot info, if needed
%
% Description:
%   This function computes detailed ray tracing data (via Siddon’s algorithm) for each beam and ray
%   in the matRad spot target file. It determines water-equivalent path length (WEPL) segments, 
%   calculates where the Bragg peak would fall in the CT volume, and assigns spot positions 
%   accordingly. The spot positions are computed in both world (RAS) and cube (voxel) coordinates 
%   and stored in `rayTracerInfo.perSpot`.
%
%   The resulting `rayTracerInfo` is essential for downstream visualization or dose calculation
%   tasks. For example, `matRadJoana_visSpotsWeight` expects `rayTracerInfo` to exist for each ray.
%
% Notes:
%   - Uses Siddon ray tracing to determine voxel traversal and WEPL.
%   - Each ray’s `rayTracerInfo` includes WEPL, density, path indices, and spot locations.
%   - Spot positions are computed by shifting the Bragg peak depth along the ray by WEPL in air.
%   - Energies must match entries in the machine model (`machine.data.energy`).
%   - If `rayTracerInfo` already exists in `stf`, running this function again will overwrite it
%     without warning — use with care in iterative workflows.
%
%%
% Load machine if not provided
if nargin < 3 || isempty(machine)
    machineFileName = append(stf(1).radiationMode, '_', stf(1).machine);
    machine = load(machineFileName);
    machine = machine.machine;
end

% Ensure CT has water-equivalent density computed
if ~isfield(ct, 'cube') || isempty(ct.cube)
    ct = matRad_calcWaterEqD(ct, stf(1).radiationMode);  % Compute WEPL if missing
end

% Ensure STF has SSD computed
missingSSD = false;
for iBeam = 1:numel(stf)
    if ~isfield(stf(iBeam), 'ray') || isempty(stf(iBeam).ray)
        continue;
    end
    if ~isfield(stf(iBeam).ray(1), 'SSD')
        missingSSD = true;
        break;
    end
end
if missingSSD
    stf = matRad_computeSSD(stf, ct);  % Compute SSD if not present
end

%%
spr_air = 0.0012;                                              % Stopping power ratio for air

LPS_to_RAS = diag([-1, -1, 1]);                                % Matrix to convert coordinates from LPS to RAS

energyList = [machine.data(:).energy]';                        % Extract list of energies from machine model
rangeList = [machine.data(:).range]';                          % (Optional) list of ranges, unused here

iSpotsAll = 1;                                                 % Counter for all spots, placeholder for collection

numBeams = numel(stf);                                        % Loop over all beams in STF
for iBeam = 1:numBeams
    gantryBeam = stf(iBeam).gantryAngle;                      % Store beam gantry angle (currently unused)
    couchBeam = stf(iBeam).couchAngle;                        % Store beam couch angle (currently unused)

    cubeIsoCenter = matRad_world2cubeCoords(stf(iBeam).isoCenter,ct);  % Convert isocenter to cube (voxel) coordinates

    numRays = numel(stf(iBeam).ray);                          % Loop over all rays in current beam
    for iRay = 1:numRays
        ssd = stf(iBeam).ray(iRay).SSD;                       % Get source-to-surface distance for ray

        % Perform Siddon ray tracing to get path and WEPL
        [~,l,rho,~,ix] = matRad_siddonRayTracer(cubeIsoCenter, ...
            ct.resolution, ...
            stf(iBeam).sourcePoint, ...
            stf(iBeam).ray(iRay).targetPoint, ...
            {ct.cube{1}});

        wepl_segments = l .* rho{1};                          % Multiply segment lengths by densities
        cumulative_wepl = cumsum(wepl_segments);              % Accumulate WEPL along ray
        wepl_air = ssd * spr_air;                             % Estimate WEPL in air before patient

        % Store ray tracing info into rayTracerInfo struct
        rayTracerInfo.rho = rho;
        rayTracerInfo.l = l;
        rayTracerInfo.ix = ix;
        rayTracerInfo.wepl_segments = wepl_segments;
        rayTracerInfo.wepl_air = wepl_air;

        stf(iBeam).ray(iRay).rayTracerInfo = rayTracerInfo;   % Attach to STF ray

        rayEnergy = stf(iBeam).ray(iRay).energy;              % Get energy or energies for this ray

        if isscalar(rayEnergy)
            rayEnergy = rayEnergy(:);                         % Ensure it's a column vector for single-spot case
        end

        % Loop over all spot energies assigned to this ray
        numSpots = stf(iBeam).numOfBixelsPerRay(iRay);
        for iSpot = 1:numSpots
            thisEnergy = rayEnergy(iSpot);                    % Energy for current spot

            spotInfoIdx = find(energyList == thisEnergy, 1, 'first');  % Find energy in machine model

            if isempty(spotInfoIdx)
                error('Energy %.2f MeV not found in machine definition.', thisEnergy);  % Safety check
            end

            spotInfo = machine.data(spotInfoIdx);             % Get spot info from machine model
            peakDepth = spotInfo.peakPos;                     % Bragg peak position in water

            % Create and fill spot struct
            spotStruct = struct();
            spotStruct.infoIdx = spotInfoIdx;
            spotStruct.energy = thisEnergy;
            spotStruct.peakDepth = peakDepth;
            spotStruct.range = spotInfo.range;

            peakAdjusted = peakDepth + wepl_air;              % Account for WEPL in air before entering patient
            spotStruct.peakAdjusted = peakAdjusted;

            % Find voxel index where adjusted peak depth occurs along ray
            idx = find(cumulative_wepl >= peakAdjusted, 4);
            idx = idx(end);                                   % Choose last index crossing threshold

            spotWorld = matRad_cubeIndex2worldCoords(ix(idx), ct); % Convert voxel index to world coords
            spotCube = matRad_world2cubeIndex(spotWorld, ct);      % Convert back to cube index for consistency
            spotCube = [spotCube(2), spotCube(1), spotCube(3)];    % Reorder for plotting convention

            spotStruct.spotWorld = spotWorld;
            spotStruct.spotCube = spotCube;

            % Assign weight to spot if available
            if isfield(stf(iBeam).ray(iRay), 'weight')
                rayWeight = stf(iBeam).ray(iRay).weight;
                if numel(rayWeight) == numel(rayEnergy)
                    spotStruct.weight = rayWeight(iSpot);
                else
                    warning('Mismatch between number of energies and weights in ray %d, beam %d.', iRay, iBeam);
                    spotStruct.weight = NaN;
                end
            else
                spotStruct.weight = NaN;                       % If no weight info, assign NaN
            end

            spots(iSpot) = spotStruct;                         % Add spot to list
            % spotsInfoAll(iSpotsAll) = spotStruct;           % Optional: collect globally
            iSpotsAll = iSpotsAll+numSpots;                           % Increment global counter
        end

        rayTracerInfo.perSpot = spots;                         % Add per-spot info to rayTracerInfo
        stf(iBeam).ray(iRay).rayTracerInfo = rayTracerInfo;    % Update STF with full rayTracerInfo
        clear spotStruct spots
    end

    clear spots                                               % Clear spot buffer before next beam
end
end
