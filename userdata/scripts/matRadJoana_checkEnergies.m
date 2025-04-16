function [allEnergies, numOfEnergies, numOfRays] = matRadJoana_checkEnergies(stf)
% Taken from matRad_visSpotWeights, adapted on 14/04/2025
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% call
%    matRadJoana_checkEnergies(stf)
%
% input
%   stf:              matRad stf struct

% output
%
% References
%   -
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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