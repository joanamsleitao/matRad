function [stf, mb_stf, sb_stf] = matRad_genStfELB(ct, cst, pln)
% MATRADJOANA_GENERATESTFONEEL - Generates STF with single energy layer per ray
%
% Syntax:  [stf, mb_stf, sb_stf] = matRadJoana_generateStfOneEL(ct, cst, pln)
%
% Inputs:
%   ct      - CT structure (struct)
%   cst     - CST cell array (cell array)
%   pln     - Plan structure (struct)
%
% Outputs:
%   stf     - STF with single energy layer per ray (struct)
%   mb_stf  - Multi-energy STF (struct)
%   sb_stf  - Single bixel STF (struct)
%
% Other m-files required: matRad_generateStf.m, matRad_generateSingleBixelStf.m
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_generateStf, matRad_generateSingleBixelStf
%
list = []; % empty
for j = 1:stf.numOfRays
    % if j==111
    if (stf.ray(j).rayPos_bev(2)~=0 || stf.ray(j).rayPos_bev(3)~=0)
% tmp.ray(j) = [];
  list = [list; j]; % save all rows that have (x, 0, 0) coordinates
    end
    % end
end

f = flip(list); % flip to start removing from the bottom
stf.ray(f) = []; % delete all rows that have (x, 0, 0) coordinates

% remove fields because they interfeer with code
stf.ray = rmfield(stf.ray, 'numParticlesPerMU');
stf.ray = rmfield(stf.ray, 'minMU');
stf.ray = rmfield(stf.ray, 'maxMU');

% make energy, rangeShifter and focusIx the same as in sb_stf
for i = 1:size(stf.ray,2)
    stf.ray(i).energy = sb_stf.ray(1).energy;
    stf.ray(i).rangeShifter = sb_stf.ray(1).rangeShifter;
    stf.ray(i).focusIx = sb_stf.ray(1).focusIx;
end

% change remainning parameters
stf.numOfRays  = size(stf.ray,2);
stf.numOfBixelsPerRay = ones(stf.numOfRays,1)';
stf.totalNumOfBixels = sum(stf.numOfBixelsPerRay(:));

%figure, matRad_plotSliceWrapper(gca,ct_comb,cst_comb,1,resultGUI.physicalDose - resultGUI_comb.physicalDose ,3,slice);
% slice = matRad_world2cubeIndex(pln.propStf.isoCenter(1,:),ct);
% slice = slice(3);

end