function [doseCube, type] = matRad_doseCubeExtract(resultGUI)
% matRad_doseCubeExtract - Extract dose cube from resultGUI
%
% Syntax:
%   doseCube = matRad_doseCubeExtract(resultGUI)
%
% Inputs:
%   resultGUI - matRad resultGUI struct
%
% Outputs:
%   doseCube - 3D dose array (empty if not found)
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

doseCube = [];

if isempty(resultGUI)
    return;
end

if isfield(resultGUI, 'physicalDose')
    doseCube = resultGUI.physicalDose;
    type = 'physicalDose';
elseif isfield(resultGUI, 'RBExDose')
    doseCube = resultGUI.RBExDose;
    type = 'RBExDose';
else
    warning('No dose cube found in resultGUI.');
end

end