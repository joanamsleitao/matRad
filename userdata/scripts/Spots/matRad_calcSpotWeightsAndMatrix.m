function [stf, wMatrix] = matRad_calcSpotWeightsAndMatrix(stf, weights)
% matRad_calcSpotWeightsAndMatrix - Computes normalized spot weights and fills a 3D weight matrix
% for each beam, organized by bixel (x/z position) and energy.
% Partially adapted from matRad_visSpotWeights.m
%
% This function constructs a weight matrix for each beam in the spot target file (STF)
% and assigns normalized weights to individual spots based on their energy and position.
% It also updates per-spot weights in auxiliary fields if available.
%
% Inputs:
%   stf     - stf containing beam, ray, and spot data.
%   weights - Vector of raw spot weights corresponding to all bixels (spots).
%
% Outputs:
%   stf            - Updated STF structure with normalized weights assigned per ray and per spot.
%   wMatrix  - Cell array containing 3D matrices (X × Z × Energy) of normalized weights per beam.
%
% Notes:
%   - Normalized weights are scaled relative to the maximum weight in the input vector.
%   - If the field `stf.ray.spotsInfoGeo` exists, the normalized weight is also stored in
%     `stf.ray(iRay).spotsInfoGeo(s).weight` for each spot `s`.
%   - If the field `stf.ray.rayTracerInfo.perSpot` exists, the normalized weight is stored in
%     `stf.ray(iRay).rayTracerInfo.perSpot(s).weight` as well.
%   - Warnings are issued when the number of weights does not match the number of spots.
%
% See also: matRad_computeStf, matRad_initStf, matRad_computeSSD
%
%% %%%

numOfBeams = size(stf,2);

% Construct bixel lookup table
counter = 0;
for i = 1:numOfBeams
    for j = 1:stf(i).numOfRays
        for k = 1:stf(i).numOfBixelsPerRay(j)
            counter = counter + 1;
            bixelLut.beamNum(counter)   = i;
            bixelLut.rayNum(counter)    = j;
            bixelLut.bixelNum(counter)  = k;
            bixelLut.energy(counter)    = stf(i).ray(j).energy(k);
        end
    end
end

wMax = max(weights);

% Loop over beams
for iBeam = 1:numOfBeams
    fprintf('Calculate weights for Beam %d...\n', iBeam);

    % Extract ray positions
    rayPos_mat = vertcat(stf(iBeam).ray(:).rayPos_bev);
    x_min = min(rayPos_mat(:, 1));
    z_min = min(rayPos_mat(:, 3));
    x_max = max(rayPos_mat(:, 1));
    z_max = max(rayPos_mat(:, 3));

    % Extract and count energies
    all_energies{iBeam} = unique(cat(2, stf(iBeam).ray(:).energy));
    numOfEnergies(iBeam) = length(all_energies{iBeam});

    % Initialize weight matrix for this beam
    wMatrix{iBeam} = zeros( ...
        (x_max - x_min) / stf(iBeam).bixelWidth, ...
        (z_max - z_min) / stf(iBeam).bixelWidth, ...
        numOfEnergies(iBeam));

    % Find bixels for current beam
    beam_ix = (bixelLut.beamNum == iBeam);

    for j = 1:numOfEnergies(iBeam)
        energy_ix = and((bixelLut.energy == all_energies{iBeam}(j)), beam_ix);

        numRays = numel(stf(iBeam).ray);
        for iRay = 1:numRays

            % Get ray tracer info
            currentRay = stf(iBeam).ray(iRay).rayTracerInfo;

            % Get weight indices for this ray and energy
            wIx = and((bixelLut.rayNum == iRay), energy_ix);
            wNorm = weights(wIx) / wMax;

            if isempty(wNorm)
                wNorm = 0;
            end

            %%
            % Update spot-level weights in spotsInfoGeo if available
            if isfield(stf(iBeam).ray(iRay), 'spotsInfoGeo')
                % Number of bixels/spots expected
                numSpots = numel(stf(iBeam).ray(iRay).spotsInfoGeo);

                if numel(wNorm) == numSpots
                    for s = 1:numSpots
                        stf(iBeam).ray(iRay).spotsInfoGeo(s).weight = wNorm(s);
                    end
                else
                    warning('Mismatch in number of weights and spotsInfoGeo entries in beam %d, ray %d.', iBeam, iRay);
                    for s = 1:numSpots
                        stf(iBeam).ray(iRay).spotsInfoGeo(s).weight = NaN;
                    end
                end
            end

            % Update perSpot.weight in rayTracerInfo if available
            if isfield(stf(iBeam).ray(iRay), 'rayTracerInfo') && ...
                    isfield(stf(iBeam).ray(iRay).rayTracerInfo, 'perSpot')

                numPerSpot = numel(stf(iBeam).ray(iRay).rayTracerInfo.perSpot);

                if numel(wNorm) == numPerSpot
                    for s = 1:numPerSpot
                        stf(iBeam).ray(iRay).rayTracerInfo.perSpot(s).weight = wNorm(s);
                    end
                else
                    warning('Mismatch in number of weights and rayTracerInfo.perSpot entries in beam %d, ray %d.', iBeam, iRay);
                    for s = 1:numPerSpot
                        stf(iBeam).ray(iRay).rayTracerInfo.perSpot(s).weight = NaN;
                    end
                end
            end

            %%


            % Compute matrix coordinates
            xpos = (stf(iBeam).ray(iRay).rayPos_bev(1) + abs(x_min)) / stf(iBeam).bixelWidth + 1;
            zpos = (stf(iBeam).ray(iRay).rayPos_bev(3) + abs(z_min)) / stf(iBeam).bixelWidth + 1;

            wMatrix{iBeam}(xpos, zpos, j) = wNorm;
        end
    end
    % 
    % % Store result in STF
    % stf(iBeam).wMatrix = wMatrix;
end
