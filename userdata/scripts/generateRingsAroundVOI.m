function [cst, ringInfo] = generateRingsAroundVOI(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize)
% GENERATERINGSAROUNDVOI - Create concentric ring VOIs around reference structure
%
% Syntax:  [cst, ringInfo] = generateRingsAroundVOI(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize)
%
% Inputs:
%   ct                 - CT structure (struct)
%   cst                - CST cell array (cell array)
%   ring_mm            - Ring margin(s) [mm] (double array)
%   ixRefVOI           - Reference VOI index (integer)
%   marginPTVRing_mm   - Inner margin from PTV [mm] (double, optional)
%   visualize          - Visualization flag (logical, optional)
%
% Outputs:
%   cst                - Updated CST with ring VOIs (cell array)
%   ringInfo           - Ring metadata structure (struct array)
%
% Other m-files required: matRad_addMargin.m
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_addMargin

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
