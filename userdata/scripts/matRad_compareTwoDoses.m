function [hFigSlicesCenter, hFigSlicesMaxDiff, hFigDVH] = matRad_compareTwoDoses(doseRef, doseTest, ct, cst, zoom)
% matRad_compareTwoDoses - Compare two dose distributions visually
%
% INPUTS:
%   doseRef  - reference dose cube [3D]
%   doseTest - test dose cube [3D]
%   ct       - matRad CT struct
%   cst      - matRad CST cell array
%
% OUTPUTS:
%   hFigSlicesCenter  - figure handle for axial center slice comparison
%   hFigSlicesMaxDiff - figure handle for axial slice with max abs difference
%   hFigDVH          - figure handle for DVH comparison

%% Optional var
if ~exist('zoom', 'var') || isempty(zoom)
    zoom = 0;
end
%% Check sizes
if ~isequal(size(doseRef), size(doseTest))
    error('doseRef and doseTest must have the same dimensions.');
end

%% Absolute difference
doseDiff = doseRef - doseTest;

%% Find center slice
isoCenter = matRad_world2cubeIndex(matRad_getIsoCenter(cst, ct, 0), ct);
sliceCenter = isoCenter(3);

%% Find max difference slice inside all PTVs
ixTargets = matRad_VOITargetFindIx(cst);
ptvIdxAll = [];
for k = 1:numel(ixTargets)
        ptvIdxAll = [ptvIdxAll; cst{ixTargets(k),4}{1}(:)];
end

if ~isempty(ptvIdxAll)
    [~,~,zSubs] = ind2sub(size(doseRef), ptvIdxAll);
    % linear ind slices where we have targets
    zRange = unique(zSubs);
    sliceSums = zeros(numel(zRange),1);
    for ii = 1:numel(zRange)
        z = zRange(ii);
        sliceLinear = ptvIdxAll(zSubs==z);
        sliceSums(ii) = sum(abs(doseDiff(sliceLinear)));
    end
    [~, imax] = max(sliceSums);
    sliceMaxDiff = zRange(imax);
else
    % fallback: global max abs difference
    absPerSlice = squeeze(sum(sum(abs(doseDiff,1),2)));
    [~, sliceMaxDiff] = max(absPerSlice);
end

%% 1) Axial center slice
hFigSlicesCenter = figure('Name','hFigSlicesCenter','Color','w',...
    'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
t = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

nexttile;
matRad_showSliceFast(ct, cst, doseRef, sliceCenter, [], 0, zoom);
title(sprintf('Reference (slice %d)', sliceCenter));

nexttile;
matRad_showSliceFast(ct, cst, doseTest, sliceCenter, [], 0, zoom);
title(sprintf('Test (slice %d)', sliceCenter));

nexttile;
matRad_showSliceFast(ct, cst, doseRef-doseTest, sliceCenter, [], 1, zoom);
colormap(gca, sky);
title(sprintf('Difference (slice %d)', sliceCenter));

%% 2) Axial max difference slice
hFigSlicesMaxDiff = figure('Name','hFigSlicesMaxDiff','Color','w');
t = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

nexttile;
matRad_showSliceFast(ct, cst, doseRef, sliceMaxDiff, [], 0, zoom);
title(sprintf('Reference (slice %d)', sliceMaxDiff));

nexttile;
matRad_showSliceFast(ct, cst, doseTest, sliceMaxDiff, [], 0, zoom);
title(sprintf('Test (slice %d)', sliceMaxDiff));

nexttile;
matRad_showSliceFast(ct, cst, doseRef-doseTest, sliceMaxDiff, [], 1, zoom);
colormap(gca, sky);
title(sprintf('Difference (slice %d)', sliceMaxDiff));

%% 3) DVH comparison
dvhAll.Reference = matRad_calcDVH(cst, doseRef);
dvhAll.Test      = matRad_calcDVH(cst, doseTest);

hFigDVH = figure('Name','hFigDVH','Color','w',...
    'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
matRad_showMultiDVH(dvhAll, cst);

end
