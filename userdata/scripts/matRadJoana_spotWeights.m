function [all_energies, numOfEnergies, weight_matrix] = matRadJoana_spotWeights(stf,weights)
% Taken from matRad_visSpotWeights, adapted on 14/04/2025
%
%
% visualise spot weights per energy slice (or fluence map for photons resp.)
% for single beams
% 
% call
%    matRadJoana_spotWeights(stf,weights)
%
% input
%   stf:              matRad stf struct
%   weights:          spot weights for bixels (resultGUI.w)

% output 
%      plots for all beams - for particles: scroll mousewheel to access different energies  
%
% References
%   -
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSE.md. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numOfBeams = size(stf,2);

for i=1:numOfBeams
    % find range of ray positions within beam
    rayPos_mat = vertcat(stf(i).ray(:).rayPos_bev);
    x_min = min(rayPos_mat(:, 1));
    z_min = min(rayPos_mat(:, 3));
    x_max = max(rayPos_mat(:, 1));
    z_max = max(rayPos_mat(:, 3));

    all_energies{i} = unique(cat(2, stf(i).ray(:).energy));
    numOfEnergies(i) = length(all_energies{i});

    % initialise weight matrix
    weight_matrix{i} = zeros((x_max-x_min)/stf(i).bixelWidth,(z_max-z_min)/stf(i).bixelWidth, numOfEnergies(i));
end
end