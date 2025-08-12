function voxelIndex = matRad_worldToVoxel(worldCoord, ctInfo)
% matrad_worldToVoxel - Converts world coordinates to voxel indices
%
% Syntax:  voxelIndex = matRad_worldToVoxel(worldCoord, ctInfo)
%
% Inputs:
%   worldCoord - World coordinates [x y z] (vector)
%   ctInfo     - CT information structure (struct)
%
% Outputs:
%   voxelIndex - Voxel indices [i j k] (vector)
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_world2cubeIndex
%
    % Ensure column vector
    if isrow(worldCoord)
        worldCoord = worldCoord';
    end

    % Compute voxel index (1-based, MATLAB-style)
    voxelIndex = round((worldCoord - ctOrigin') ./ voxelSize') + 1;

    % Clip to bounds (optional safety check)
    voxelIndex = max(voxelIndex, [1;1;1]);
    voxelIndex = min(voxelIndex, ct.cubeDim');
end