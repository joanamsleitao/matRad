function [stf_oneEL, stf_mb, stf_sb] = matRad_genStf1EL(ct, cst, pln)
% matRadJoana_generateStfOneEL - Create STF with one energy layer per ray
%
% Syntax:
%   [stf_oneEL, stf_mb, stf_sb] = matRadJoana_generateStfOneEL(ct, cst, pln)
%
% Inputs:
%   ct    - matRad CT structure
%   cst   - matRad CST structure
%   pln   - matRad plan structure
%
% Outputs:
%   stf_oneEL - STF where all rays lie in (x, 0, 0) and share the same energy layer
%   stf_mb    - Full multi-energy STF
%   stf_sb    - Single-bixel STF used as energy source
%
% Description:
%   This function simplifies the beam geometry by filtering out rays not aligned
%   along the (x, 0, 0) direction and assigning a uniform energy, range shifter,
%   and focus index to all remaining rays. Fields interfering with optimization
%   are removed.
%
% Other m-files required: matRad_generateStf, matRad_generateSingleBixelStf
% Subfunctions: none
% MAT-files required: none
%
% See also: matRadJoana_generatePln, matRad_plotSingleRay
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% create multi energy stf
stf_mb = matRad_generateStf(ct,cst,pln);
stf = stf_mb;
%%
% stf = mb_stf;
% stf_no_mod = mb_stf_no_mod;
%%
% create single bixel stf
stf_sb = matRad_generateSingleBixelStf(ct,cst,pln);

pln.propStf.energy = stf_sb.ray.energy;

stf_oneEL = matRad_generateSingleBixelStf(ct,cst,pln);

% sb_stf_no_mod = matRad_generateSingleBixelStf(ct_no_mod,cst_no_mod,pln);
%%
% adapt stf to have one energy layer/bixel per ray
% run through all rays, keep only ray in the (x, 0, 0) line
% to make a one front beam
% can be altered to have another line
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

% % remove fields because they interfeer with code
stf.ray = rmfield(stf.ray, 'numParticlesPerMU');
stf.ray = rmfield(stf.ray, 'minMU');
stf.ray = rmfield(stf.ray, 'maxMU');

% make energy, rangeShifter and focusIx the same as in sb_stf
for i = 1:size(stf.ray,2)
    stf.ray(i).energy = stf_oneEL.ray(1).energy;
    stf.ray(i).rangeShifter = stf_oneEL.ray(1).rangeShifter;
    stf.ray(i).focusIx = stf_oneEL.ray(1).focusIx;
end

% change remainning parameters
stf.numOfRays  = size(stf.ray,2);
stf.numOfBixelsPerRay = ones(stf.numOfRays,1)';
stf.totalNumOfBixels = sum(stf.numOfBixelsPerRay(:));

%figure, matRad_plotSliceWrapper(gca,ct_comb,cst_comb,1,resultGUI.physicalDose - resultGUI_comb.physicalDose ,3,slice);
% slice = matRad_world2cubeIndex(pln.propStf.isoCenter(1,:),ct);
% slice = slice(3);

%%
stf_oneEL = stf;

end