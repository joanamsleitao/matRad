function [healthyMask, cstNew, healthyAboveThrMask] = matRad_VOIHealthy( ...
    cst, doseCube, doseThreshold, includeTargets)
% matRad_VOIHealthy - Create VOIs for irradiated healthy tissue
%
% Syntax:
%   [cstNew, healthyMask, healthyAboveThrMask] = ...
%       matRad_VOIHealthy(cst, doseCube, doseThreshold, includeTargets)
%
% Description:
%   Finds all voxels receiving dose > 0 and optionally excludes those
%   belonging to TARGET/PTV/GTV VOIs.
%   Creates:
%     1) 'HealthyTissue' - voxels with dose > 0
%     2) 'HealthyTissueAboveThr' - same, but dose > threshold
%
% Inputs:
%   cst            - matRad CST structure
%   doseCube       - 3D dose matrix
%   doseThreshold  - dose threshold (Gy)
%   includeTargets - logical (default=false); if false, exclude targets
%
% Outputs:
%   cstNew              - updated CST
%   healthyMask         - voxels receiving dose (optionally excluding targets)
%   healthyAboveThrMask - voxels > threshold (optionally excluding targets)
%
% Author: Joana Leitão + GPT-5, 2025
% -------------------------------------------------------------------------

if nargin < 3 || isempty(doseThreshold)
    doseThreshold = 10;
end
if nargin < 4 || isempty(includeTargets)
    includeTargets = false;
end

doseMask = doseCube > 0;

% --- Identify target voxels
targetMask = false(size(doseCube));
for i = 1:size(cst,1)
    voiType = lower(cst{i,3});
    if contains(voiType, 'target') || contains(voiType, 'ptv') || contains(voiType, 'gtv')
        indices = cst{i,4}{1};
        targetMask(indices) = true;
    end
end

if includeTargets
    healthyMask = doseMask;
else
    healthyMask = doseMask & ~targetMask;
end

healthyAboveThrMask = healthyMask & (doseCube > doseThreshold);

% --- Create CST entries ---
healthyIdx = find(healthyMask);
healthyAboveThrIdx = find(healthyAboveThrMask);

baseEntry = cst(end,:);
newEntry1 = baseEntry;
newEntry2 = baseEntry;

suffix = '';
if includeTargets
    suffix = '_IncTargets';
end

newEntry1{2} = ['HealthyTissue' suffix];
newEntry1{3} = 'OAR';
newEntry1{4} = {healthyIdx};

newEntry2{2} = sprintf('HealthyTissueAboveThr_%.1fGy%s', doseThreshold, suffix);
newEntry2{3} = 'OAR';
newEntry2{4} = {healthyAboveThrIdx};

cstNew = [cst; newEntry1; newEntry2];

fprintf('Added new CST VOIs: "%s" (%d voxels) and "%s" (%d voxels)\n', ...
    newEntry1{2}, numel(healthyIdx), newEntry2{2}, numel(healthyAboveThrIdx));
end