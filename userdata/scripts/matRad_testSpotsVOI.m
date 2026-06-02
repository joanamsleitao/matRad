function [spotTblAll, voiTbl, spotTblVOI, stats] = matRad_testSpotsVOI(ct, cst, stf, ixVOI, ixBeam, sliceShown)
% matRad_testSpotsVOI - Test-only helper to inspect spots in one beam
%                       and their overlap with one VOI
%
% Syntax:
%   [spotTblAll, voiTbl, spotTblVOI, stats] = matRad_testSpotsVOI(ct, cst, stf, ixVOI, ixBeam, sliceShown)
%
% Description:
%   This function does not plot anything.
%   It:
%     1) Extracts all spots from one selected beam.
%     2) Extracts the VOI voxel list from cst{ixVOI,4}{1}.
%     3) Matches spots against the VOI by linear voxel index.
%     4) Prints simple counts for debugging.
%
% Inputs:
%   ct         - matRad CT structure
%   cst        - matRad CST cell array
%   stf        - matRad steering file structure array
%   ixVOI      - row index in cst of the VOI
%   ixBeam     - beam index to inspect
%   sliceShown - slice index to test
%
% Outputs:
%   spotTblAll - Table with all spots in the selected beam
%   voiTbl     - Table with VOI voxels
%   spotTblVOI - Table with spots that lie inside the VOI
%   stats      - Struct with summary counts
%
% Reference entry:
% | `N/A` | `matRad_testSpotsVOI` | Test spot/VOI overlap for one beam and one slice | `[spotTblAll, voiTbl, spotTblVOI, stats] = matRad_testSpotsVOI(ct, cst, stf, ixInterface, ixBeam, sliceShown)` | 🟢 |
%
% ----
% Author: Joana Leitão
% ----

if isempty(stf) || ~isstruct(stf)
    error('matRad_testSpotsVOI:InvalidSTF', ...
        'stf must be a non-empty struct array.');
end

if nargin < 5 || isempty(ixBeam) || ~isscalar(ixBeam) || ixBeam < 1 || ixBeam > numel(stf)
    error('matRad_testSpotsVOI:InvalidBeamIndex', ...
        'ixBeam must be a valid beam index between 1 and numel(stf).');
end

if nargin < 4 || isempty(ixVOI) || ~isscalar(ixVOI) || ixVOI < 1 || ixVOI > size(cst,1)
    error('matRad_testSpotsVOI:InvalidVOIRow', ...
        'ixVOI must be a valid row index in cst.');
end

if nargin < 6 || isempty(sliceShown)
    error('matRad_testSpotsVOI:MissingSlice', ...
        'sliceShown must be provided.');
end

% CT dimensions
if isfield(ct, 'cubeDim') && ~isempty(ct.cubeDim)
    ctDim = ct.cubeDim;
else
    ctDim = size(ct.cubeHU);
end
ctDim = double(ctDim(:).');

% -------------------------------------------------------------------------
% VOI voxel table
% -------------------------------------------------------------------------
if ~iscell(cst) || size(cst,2) < 4 || isempty(cst{ixVOI,4})
    error('matRad_testSpotsVOI:InvalidCSTVOI', ...
        'cst{ixVOI,4}{1} is missing or empty.');
end

linVOI = cst{ixVOI,4}{1};
linVOI = unique(linVOI(:));
linVOI = linVOI(linVOI >= 1 & linVOI <= prod(ctDim));

[rowVOI, colVOI, sliceVOI] = ind2sub(ctDim, linVOI);
voiWorld = matRad_cubeIndex2worldCoords(linVOI, ct);

voiTbl = table(linVOI, rowVOI, colVOI, sliceVOI, ...
    voiWorld(:,1), voiWorld(:,2), voiWorld(:,3), ...
    'VariableNames', {'linVox', 'rowCube', 'colCube', 'sliceCube', ...
                      'xWorld', 'yWorld', 'zWorld'});

% -------------------------------------------------------------------------
% Extract all spots from one beam
% -------------------------------------------------------------------------
stfBeam = stf(ixBeam);

spotGlobalCol = [];
iRayCol       = [];
iSpotCol      = [];
energyCol     = [];
xCubeCol      = [];
yCubeCol      = [];
zCubeCol      = [];
linVoxCol     = [];
inVOICol      = [];
inSliceCol    = [];

if ~isfield(stfBeam, 'ray') || isempty(stfBeam.ray)
    warning('matRad_testSpotsVOI:NoRays', ...
        'Beam %d contains no rays.', ixBeam);
else
    for iRay = 1:numel(stfBeam.ray)
        ray = stfBeam.ray(iRay);

        if ~isfield(ray, 'rayTracerInfo') || ...
                ~isfield(ray.rayTracerInfo, 'perSpot') || ...
                isempty(ray.rayTracerInfo.perSpot)
            continue;
        end

        spots = ray.rayTracerInfo.perSpot;

        for iSpot = 1:numel(spots)
            if ~isfield(spots(iSpot), 'spotCube') || numel(spots(iSpot).spotCube) < 3
                continue;
            end
            if ~isfield(spots(iSpot), 'energy') || isempty(spots(iSpot).energy)
                continue;
            end

            spotCube = spots(iSpot).spotCube(:).';
            spotEnergy = spots(iSpot).energy;

            % Assume plotting convention: spotCube = [x, y, z]
            xC = round(spotCube(1));
            yC = round(spotCube(2));
            zC = round(spotCube(3));

            % Bounds check
            if xC < 1 || yC < 1 || zC < 1 || ...
               xC > ctDim(2) || yC > ctDim(1) || zC > ctDim(3)
                continue;
            end

            % Linear voxel index in MATLAB convention [row, col, slice] = [y, x, z]
            linVox = sub2ind(ctDim, yC, xC, zC);

            spotGlobalCol(end+1,1) = numel(spotGlobalCol) + 1; %#ok<AGROW>
            iRayCol(end+1,1)       = iRay; %#ok<AGROW>
            iSpotCol(end+1,1)      = iSpot; %#ok<AGROW>
            energyCol(end+1,1)     = spotEnergy; %#ok<AGROW>
            xCubeCol(end+1,1)      = xC; %#ok<AGROW>
            yCubeCol(end+1,1)      = yC; %#ok<AGROW>
            zCubeCol(end+1,1)      = zC; %#ok<AGROW>
            linVoxCol(end+1,1)     = linVox; %#ok<AGROW>
            inVOICol(end+1,1)      = ismember(linVox, voiTbl.linVox); %#ok<AGROW>
            inSliceCol(end+1,1)    = (zC == sliceShown); %#ok<AGROW>
        end
    end
end

spotTblAll = table(spotGlobalCol, iRayCol, iSpotCol, energyCol, ...
    xCubeCol, yCubeCol, zCubeCol, linVoxCol, inVOICol, inSliceCol, ...
    'VariableNames', {'globalSpot', 'iRay', 'iSpot', 'energy', ...
                      'xCube', 'yCube', 'zCube', ...
                      'linVox', 'inVOI', 'inSlice'});

spotTblVOI = spotTblAll(spotTblAll.inVOI, :);

% -------------------------------------------------------------------------
% Summary stats
% -------------------------------------------------------------------------
stats = struct();
stats.iBeam = ixBeam;
stats.ixVOI = ixVOI;
stats.sliceShown = sliceShown;
stats.nRays = numel(stfBeam.ray);
stats.nSpotsAll = height(spotTblAll);
stats.nSpotsInVOI = height(spotTblVOI);
stats.nSpotsInSlice = sum(spotTblAll.inSlice);
stats.nSpotsInVOIAndSlice = sum(spotTblAll.inVOI & spotTblAll.inSlice);
stats.nUniqueEnergyAll = numel(unique(spotTblAll.energy));
stats.nUniqueEnergyVOI = numel(unique(spotTblVOI.energy));

% -------------------------------------------------------------------------
% Print debug info
% -------------------------------------------------------------------------
fprintf('\n===== matRad_testSpotsVOI =====\n');
fprintf('Beam index: %d\n', ixBeam);
fprintf('VOI row in cst: %d\n', ixVOI);
fprintf('Displayed slice: %d\n', sliceShown);
fprintf('Number of rays in beam: %d\n', stats.nRays);
fprintf('Number of spots in beam: %d\n', stats.nSpotsAll);
fprintf('Number of spots inside VOI: %d\n', stats.nSpotsInVOI);
fprintf('Number of spots in displayed slice: %d\n', stats.nSpotsInSlice);
fprintf('Number of spots inside VOI AND slice: %d\n', stats.nSpotsInVOIAndSlice);
fprintf('Number of unique energies in beam: %d\n', stats.nUniqueEnergyAll);
fprintf('Number of unique energies inside VOI: %d\n', stats.nUniqueEnergyVOI);

if ~isempty(spotTblVOI)
    disp('First VOI spots:');
    disp(spotTblVOI(1:min(10,height(spotTblVOI)), :));
else
    disp('No spots matched the VOI.');
end

end