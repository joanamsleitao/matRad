function [allEnergies, numOfEnergies, numOfRays] = matRadJoana_checkEnergies(stf)
% matRadJoana_checkEnergies - Lists energy layers per beam in STF
%
% Syntax:
%   [allEnergies, numOfEnergies, numOfRays] = matRadJoana_checkEnergies(stf)
%
% Inputs:
%   stf - matRad stf structure containing beam and ray definitions
%
% Outputs:
%   allEnergies    - Cell array of energy vectors per beam
%   numOfEnergies  - Number of unique energies per beam
%   numOfRays      - Total number of rays in the plan
%
% Description:
%   Extracts the unique energy levels used in each beam and counts them,
%   as well as the total number of rays in the plan.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_plotEnergyLayerHistogram, matRad_generateStf
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
numOfBeams = size(stf,2);
for i=1:numOfBeams
    % find range of ray positions within beam
    % rayPos_mat = vertcat(stf(i).ray(:).rayPos_bev);
    % x_min = min(rayPos_mat(:, 1));
    % z_min = min(rayPos_mat(:, 3));
    % x_max = max(rayPos_mat(:, 1));
    % z_max = max(rayPos_mat(:, 3));

    allEnergies{i} = unique(cat(2, stf(i).ray(:).energy));
    numOfEnergies(i) = length(allEnergies{i});
end
numOfRays  = stf.numOfRays;
end