function ix = matRad_spotIx(stf, iBeam, iRay, iSpot)
% matRad_spotIx - Computes the global spot index from beam, ray, and spot indices.
%
% This utility function computes the 1D index of a spot (e.g., for use in weight vectors)
% based on its position in a beam, ray, and bixel/spot number within the ray.
%
% Inputs:
%   stf    - stf structure 
%   iBeam  - Index of the beam (1-based)
%   iRay   - Index of the ray within the beam (1-based)
%   iSpot  - Index of the spot within the ray (1-based)
%
% Output:
%   ix     - Global 1D index of the spot
%
% Note:
%   - Assumes a flat 1D indexing of all bixels across all beams and rays.
%   - Requires the fields: totalNumOfBixels (per beam) and numOfBixelsPerRay (per beam).
%
%%
% Input validation
numBeams = numel(stf);

if ~isscalar(iBeam) || iBeam < 1 || iBeam > numBeams || floor(iBeam) ~= iBeam
    error('Invalid iBeam index. Must be an integer between 1 and %d.', numBeams);
end

numRays = numel(stf(iBeam).ray);
if ~isscalar(iRay) || iRay < 1 || iRay > numRays || floor(iRay) ~= iRay
    error('Invalid iRay index. Must be an integer between 1 and %d for beam %d.', numRays, iBeam);
end

numSpots = stf(iBeam).numOfBixelsPerRay(iRay);
if ~isscalar(iSpot) || iSpot < 1 || iSpot > numSpots || floor(iSpot) ~= iSpot
    error('Invalid iSpot index. Must be an integer between 1 and %d for beam %d ray %d.', numSpots, iBeam, iRay);
end

% Compute global index
ixTotal = 0;

% Accumulate bixels from previous beams
for i = 1:iBeam-1
    ixTotal = ixTotal + stf(i).totalNumOfBixels;
end

% Accumulate bixels from previous rays in current beam
for i = 1:iRay-1
    ixTotal = ixTotal + stf(iBeam).numOfBixelsPerRay(i);
end

% Add current spot index
ixTotal = ixTotal + iSpot;

ix = ixTotal;
end
