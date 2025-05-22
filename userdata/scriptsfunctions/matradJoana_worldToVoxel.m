function voxelIndex = matradJoana_worldToVoxel(worldCoord, ctInfo)
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