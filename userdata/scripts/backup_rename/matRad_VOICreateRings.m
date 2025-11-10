function [cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize)
% matRad_VOICreateRings - Create concentric ring VOIs around (or inside) a reference structure
%
% Syntax:  [cst, ringInfo] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize)
%
% Inputs:
%   ct                 - CT structure (struct)
%   cst                - CST cell array (cell array)
%   ring_mm            - Ring margin(s) [mm] (double array; can be negative for contraction)
%   ixRefVOI           - Reference VOI index (integer)
%   marginPTVRing_mm   - Inner margin from PTV [mm] (double, optional)
%   visualize          - Visualization flag (logical, optional)
%
% Outputs:
%   cst                - Updated CST with ring VOIs (cell array)
%   ringInfo           - Ring metadata structure (struct array)
%
% Notes:
%   - Positive margins create *outer* rings (expansion).
%   - Negative margins create *inner* rings (erosion/contraction).
%   - marginPTVRing_mm defines an inner cutoff (ignored for negative rings).
%
% Requires: matRad_addMargin.m
%
% See also: matRad_addMargin

if nargin < 5 || isempty(marginPTVRing_mm)
    marginPTVRing_mm = 0;
else
    if marginPTVRing_mm >= min(abs(ring_mm))
        warning('Margin from PTV (%.1f mm) close to or larger than smallest ring (%.1f mm). Check configuration.', ...
            marginPTVRing_mm, min(abs(ring_mm)));
    end
end

if nargin < 6
    visualize = false;
end

if nargin < 4 || isempty(ixRefVOI)
    ixRefVOI = find(strcmpi(cst(:,3), 'PTV'), 1);
    if isempty(ixRefVOI)
        error('No PTV VOI found as default. Please specify ixVOI.');
    end
end

ixAdded = [];

baseIndices = cst{ixRefVOI,4}{1};
voiName = cst{ixRefVOI,2};

% Convert linear indices to mask
voiMask = false(ct.cubeDim);
voiMask(baseIndices) = true;

ringInfo = struct('name', {}, 'margin_mm', {}, 'voxelsAdded', {}, 'mask', {}, 'linearIndices', {});

% Sort by absolute magnitude (preserving sign for naming)
[~, order] = sort(abs(ring_mm));
ring_mm = ring_mm(order);

voxelSize = ct.resolution(:)';
voxelSize = [ct.resolution.x ct.resolution.y ct.resolution.z];
disp('--- Ring Generation Summary ---');

for i = 1:length(ring_mm)
    offset_mm = ring_mm(i);
    ringType = 'outer';
    if offset_mm < 0
        ringType = 'inner';
    end

    offset = struct('x', abs(offset_mm), 'y', abs(offset_mm), 'z', abs(offset_mm));

    % === Expansion (outer) ===
    if offset_mm > 0
        outerMask = matRad_addMargin(voiMask, cst, ct.resolution, offset, true);
        if marginPTVRing_mm > 0
            inner = struct('x', marginPTVRing_mm, 'y', marginPTVRing_mm, 'z', marginPTVRing_mm);
            innerMask = matRad_addMargin(voiMask, cst, ct.resolution, inner, true);
            ringMask = outerMask & ~innerMask;
        else
            ringMask = outerMask & ~voiMask;
        end

    % === Contraction (inner) ===
    else
        % Erode structure by abs(offset_mm)
        erodedMask = matRad_addMargin(voiMask, cst, ct.resolution, offset, false); % shrink
        ringMask = voiMask & ~erodedMask;  % difference region (inner shell)
    end

    ringIndices = find(ringMask);

    % Update CST
    newRow = size(cst,1)+1;
    ixAdded = [ixAdded; newRow];
    signLabel = '';
    if offset_mm < 0, signLabel = 'neg'; end
    ringName = sprintf('%s_%sRing%imm', voiName, signLabel, abs(offset_mm));
    cst{newRow, 1} = newRow;
    cst{newRow, 2} = ringName;
    cst{newRow, 3} = 'TARGET';
    cst{newRow, 4} = {ringIndices};
    cst{newRow, 5} = cst{ixRefVOI, 5};
    cst{newRow, 5}.visibleColor = rand(1, 3);
    cst{newRow, 5}.Priority = newRow;

    % Store metadata
    ringInfo(i).name = ringName;
    ringInfo(i).margin_mm = offset_mm;
    ringInfo(i).voxelsAdded = numel(ringIndices);
    ringInfo(i).mask = ringMask;
    ringInfo(i).linearIndices = ringIndices;

    % Display info
    voxelOffset = round(abs(offset_mm) ./ voxelSize);
    voxelsDiag = round(norm(voxelOffset));
    fprintf('Ring %d (%s, %s): %.1f mm = [%d %d %d] voxels (~%d diagonally)\n', ...
        i, ringName, ringType, offset_mm, voxelOffset(1), voxelOffset(2), voxelOffset(3), voxelsDiag);
end

disp('--------------------------------');

% Visualization
if visualize
    sliceIdx = round(ct.cubeDim(3)/2);
    figure; [~, hleg] = matRad_showSliceFast(ct, cst);
    title(sprintf('Rings (±) around %s on CT slice %d', voiName, sliceIdx));
end

ixAdded = ixAdded';
end