function doseInVoi = matRad_getDoseInVOI(doseCube, cst, idx)
    % Extract dose values for all voxels in a VOI
    % Handles multi-part masks (consistent with matRad_calcQI)
    %
    % Inputs:
    %   doseCube - 3D dose distribution
    %   cst      - matRad structure set
    %   idx      - VOI index in CST
    %
    % Outputs:
    %   doseInVoi - Vector of dose values for VOI voxels
    
    vox = [];
    for k = 1:numel(cst{idx,4})
        vox = [vox; cst{idx,4}{k}(:)];
    end
    vox = unique(vox);
    doseInVoi = doseCube(vox);
end