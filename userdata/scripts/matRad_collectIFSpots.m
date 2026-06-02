function ifData = matRad_collectIFSpots(ct, cst, stf, ixInterface)
% matRad_collectIFSpots - Collect all spots inside an interface VOI,
%                          separated by beam and energy layer
%
% Syntax:
%   ifData = matRad_collectIFSpots(ct, cst, stf, ixInterface)
%
% Description:
%   Collects all spots from all beams that lie inside the VOI specified by
%   cst{ixInterface,4}{1}. The output keeps:
%     - a flat master table of all interface spots,
%     - per-beam interface spot tables,
%     - per-beam energy-layer grouping of interface spots,
%     - VOI voxel information in cube and world coordinates.
%
%   IMPORTANT:
%   - cst{ixInterface,4}{1} must contain the VOI voxels as linear indices.
%   - spots are assumed to be stored in stf(*).ray(*).rayTracerInfo.perSpot(*).spotCube
%   - spotCube is assumed to already be in cube coordinates.
%
% Inputs:
%   ct          - matRad CT struct
%   cst         - matRad CST cell array
%   stf         - matRad steering file struct array
%   ixInterface - row index in cst of the interface VOI
%
% Outputs:
%   ifData - struct with fields:
%       .ixInterface
%       .voiTbl
%       .voiCube
%       .masterSpotTbl
%       .beam(ixBeam).ixBeam
%       .beam(ixBeam).spotTblAll
%       .beam(ixBeam).spotTblInterface
%       .beam(ixBeam).el(iEL).energyMeV
%       .beam(ixBeam).el(iEL).spotTbl
%       .beam(ixBeam).el(iEL).nSpots
%
% Reference entry:
% | `N/A` | `matRad_collectIFSpots` | Collect interface spots grouped by beam and energy layer | `ifData = matRad_collectIFSpots(ct, cst, stf, ixInterface)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if nargin < 4 || isempty(ixInterface)
    error('matRad_collectIFSpots:MissingInterfaceIndex', ...
        'ixInterface must be provided.');
end

if isempty(stf) || ~isstruct(stf)
    error('matRad_collectIFSpots:InvalidSTF', ...
        'stf must be a non-empty struct array.');
end

if ~iscell(cst) || size(cst,2) < 4 || ixInterface < 1 || ixInterface > size(cst,1)
    error('matRad_collectIFSpots:InvalidCST', ...
        'ixInterface must be a valid row index in cst.');
end

% -------------------------------------------------------------------------
% CT dimensions
% -------------------------------------------------------------------------
if isfield(ct, 'cubeDim') && ~isempty(ct.cubeDim)
    ctDim = double(ct.cubeDim(:).');
else
    ctDim = double(size(ct.cubeHU));
end

% -------------------------------------------------------------------------
% Interface VOI voxels -> cube coordinates
% -------------------------------------------------------------------------
if isempty(cst{ixInterface,4})
    error('matRad_collectIFSpots:EmptyInterfaceVOI', ...
        'cst{ixInterface,4} is empty.');
end

linVOI = cst{ixInterface,4}{1};
linVOI = unique(linVOI(:));
linVOI = linVOI(linVOI >= 1 & linVOI <= prod(ctDim));

if isempty(linVOI)
    error('matRad_collectIFSpots:NoInterfaceVoxels', ...
        'The interface VOI contains no valid voxels.');
end

[voiI, voiJ, voiK] = matRad_lin2cubeCoords(ct.cubeDim, linVOI);
voiWorld = matRad_cubeIndex2worldCoords(linVOI, ct);

voiTbl = table(linVOI, voiI, voiJ, voiK, ...
    voiWorld(:,1), voiWorld(:,2), voiWorld(:,3), ...
    'VariableNames', {'linVox', 'iCube', 'jCube', 'kCube', ...
                      'xWorld', 'yWorld', 'zWorld'});

voiCube = [voiI(:), voiJ(:), voiK(:)];

% -------------------------------------------------------------------------
% Initialize output
% -------------------------------------------------------------------------
ifData = struct();
ifData.ixInterface = ixInterface;
ifData.voiTbl = voiTbl;
ifData.voiCube = voiCube;
ifData.beam = repmat(struct( ...
    'ixBeam', [], ...
    'spotTblAll', [], ...
    'spotTblInterface', [], ...
    'el', []), numel(stf), 1);

% Master table arrays: interface spots only
mGlobalBeamCol = [];
mGlobalRayCol  = [];
mGlobalSpotCol = [];
mEnergyCol     = [];
mBeamCol       = [];
mRayCol        = [];
mSpotCol       = [];
mICubeCol      = [];
mJCubeCol      = [];
mKCubeCol      = [];
mLinVoxCol     = [];
mXWorldCol     = [];
mYWorldCol     = [];
mZWorldCol     = [];
mInVOICol      = [];

% -------------------------------------------------------------------------
% Loop over beams
% -------------------------------------------------------------------------
for ixBeam = 1:numel(stf)
    stfBeam = stf(ixBeam);

    % Per-beam arrays for all spots in the beam
    globalBeamCol = [];
    globalRayCol  = [];
    globalSpotCol = [];
    energyCol     = [];
    iBeamCol      = [];
    iRayCol       = [];
    iSpotCol      = [];
    iCubeCol      = [];
    jCubeCol      = [];
    kCubeCol      = [];
    linVoxCol     = [];
    xWorldCol     = [];
    yWorldCol     = [];
    zWorldCol     = [];
    inVOICol      = [];

    if ~isfield(stfBeam, 'ray') || isempty(stfBeam.ray)
        ifData.beam(ixBeam).ixBeam = ixBeam;
        ifData.beam(ixBeam).spotTblAll = matRad_makeEmptySpotTable();
        ifData.beam(ixBeam).spotTblInterface = matRad_makeEmptySpotTable();
        ifData.beam(ixBeam).el = struct('energyMeV', {}, 'spotTbl', {}, 'nSpots', {});
        continue;
    end

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

            spotCube = round(spots(iSpot).spotCube(:).');
            spotEnergy = spots(iSpot).energy;

            % spotCube is assumed to already be in cube coordinates [i j k]
            iC = spotCube(1);
            jC = spotCube(2);
            kC = spotCube(3);

            % Bounds check
            if iC < 1 || jC < 1 || kC < 1 || ...
               iC > ctDim(1) || jC > ctDim(2) || kC > ctDim(3)
                continue;
            end

            linVox = sub2ind(ctDim, iC, jC, kC);
            isInVOI = ismember([jC iC kC], voiCube, 'rows'); %#ok<AGROW>

            % Store all spots in this beam
            globalBeamCol(end+1,1) = ixBeam; %#ok<AGROW>
            globalRayCol(end+1,1)  = iRay;   %#ok<AGROW>
            globalSpotCol(end+1,1) = iSpot;   %#ok<AGROW>
            energyCol(end+1,1)     = spotEnergy; %#ok<AGROW>

            iBeamCol(end+1,1)      = ixBeam; %#ok<AGROW>
            iRayCol(end+1,1)       = iRay;   %#ok<AGROW>
            iSpotCol(end+1,1)      = iSpot;  %#ok<AGROW>

            iCubeCol(end+1,1)      = iC; %#ok<AGROW>
            jCubeCol(end+1,1)      = jC; %#ok<AGROW>
            kCubeCol(end+1,1)      = kC; %#ok<AGROW>

            linVoxCol(end+1,1)     = linVox; %#ok<AGROW>
            inVOICol(end+1,1)      = isInVOI; %#ok<AGROW>

            worldCoord = matRad_cubeIndex2worldCoords(linVox, ct);
            xWorldCol(end+1,1)     = worldCoord(1); %#ok<AGROW>
            yWorldCol(end+1,1)     = worldCoord(2); %#ok<AGROW>
            zWorldCol(end+1,1)     = worldCoord(3); %#ok<AGROW>

            % Keep interface spots also in the master table arrays
            if isInVOI
                mGlobalBeamCol(end+1,1) = ixBeam; %#ok<AGROW>
                mGlobalRayCol(end+1,1)  = iRay;   %#ok<AGROW>
                mGlobalSpotCol(end+1,1) = iSpot;  %#ok<AGROW>
                mEnergyCol(end+1,1)     = spotEnergy; %#ok<AGROW>

                mBeamCol(end+1,1)       = ixBeam; %#ok<AGROW>
                mRayCol(end+1,1)        = iRay;   %#ok<AGROW>
                mSpotCol(end+1,1)       = iSpot;  %#ok<AGROW>

                mICubeCol(end+1,1)      = iC; %#ok<AGROW>
                mJCubeCol(end+1,1)      = jC; %#ok<AGROW>
                mKCubeCol(end+1,1)      = kC; %#ok<AGROW>

                mLinVoxCol(end+1,1)     = linVox; %#ok<AGROW>
                mInVOICol(end+1,1)      = true; %#ok<AGROW>

                mWorldCoord = worldCoord;
                mXWorldCol(end+1,1)     = mWorldCoord(1); %#ok<AGROW>
                mYWorldCol(end+1,1)     = mWorldCoord(2); %#ok<AGROW>
                mZWorldCol(end+1,1)     = mWorldCoord(3); %#ok<AGROW>
            end
        end
    end

    % Build per-beam table
    spotTblAll = matRad_makeSpotTable( ...
        globalBeamCol, globalRayCol, globalSpotCol, energyCol, ...
        iBeamCol, iRayCol, iSpotCol, ...
        iCubeCol, jCubeCol, kCubeCol, ...
        linVoxCol, xWorldCol, yWorldCol, zWorldCol, inVOICol);

    spotTblInterface = spotTblAll(spotTblAll.inVOI == 1, :);

    % Energy-layer grouping on interface spots only
    if isempty(spotTblInterface)
        elStruct = struct('energyMeV', {}, 'spotTbl', {}, 'nSpots', {});
    else
        uniqueE = unique(spotTblInterface.energy, 'sorted');
        elStruct = repmat(struct('energyMeV', [], 'spotTbl', [], 'nSpots', []), numel(uniqueE), 1);

        for iE = 1:numel(uniqueE)
            idxE = (spotTblInterface.energy == uniqueE(iE));
            elStruct(iE).energyMeV = uniqueE(iE);
            elStruct(iE).spotTbl = spotTblInterface(idxE, :);
            elStruct(iE).nSpots = height(elStruct(iE).spotTbl);
        end
    end

    ifData.beam(ixBeam).ixBeam = ixBeam;
    ifData.beam(ixBeam).spotTblAll = spotTblAll;
    ifData.beam(ixBeam).spotTblInterface = spotTblInterface;
    ifData.beam(ixBeam).el = elStruct;
end

% -------------------------------------------------------------------------
% Build master interface spot table
% -------------------------------------------------------------------------
ifData.masterSpotTbl = matRad_makeSpotTable( ...
    mGlobalBeamCol, mGlobalRayCol, mGlobalSpotCol, mEnergyCol, ...
    mBeamCol, mRayCol, mSpotCol, ...
    mICubeCol, mJCubeCol, mKCubeCol, ...
    mLinVoxCol, mXWorldCol, mYWorldCol, mZWorldCol, mInVOICol);

end

% ========================================================================
% Local helper: empty table with the correct variable count
% ========================================================================
function T = matRad_makeEmptySpotTable()
z = zeros(0,1);
f = false(0,1);

T = table( ...
    z, z, z, z, ...
    z, z, z, ...
    z, z, z, ...
    z, z, z, z, ...
    f, ...
    'VariableNames', {'globalBeam', 'globalRay', 'globalSpot', 'energy', ...
                      'iBeam', 'iRay', 'iSpot', ...
                      'iCube', 'jCube', 'kCube', ...
                      'linVox', 'xWorld', 'yWorld', 'zWorld', 'inVOI'});
end

% ========================================================================
% Local helper: create spot table from arrays
% ========================================================================
function T = matRad_makeSpotTable( ...
    globalBeamCol, globalRayCol, globalSpotCol, energyCol, ...
    iBeamCol, iRayCol, iSpotCol, ...
    iCubeCol, jCubeCol, kCubeCol, ...
    linVoxCol, xWorldCol, yWorldCol, zWorldCol, inVOICol)

if isempty(globalBeamCol)
    T = matRad_makeEmptySpotTable();
    return;
end

T = table( ...
    globalBeamCol(:), globalRayCol(:), globalSpotCol(:), energyCol(:), ...
    iBeamCol(:), iRayCol(:), iSpotCol(:), ...
    iCubeCol(:), jCubeCol(:), kCubeCol(:), ...
    linVoxCol(:), xWorldCol(:), yWorldCol(:), zWorldCol(:), inVOICol(:), ...
    'VariableNames', {'globalBeam', 'globalRay', 'globalSpot', 'energy', ...
                      'iBeam', 'iRay', 'iSpot', ...
                      'iCube', 'jCube', 'kCube', ...
                      'linVox', 'xWorld', 'yWorld', 'zWorld', 'inVOI'});
end