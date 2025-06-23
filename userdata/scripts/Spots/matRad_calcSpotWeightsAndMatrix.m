function [stf, wMatrix] = matRad_calcSpotWeightsAndMatrix(stf, weights)
% matRad_calcSpotWeightsAndMatrix - Normalizes and assigns spot weights, and constructs a 3D weight matrix.
%
% This function takes a flat list of spot weights (as computed by the dose engine),
% normalizes them relative to the global maximum, and assigns them to the corresponding
% spot entries in the `stf.ray.rayTracerInfo.perSpot` structure. It also builds a 3D
% matrix (X × Z × Energy) of weights per beam, useful for visualization and analysis.
%
% Inputs:
%   stf     - Spot Target File (STF) structure, with beam, ray, and rayTracerInfo fields.
%   weights - Vector of raw spot weights for all bixels (ordered by beam, ray, bixel).
%
% Outputs:
%   stf     - Updated STF with `perSpot(s).weight` fields set to normalized values.
%   wMatrix - Cell array of 3D weight matrices per beam (X × Z × Energy).
%
% Notes:
%   - If `rayTracerInfo.perSpot` is missing, a warning is issued and no update is performed.
%   - The bixel width and ray BEV positions are used to place weights in matrix coordinates.
%
% See also: matRad_computeStf, matRad_computeDose

%% Initialization

numOfBeams = numel(stf);
wMax = max(weights);
wIx = 1;

for iBeam = 1:numOfBeams
    fprintf('Calculate weights for Beam %d...\n', iBeam);

    % Extract ray positions for bounding box
    rayPos_mat = vertcat(stf(iBeam).ray(:).rayPos_bev);
    x_min = min(rayPos_mat(:, 1));
    z_min = min(rayPos_mat(:, 3));
    x_max = max(rayPos_mat(:, 1));
    z_max = max(rayPos_mat(:, 3));

    % Create energy bins from unique energies in this beam
    allEnergies = unique(cat(2, stf(iBeam).ray(:).energy));
    numEnergies = numel(allEnergies);

    % Initialize weight matrix
    wMatrix{iBeam} = zeros( ...
        (x_max - x_min) / stf(iBeam).bixelWidth, ...
        (z_max - z_min) / stf(iBeam).bixelWidth, ...
        numEnergies);

    for iRay = 1:stf(iBeam).numOfRays
        currentRay = stf(iBeam).ray(iRay);
        numSpots = stf(iBeam).numOfBixelsPerRay(iRay);

        % Get normalized weights for this ray
        wNormPerRay = weights(wIx : wIx + numSpots - 1) / wMax;

        % Assign weights to perSpot field
        if isfield(currentRay, 'rayTracerInfo') && isfield(currentRay.rayTracerInfo, 'perSpot')
            if numel(currentRay.rayTracerInfo.perSpot) == numSpots
                for s = 1:numSpots
                    stf(iBeam).ray(iRay).rayTracerInfo.perSpot(s).weight = wNormPerRay(s);
                end
            else
                warning('Mismatch in number of weights and perSpot entries (Beam %d, Ray %d).', iBeam, iRay);
                for s = 1:numel(currentRay.rayTracerInfo.perSpot)
                    stf(iBeam).ray(iRay).rayTracerInfo.perSpot(s).weight = NaN;
                end
            end
        else
            warning('Missing rayTracerInfo.perSpot in Beam %d, Ray %d.', iBeam, iRay);
        end

        % Compute voxel indices
        xpos = (currentRay.rayPos_bev(1) - x_min) / stf(iBeam).bixelWidth + 1;
        zpos = (currentRay.rayPos_bev(3) - z_min) / stf(iBeam).bixelWidth + 1;

        % Determine energy layer index (assumes constant energy per ray)
        % Take the first energy value as representative for the ray
        rayEnergy = currentRay.energy(1);
        [~, energyIdx] = ismember(rayEnergy, allEnergies);

        if energyIdx > 0
            wMatrix{iBeam}(xpos, zpos, energyIdx) = mean(wNormPerRay);
        else
            warning('Energy %g not found in energy list for Beam %d, Ray %d.', rayEnergy, iBeam, iRay);
        end

        wIx = wIx + numSpots;
    end
end
end
