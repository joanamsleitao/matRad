function [logicalMask, removedIdx] = matRad_removeSpotsOverlappingVOIs(stf, ct, cst, ixVOI, iBeam)
% Removes spots overlapping with a given VOI (e.g., skin, air)
% Returns:
%   logicalMask - vector marking retained (true) and removed (false) spots
%   removedIdx  - linear indices of removed spots

ctSize = ct.cubeDim;  % [X Y Z] size of CT
voiLinearIdx = cst{ixVOI,4}{1};  % Linear indices of the VOI in CT space

numSpotsTotal = stf(iBeam).totalNumOfBixels;
logicalMask = true(numSpotsTotal, 1);
removedIdx = [];

ixCounter = 1;

for iRay = 1:stf(iBeam).numOfRays
    nSpots = stf(iBeam).numOfBixelsPerRay(iRay);

    for iSpot = 1:nSpots
        spotCube = stf(iBeam).ray(iRay).rayTracerInfo.perSpot(iSpot).spotCube;

        % Convert (x,y,z) voxel coordinates to linear index
        % Note: spotCube = [x y z] = [col row slice]
        if all(spotCube > 0) && all(spotCube <= ctSize)
            linIdx = sub2ind(ctSize, spotCube(2), spotCube(1), spotCube(3));

            if ismember(linIdx, voiLinearIdx)
                logicalMask(ixCounter) = false;
                removedIdx(end+1) = ixCounter; %#ok<AGROW>
            end
        end

        ixCounter = ixCounter + 1;
    end
end

end
