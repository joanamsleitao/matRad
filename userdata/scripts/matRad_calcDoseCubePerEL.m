function [eLayerStruct] = matRad_calcDoseCubePerEL(dij, weights, eLayerStruct)
% MATRAD_CALCDOSECUBEPEREL - Compute dose cube contributions per selected energy layer
%
% Inputs:
%   dij                  - Dose influence matrix (struct with 'physicalDose')
%   resultGUI            - matRad result structure with .w
%   selectedEnergyStruct - Struct with fields for each selected energy layer
%
% Output:
%   dosePerEL - Struct with dose cube for each energy layer

layerNames = fieldnames(eLayerStruct);

for i = 1:numel(layerNames)
    name = layerNames{i};
    mask = eLayerStruct.(name).spotMask;

    wFiltered = weights .* mask;

    % Calculate dose
    % resultTemp = matRad_calcCubes(wFiltered, dij);

    % physicalDose
    tmp = reshape(full(dij.physicalDose{1} * (wFiltered .* 1)), dij.doseGrid.dimensions);
    tmp = matRad_interp3(dij.doseGrid.x,dij.doseGrid.y',dij.doseGrid.z, ...
        tmp, ...
        dij.ctGrid.x,dij.ctGrid.y',dij.ctGrid.z,'linear',0);

    if isfield(dij,'RBE') && isscalar(dij.RBE)
        
            tmp = tmp * dij.RBE;
        eLayerStruct.(name).RBExDose = tmp;
    else
        eLayerStruct.(name).physicalDose = tmp;
    end
    eLayerStruct.(name).w = wFiltered;

end
end