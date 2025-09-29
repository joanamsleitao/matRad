function [dose] = matRad_calcDoseCubeSimple(dij, w)
% MATRAD_CALCDOSECUBEPEREL - Compute dose cube contributions per selected energy layer
%
% Inputs:
%   dij                  - Dose influence matrix (struct with 'physicalDose')
%   resultGUI            - matRad result structure with .w
%
% Output:
%   dose - Struct with dose cube for each energy layer
%%
dose = [];
% physicalDose
tmp = reshape(full(dij.physicalDose{1} * (w .* 1)), dij.doseGrid.dimensions);
tmp = matRad_interp3(dij.doseGrid.x,dij.doseGrid.y',dij.doseGrid.z, ...
    tmp, ...
    dij.ctGrid.x,dij.ctGrid.y',dij.ctGrid.z,'linear',0);

if isfield(dij,'RBE') && isscalar(dij.RBE)
    tmp = tmp * dij.RBE;
    result.RBExDose = tmp;
end
dose = tmp;
end