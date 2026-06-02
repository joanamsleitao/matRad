function [spotPos, spotEnergy] = matRad_extractRayPoints(ray)
% matRad_extractRayPoints - Extract spot positions and energies from one ray
%
% Syntax:
%   [spotPos, spotEnergy] = matRad_extractRayPoints(ray)
%
% Description:
%   Extracts per-spot cube coordinates and energies from a single ray.
%   The preferred source is ray.rayTracerInfo.perSpot(iSpot).spotCube,
%   matching the convention used in matRad_plotSpotsSlice and
%   matRad_plotBeamArea.
%
%   Fallbacks are included for alternate field layouts when available.
%
% Inputs:
%   ray         - One ray struct from the matRad steering file
%
% Outputs:
%   spotPos     - Nx3 array of spot positions in cube coordinates [x y z]
%   spotEnergy  - Nx1 vector of energies corresponding to each spot
%
% Reference entry:
% | `matRad_extractRayPts` | `matRad_extractRayPoints` | Extract spot cube positions and energies from one ray | `[spotPos, spotEnergy] = matRad_extractRayPoints(ray)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

spotPos    = [];
spotEnergy = [];

if nargin < 1 || isempty(ray) || ~isstruct(ray)
    warning('matRad_extractRayPoints:InvalidInput', ...
        'Input ray is missing or invalid.');
    return;
end

% -------------------------------------------------------------------------
% Preferred source: rayTracerInfo.perSpot(iSpot).spotCube
% -------------------------------------------------------------------------
if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot') ...
        && ~isempty(ray.rayTracerInfo.perSpot)

    perSpot = ray.rayTracerInfo.perSpot;
    nSpots  = numel(perSpot);

    spotPos = nan(nSpots, 3);

    for iSpot = 1:nSpots
        p = [];

        if isfield(perSpot(iSpot), 'spotCube') && ~isempty(perSpot(iSpot).spotCube)
            p = perSpot(iSpot).spotCube(:).';
        elseif isfield(perSpot(iSpot), 'rayPos') && ~isempty(perSpot(iSpot).rayPos)
            p = perSpot(iSpot).rayPos(:).';
        elseif isfield(perSpot(iSpot), 'rayPosCube') && ~isempty(perSpot(iSpot).rayPosCube)
            p = perSpot(iSpot).rayPosCube(:).';
        elseif isfield(perSpot(iSpot), 'targetPoint') && ~isempty(perSpot(iSpot).targetPoint)
            p = perSpot(iSpot).targetPoint(:).';
        elseif isfield(perSpot(iSpot), 'targetPointCube') && ~isempty(perSpot(iSpot).targetPointCube)
            p = perSpot(iSpot).targetPointCube(:).';
        end

        if ~isempty(p)
            nCopy = min(3, numel(p));
            spotPos(iSpot, 1:nCopy) = p(1:nCopy);
        end
    end

    % Energy vector
    if isfield(ray, 'energy') && ~isempty(ray.energy)
        spotEnergy = ray.energy(:);
    elseif isfield(ray.rayTracerInfo, 'energy') && ~isempty(ray.rayTracerInfo.energy)
        spotEnergy = ray.rayTracerInfo.energy(:);
    else
        spotEnergy = ones(nSpots, 1);
    end

    % Clean invalid rows
    validRows = all(isfinite(spotPos(:,1:2)), 2);
    spotPos   = spotPos(validRows, :);

    if numel(spotEnergy) == nSpots
        spotEnergy = spotEnergy(validRows);
    else
        spotEnergy = spotEnergy(:);
        if isempty(spotEnergy)
            spotEnergy = ones(size(spotPos,1), 1);
        elseif numel(spotEnergy) < size(spotPos,1)
            spotEnergy(end+1:size(spotPos,1), 1) = spotEnergy(end);
        else
            spotEnergy = spotEnergy(1:size(spotPos,1));
        end
    end

    return;
end

% -------------------------------------------------------------------------
% Fallback 1: ray.rayPos
% -------------------------------------------------------------------------
if isfield(ray, 'rayPos') && isnumeric(ray.rayPos) && ~isempty(ray.rayPos)
    spotPos = ray.rayPos;
end

% -------------------------------------------------------------------------
% Fallback 2: ray.targetPoint
% -------------------------------------------------------------------------
if isempty(spotPos) && isfield(ray, 'targetPoint') && isnumeric(ray.targetPoint) ...
        && ~isempty(ray.targetPoint)
    spotPos = ray.targetPoint;
end

% -------------------------------------------------------------------------
% Fallback 3: BEV coordinates
% -------------------------------------------------------------------------
if isempty(spotPos) && isfield(ray, 'rayPos_bev') && isnumeric(ray.rayPos_bev) ...
        && ~isempty(ray.rayPos_bev)
    spotPos = ray.rayPos_bev;
end

if isempty(spotPos) && isfield(ray, 'targetPoint_bev') && isnumeric(ray.targetPoint_bev) ...
        && ~isempty(ray.targetPoint_bev)
    spotPos = ray.targetPoint_bev;
end

% Normalize to Nx3
if isvector(spotPos) && numel(spotPos) > 1
    spotPos = spotPos(:).';
end

if ~isempty(spotPos)
    if size(spotPos, 1) == 3 && size(spotPos, 2) ~= 3
        spotPos = spotPos.';
    end

    if size(spotPos, 2) == 2
        spotPos(:,3) = NaN;
    elseif size(spotPos, 2) > 3
        spotPos = spotPos(:,1:3);
    end

    validRows = all(isfinite(spotPos(:,1:2)), 2);
    spotPos   = spotPos(validRows, :);
else
    spotPos = nan(0, 3);
end

% Energy fallback
if isfield(ray, 'energy') && ~isempty(ray.energy)
    spotEnergy = ray.energy(:);
elseif isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'energy') ...
        && ~isempty(ray.rayTracerInfo.energy)
    spotEnergy = ray.rayTracerInfo.energy(:);
else
    spotEnergy = ones(size(spotPos,1), 1);
end

% Match energy length to position length
if numel(spotEnergy) ~= size(spotPos,1)
    if isempty(spotEnergy)
        spotEnergy = ones(size(spotPos,1), 1);
    else
        nMin = min(numel(spotEnergy), size(spotPos,1));
        spotEnergy = spotEnergy(1:nMin);
        spotPos    = spotPos(1:nMin, :);
    end
end

end