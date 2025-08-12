function dosePerEL = matRad_calcDoseCubePerEL(dij, resultGUI, selectedEnergyStruct)
% MATRAD_CALCDOSECUBEPEREL - Compute dose cube contributions per selected energy layer
%
% Inputs:
%   dij                  - Dose influence matrix (struct with 'physicalDose')
%   resultGUI            - matRad result structure with .w
%   selectedEnergyStruct - Struct with fields for each selected energy layer
%
% Output:
%   dosePerEL - Struct with dose cube for each energy layer

dosePerEL = struct;
w = resultGUI.w;
layerNames = fieldnames(selectedEnergyStruct);

for i = 1:numel(layerNames)
    name = layerNames{i};
    mask = selectedEnergyStruct.(name).spotMask;

    wFiltered = w .* mask;

    % Calculate dose
    resultTemp = matRad_calcCubes(wFiltered, dij);
    dosePerEL.(name) = resultTemp.physicalDose;
    clear resultTemp
end
end