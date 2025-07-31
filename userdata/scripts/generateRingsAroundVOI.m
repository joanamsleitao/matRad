function [cst, ringInfo] = generateRingsAroundVOI(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize)
% generateRingsAroundVOI - Generate one or more concentric ring VOIs around a selected structure (e.g., PTV).
%
% This function creates concentric margin-based ring structures around an existing VOI in the CST.
% Each ring corresponds to a margin expansion and optionally a subtraction of an inner margin,
% forming a true "donut" shape. The rings are stored in the CST using linear voxel indices.
%
% This is especially useful for dose fall-off shaping, as ring OARs can be used for gradient constraints.
%
% Compared to matRad_addMargin:
% - This function appends to the CST, preserving structure metadata.
% - It computes the margin in voxel units based on CT resolution.
% - It optionally creates multiple rings (e.g., 5mm, 10mm, 15mm shells).
% - It can visualize the result on a CT slice.
% - It creates ring *VOIs* not masks.
%
% Inputs:
%   ct          - CT struct with geometry info (must include ct.resolution and ct.cubeHU)
%   cst         - Current CST cell array
%   margin_mm   - Scalar or vector of ring margins in mm (e.g., [10] or [5 10 15])
%   ixVOI       - Index of VOI in CST to ring around (default: PTV)
%   visualize   - (Optional) true to plot result. Default: false
%
% Outputs:
%   cst         - Updated CST with new ring structures
%   ringInfo    - Struct array with metadata for each ring created

if nargin < 5 || isempty(marginPTVRing_mm)
    marginPTVRing_mm = 0;
else
    if marginPTVRing_mm >= min(sort(ring_mm))
        error('Margin from PTV to ring as big as ring. Please change margin value');
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

baseIndices = cst{ixRefVOI,4}{1};
voiName = cst{ixRefVOI,2};

% Convert linear indices to mask
voiMask = false(ct.cubeDim);
voiMask(baseIndices) = true;

ringInfo = struct('name', {}, 'margin_mm', {}, 'voxelsAdded', {}, 'mask', {}, 'linearIndices', {});

% Sort margins ascending
ring_mm = sort(ring_mm);

% Calculate voxel expansion for margins
voxelSize = ct.resolution(:)';
disp('--- Ring Generation Summary ---');
for i = 1:length(ring_mm)
    outer_mm = ring_mm(i);

    % Use matRad_addMargin to expand
    outer = struct('x', outer_mm, 'y', outer_mm, 'z', outer_mm);
    outerMask = matRad_addMargin(voiMask, cst, ct.resolution, outer, true);  % or false

    if marginPTVRing_mm > 0
        inner = struct('x', marginPTVRing_mm, 'y', marginPTVRing_mm, 'z', marginPTVRing_mm);
        innerMask = matRad_addMargin(voiMask, cst, ct.resolution, inner, true);  % or false
        ringMask = outerMask & ~innerMask;
    else
        ringMask = outerMask & ~voiMask;
    end

    ringIndices = find(ringMask);

    % Update CST
    newRow = size(cst,1)+1;
    ringName = sprintf('%sRing%imm', voiName, outer_mm);
    cst{newRow, 1} = newRow;                      % Index
    cst{newRow, 2} = ringName;                    % Name
    cst{newRow, 3} = 'TARGET';                       % Type
    cst{newRow, 4} = {ringIndices};              % Voxel indices
    cst{newRow, 5} = cst{ixRefVOI, 5};
    cst{newRow, 5}.visibleColor = rand(3, 1)';%[1 0 0]; % min(cst{ixRefVOI, 5}.visibleColor * 0, [1 1 1]);
    cst{newRow, 5}.Priority = size(cst, 1);

    % Store metadata
    ringInfo(i).name = ringName;
    ringInfo(i).margin_mm = outer_mm;
    ringInfo(i).voxelsAdded = numel(ringIndices);
    ringInfo(i).mask = ringMask;
    ringInfo(i).linearIndices = ringIndices;

    % Display voxel conversion info
    x = round(outer.x/voxelSize.x);
    y = round(outer.y/voxelSize.y);
    z = round(outer.z/voxelSize.z);
    voxelsXYZ = [x y z];
    voxelsDiag = round(norm(voxelsXYZ));
    fprintf('Ring %d (%s): %.1f mm = [%d x %d x %d] voxels (~%d diagonally)', ...
        i, ringName, outer_mm, voxelsXYZ(1), voxelsXYZ(2), voxelsXYZ(3), voxelsDiag);
end

disp('--------------------------------');

% Visualization
if visualize
    sliceIdx = round(ct.cubeDim(3)/2);
    figure; [~, hleg] = matRadJoana_ShowSliceFast(ct, cst);
    % figure; imagesc(ct.cubeHU(:,:,sliceIdx)); colormap gray; axis image off;
    hold on;
    title(sprintf('Rings around %s on CT slice %d', voiName, sliceIdx));
    % for i = 1:length(ringInfo)
    %     [x,y] = ind2sub(size(ct.cubeHU{1}(:,:,sliceIdx)), find(ringInfo(i).mask(:,:,sliceIdx)));
    %     scatter(y, x, 1) %, ringInfo(i).mask(:,:,sliceIdx), 'filled');
    % end
    % legend({ringInfo.name});
end
end
