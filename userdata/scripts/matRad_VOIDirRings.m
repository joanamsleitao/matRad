function [cst, ringInfo, ixAdded] = matRad_VOIDirRings(ct, cst, ring_mm, ixRefVOI, directions, marginPTVRing_mm, mode, visualize)
% matRad_VOIDirRings - Create directional slab/corner VOIs from a reference structure
%
% Syntax:
%   [cst, ringInfo, ixAdded] = matRad_VOIDirRings(ct, cst, ring_mm, ixRefVOI, direction)
%   [cst, ringInfo, ixAdded] = matRad_VOIDirRings(ct, cst, ring_mm, ixRefVOI, directions, marginPTVRing_mm, mode, visualize)
%
% Description:
%   Creates directional "ring" VOIs (slabs) by expanding a reference VOI in
%   specified in-plane direction(s). Supports:
%     - Single direction: 'left', 'right', 'up', 'down' (or 'L','R','U','D')
%     - Multiple directions: {'right','down'} with 'union' or 'intersection'
%
%   For single direction: creates one VOI per ring_mm distance.
%   For multiple directions: creates one combined VOI using union or intersection.
%
% Inputs:
%   ct                - CT structure (struct)
%   cst               - CST cell array
%   ring_mm           - Ring margin(s) [mm], positive values (double array)
%   ixRefVOI          - Reference VOI index (integer). If empty, first 'PTV'
%                       VOI is used (case-insensitive).
%   directions        - Direction(s) of expansion:
%                         - Single: 'left','right','up','down' or 'L','R','U','D'
%                         - Multiple: cell array {'right','down'}, etc.
%   marginPTVRing_mm  - (optional) inner margin from VOI [mm] (double, >= 0)
%   mode              - (optional) 'union' (default) or 'intersection'
%                       Only used when directions is a cell array with >1 entry
%   visualize         - (optional) logical flag for visualization
%
% Outputs:
%   cst      - Updated CST with new directional VOIs appended
%   ringInfo - Struct array with metadata for each generated VOI:
%                .name
%                .margin_mm
%                .direction (or .directions + .mode for multi-dir)
%                .voxelsAdded
%                .mask
%                .linearIndices
%   ixAdded  - Row indices of the added VOIs in CST (row vector)
%
% Examples:
%   % Single direction, one ring
%   [cst2, info] = matRad_VOIDirRings(ct, cst, 10, [], 'right');
%
%   % Single direction, multiple rings
%   [cst2, info] = matRad_VOIDirRings(ct, cst, [5 10 15], [], 'down', 2);
%
%   % Multiple directions, union (L-shaped)
%   [cst2, info] = matRad_VOIDirRings(ct, cst, 10, [], {'right','down'}, 0, 'union');
%
%   % Multiple directions, intersection (corner wedge)
%   [cst2, info] = matRad_VOIDirRings(ct, cst, 10, [], {'right','down'}, 0, 'intersection');
%
% Notes:
%   - Only positive ring_mm are supported (directional expansion).
%   - marginPTVRing_mm is applied along the same direction(s) as ring_mm.
%
% See also:
%   matRad_VOICreateRings, matRad_addMargin
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_VOICreateRingsDir` | `matRad_VOIDirRings` | Create directional expansion VOIs (slabs/corners) from reference VOI | `[cst, ringInfo, ixAdded] = matRad_VOIDirRings(ct, cst, ring_mm, ixRefVOI, directions, marginPTVRing_mm, mode, visualize)` | 🟡 |
% -------------------------------------------------------------------------

%% --- Input handling and defaults ---------------------------------------
if nargin < 4 || isempty(ixRefVOI)
    ixRefVOI = find(strcmpi(cst(:,3), 'PTV'), 1);
    if isempty(ixRefVOI)
        error('matRad_VOIDirRings:NoPTV', ...
              'No PTV VOI found as default. Please specify ixRefVOI.');
    end
end

if nargin < 5 || isempty(directions)
    error('matRad_VOIDirRings:NoDirection', ...
          'Direction(s) must be specified: left/right/up/down or cell array.');
end

if nargin < 6 || isempty(marginPTVRing_mm)
    marginPTVRing_mm = 0;
end

if marginPTVRing_mm < 0
    error('matRad_VOIDirRings:NegativeMargin', ...
          'marginPTVRing_mm must be >= 0.');
end

if nargin < 7 || isempty(mode)
    mode = 'union';
end

if nargin < 8 || isempty(visualize)
    visualize = false;
end

ring_mm = ring_mm(:)'; % row vector
if any(ring_mm <= 0)
    error('matRad_VOIDirRings:NonPositiveRings', ...
          'Only positive ring_mm values are supported for directional rings.');
end

% Sort by absolute magnitude
[~, order] = sort(abs(ring_mm));
ring_mm = ring_mm(order);

if marginPTVRing_mm >= min(ring_mm)
    warning('matRad_VOIDirRings:LargeMargin', ...
        'Margin from VOI (%.1f mm) close to or larger than smallest ring (%.1f mm).', ...
        marginPTVRing_mm, min(ring_mm));
end

mode = lower(mode);
if ~ismember(mode, {'union','intersection'})
    error('matRad_VOIDirRings:UnknownMode', ...
        'mode must be ''union'' or ''intersection''.');
end

%% --- Determine single vs multi-direction mode ---------------------------
if ischar(directions) || isstring(directions)
    % Single direction mode
    isSingleDir = true;
    directions = {char(directions)};
elseif iscell(directions)
    isSingleDir = (numel(directions) == 1);
else
    error('matRad_VOIDirRings:InvalidDirections', ...
        'directions must be a string or cell array of strings.');
end

%% --- Base VOI mask ------------------------------------------------------
ixAdded = [];

baseIndices = cst{ixRefVOI,4}{1};
voiName     = cst{ixRefVOI,2};

voiMask = false(ct.cubeDim);
voiMask(baseIndices) = true;

ringInfo = struct('name', {}, 'margin_mm', {}, 'direction', {}, ...
                  'directions', {}, 'mode', {}, ...
                  'voxelsAdded', {}, 'mask', {}, 'linearIndices', {});

voxelSize = [ct.resolution.x, ct.resolution.y, ct.resolution.z];

%% --- CASE 1: Single direction, multiple rings ---------------------------
if isSingleDir
    [axisIdx, dirSign, dirLabel] = local_parseDirection(directions{1});
    voxelSizeAxis = voxelSize(axisIdx);
    
    fprintf('--- Directional Ring Generation Summary (%s) ---\n', dirLabel);
    
    for i = 1:numel(ring_mm)
        offset_mm = ring_mm(i);
        
        % Convert mm to integer voxel offsets along chosen axis
        nVoxOut = max(1, round(offset_mm / voxelSizeAxis));
        nVoxIn  = max(0, round(marginPTVRing_mm / voxelSizeAxis));
        nVoxIn  = min(nVoxIn, nVoxOut - 1); % ensure inner < outer
        
        % Build directional band
        ringMask = local_buildDirectionalBand(voiMask, axisIdx, dirSign, nVoxOut, nVoxIn);
        ringIndices = find(ringMask);
        
        % --- Update CST ---
        newRow = size(cst,1)+1;
        ixAdded = [ixAdded; newRow]; %#ok<AGROW>
        
        ringName = sprintf('%s_%sRing%imm', voiName, dirLabel, round(offset_mm));
        cst{newRow, 1} = newRow;
        cst{newRow, 2} = ringName;
        cst{newRow, 3} = 'TARGET';
        cst{newRow, 4} = {ringIndices};
        cst{newRow, 5} = cst{ixRefVOI, 5};
        cst{newRow, 5}.visibleColor = rand(1, 3);
        cst{newRow, 5}.Priority     = newRow;
        
        % --- Store metadata ---
        ringInfo(i).name         = ringName;
        ringInfo(i).margin_mm    = offset_mm;
        ringInfo(i).direction    = char(dirLabel);
        ringInfo(i).directions   = {};
        ringInfo(i).mode         = '';
        ringInfo(i).voxelsAdded  = numel(ringIndices);
        ringInfo(i).mask         = ringMask;
        ringInfo(i).linearIndices = ringIndices;
        
        % --- Log info ---
        voxelOffset = round(offset_mm / voxelSizeAxis);
        fprintf('Ring %d (%s, dir=%s): %.1f mm ~ %d voxels along axis %d\n', ...
            i, ringName, dirLabel, offset_mm, voxelOffset, axisIdx);
    end
    
    fprintf('------------------------------------------------\n');

%% --- CASE 2: Multiple directions, combined ------------------------------
else
    if numel(ring_mm) > 1
        warning('matRad_VOIDirRings:MultiRingMultiDir', ...
            'Multiple ring_mm with multiple directions; using first distance (%.1f mm).', ring_mm(1));
    end
    offset_mm = ring_mm(1);
    
    % Build directional bands for each direction
    bandMasks = cell(numel(directions),1);
    dirLabels = cell(numel(directions),1);
    
    for d = 1:numel(directions)
        [axisIdx, dirSign, dirLabel] = local_parseDirection(directions{d});
        dirLabels{d} = dirLabel;
        voxelSizeAxis = voxelSize(axisIdx);
        
        nVoxOut = max(1, round(offset_mm / voxelSizeAxis));
        nVoxIn  = max(0, round(marginPTVRing_mm / voxelSizeAxis));
        nVoxIn  = min(nVoxIn, nVoxOut - 1);
        
        bandMasks{d} = local_buildDirectionalBand(voiMask, axisIdx, dirSign, nVoxOut, nVoxIn);
    end
    
    % Combine masks
    switch mode
        case 'union'
            comboMask = false(size(voiMask));
            for d = 1:numel(bandMasks)
                comboMask = comboMask | bandMasks{d};
            end
        case 'intersection'
            comboMask = true(size(voiMask));
            for d = 1:numel(bandMasks)
                comboMask = comboMask & bandMasks{d};
            end
    end
    
    comboIdx = find(comboMask);
    
    % Update CST
    newRow = size(cst,1) + 1;
    ixAdded = newRow;
    dirStr = strjoin(dirLabels, '');
    voiNewName = sprintf('%s_%sRing%imm_%s', voiName, dirStr, round(offset_mm), mode);
    
    cst{newRow,1} = newRow;
    cst{newRow,2} = voiNewName;
    cst{newRow,3} = 'TARGET';
    cst{newRow,4} = {comboIdx};
    cst{newRow,5} = cst{ixRefVOI,5};
    cst{newRow,5}.visibleColor = rand(1,3);
    cst{newRow,5}.Priority     = newRow;
    
    % ringInfo
    ringInfo = struct();
    ringInfo.name        = voiNewName;
    ringInfo.margin_mm   = offset_mm;
    ringInfo.direction   = '';
    ringInfo.directions  = directions;
    ringInfo.mode        = mode;
    ringInfo.voxelsAdded = numel(comboIdx);
    ringInfo.mask        = comboMask;
    ringInfo.linearIndices = comboIdx;
    
    fprintf('--- Multi-Directional Ring (%s, %s) ---\n', dirStr, mode);
    fprintf('VOI: %s, %.1f mm, %d voxels\n', voiNewName, offset_mm, numel(comboIdx));
    fprintf('---------------------------------------\n');
end

%% --- Visualization ------------------------------------------------------
if visualize
    sliceIdx = round(ct.cubeDim(3)/2);
    figure; matRad_showSliceFast(ct, cst, [], sliceIdx);
    if isSingleDir
        title(sprintf('Directional rings (%s) around %s on CT slice %d', ...
            dirLabels{1}, voiName, sliceIdx));
    else
        title(sprintf('Multi-directional ring (%s, %s) around %s on CT slice %d', ...
            dirStr, mode, voiName, sliceIdx));
    end
end

ixAdded = ixAdded';

end % function matRad_VOIDirRings


% -------------------------------------------------------------------------
% Local helper: direction parsing
% -------------------------------------------------------------------------
function [axisIdx, dirSign, dirLabel] = local_parseDirection(direction)
dirStr = lower(string(direction));
switch dirStr
    case {"left","l"}
        axisIdx  = 2; dirSign = -1; dirLabel = 'L';
    case {"right","r"}
        axisIdx  = 2; dirSign = +1; dirLabel = 'R';
    case {"up","u"}
        axisIdx  = 1; dirSign = -1; dirLabel = 'U';
    case {"down","d"}
        axisIdx  = 1; dirSign = +1; dirLabel = 'D';
    otherwise
        error('local_parseDirection:UnknownDirection', ...
            'Unknown direction "%s". Use left/right/up/down or L/R/U/D.', dirStr);
end
end

% -------------------------------------------------------------------------
% Local helper: build directional band
% -------------------------------------------------------------------------
function bandMask = local_buildDirectionalBand(voiMask, axisIdx, dirSign, nVoxOut, nVoxIn)
% local_buildDirectionalBand - Build directional band between two offsets
%
% bandMask includes all voxels at directional distances in (nVoxIn, nVoxOut]
% from the original voiMask, along axisIdx with sign dirSign.

sz = size(voiMask);
bandMask = false(sz);

% Starting from base mask
currMask = voiMask;

% Shift vector for circshift
shiftVec = [0 0 0];
shiftVec(axisIdx) = dirSign;

for s = 1:nVoxOut
    % Shift mask one voxel in given direction
    currMask = circshift(currMask, shiftVec);
    
    % Remove wrapped-in voxels on the opposite boundary
    switch axisIdx
        case 1 % rows (y)
            if dirSign > 0
                currMask(1,:,:) = false;       % content wrapped from bottom
            else
                currMask(end,:,:) = false;     % content wrapped from top
            end
        case 2 % columns (x)
            if dirSign > 0
                currMask(:,1,:) = false;       % content wrapped from right
            else
                currMask(:,end,:) = false;     % content wrapped from left
            end
        case 3 % slices (z) - not used here, but kept for completeness
            if dirSign > 0
                currMask(:,:,1) = false;
            else
                currMask(:,:,end) = false;
            end
    end
    
    % Add to band if beyond inner offset
    if s > nVoxIn
        bandMask = bandMask | currMask;
    end
end

end