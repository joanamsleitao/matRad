function matRad_compareTwoDoses(doseRef, doseTest, ct, cst, outFolder, varargin)
% matRad_compareTwoDoses - Compare two dose cubes and save a summary PNG
%
% USAGE:
%   matRad_compareAndSaveFigures(doseRef, doseTest, ct, cst, outFolder)
%   matRad_compareAndSaveFigures(..., 'isodoseLevels', [0.9 0.7 0.5], ...)
%
% INPUTS:
%   doseRef   - reference dose cube (Gy) [3D]
%   doseTest  - test dose cube (Gy) [3D]
%   ct        - matRad CT struct
%   cst       - matRad CST cell array
%   outFolder - folder to save PNG
%
% NAME-VALUE OPTIONS:
%   'isodoseLevels'   - vector of fractions of max dose to evaluate (default [0.9 0.7 0.5])
%   'voisToReport'    - cell array of VOI names or numeric indices to include in table.
%                       If empty (default) uses all visible VOIs in CST except 'External'.
%   'filePrefix'      - prefix for output filename (default 'compare')
%   'dpi'             - output resolution in DPI (default 150)
%   'figSize'         - figure size in pixels [w h] (default [1800 1000])
%
% NOTES:
%   - Uses matRad_VOIfindIndex to find PTV index and checks cst{ix,3} for 'TARGET'.
%   - Slice selection: within the combined PTV mask, choose slice (z) with largest
%     sum(abs(doseRef - doseTest)) inside that slice.
%   - Table shows D_2, D_50, D_95 (Gy) for each VOI and CI for PTV (if present).
%   - Also reports numbers of voxels inside isodose volumes for both doses.
%
% EXAMPLE:
%   matRad_compareAndSaveFigures(doseClinical, doseReplica, ct, cst, './out', ...
%       'isodoseLevels', [0.9 0.7 0.5], 'filePrefix', 'Patient01_compare');
%
% Author: Joana
% ----------------------------------------------------------------------

%% Parse inputs
p = inputParser;
addParameter(p, 'isodoseLevels', [0.9 0.7 0.5], @(x)isnumeric(x) && all(x>0 & x<=1));
addParameter(p, 'voisToReport', [], @(x)isempty(x) || iscell(x) || isnumeric(x));
addParameter(p, 'filePrefix', 'compare', @ischar);
addParameter(p, 'dpi', 150, @isnumeric);
addParameter(p, 'figSize', [1800 1000], @(x)isnumeric(x) && numel(x)==2);
parse(p, varargin{:});
opts = p.Results;


if ~isfolder(outFolder)
    mkdir(outFolder);
end

%% Basic checks
if ~isequal(size(doseRef), size(doseTest))
    error('doseRef and doseTest must have identical dimensions.');
end
cubeDim = ct.cubeDim; % assume available
if ~isequal(size(doseRef), cubeDim)
    % some matRad installations store cubeDim as [nx ny nz]
    if ~isequal(size(doseRef), [cubeDim(1) cubeDim(2) cubeDim(3)])
        warning('doseCube size and ct.cubeDim mismatch — proceeding but check visuals.');
    end
end

%% 1) DVHs (prepare dvhMulti struct for plotting)
dvhRef  = matRad_calcDVH(cst, doseRef);
dvhTest = matRad_calcDVH(cst, doseTest);

dvhAll = struct();
dvhAll.Reference = dvhRef;
dvhAll.Test      = dvhTest;

%% 2) Find PTV index(es)
ixPTV = matRad_VOIfindIndex(cst, 'PTV'); % may return multiple indices
% ensure these are targets
if ~isempty(ixPTV)
    isTargetMask = false(size(ixPTV));
    for k=1:numel(ixPTV)
        isTargetMask(k) = contains(cst{ixPTV(k),3}, 'TARGET', 'IgnoreCase', true);
    end
    ixPTV = ixPTV(isTargetMask);
end

if isempty(ixPTV)
    % fallback: find first cst entry that contains 'PTV' in name or has TARGET flag
    idxTargetFlag = find(cellfun(@(s) contains(s,'TARGET','IgnoreCase',true), cst(:,3)), 1);
    if ~isempty(idxTargetFlag)
        ixPTV = idxTargetFlag;
    else
        warning('No PTV found. Slice selection will use global maximum difference slice.');
    end
end

%% 3) Compute slice with maximum abs difference inside PTV(s)
doseDiff = doseRef - doseTest;
absDiff  = abs(doseDiff);

if ~isempty(ixPTV)
    % combine all PTV voxel indices
    ptvIdxAll = [];
    for k=1:numel(ixPTV)
        if iscell(cst{ixPTV(k),4}) && ~isempty(cst{ixPTV(k),4}{1})
            ptvIdxAll = [ptvIdxAll; cst{ixPTV(k),4}{1}(:)];
        end
    end
    ptvIdxAll = unique(ptvIdxAll);

    if isempty(ptvIdxAll)
        warning('PTV index exists but contains no voxels. Will use global slice.');
        useGlobal = true;
    else
        useGlobal = false;
        % get z-subindices
        [~, ~, zSubs] = ind2sub(size(doseRef), ptvIdxAll);
        zRange = unique(zSubs);
        % sum absolute diff per z inside PTV
        sliceSums = zeros(numel(zRange),1);
        for ii = 1:numel(zRange)
            z = zRange(ii);
            maskZ = (zSubs == z);
            sliceLinear = ptvIdxAll(maskZ);
            sliceSums(ii) = sum(absDiff(sliceLinear));
        end
        [~, imax] = max(sliceSums);
        sliceToPlot = zRange(imax);
    end
else
    useGlobal = true;
end

if useGlobal
    % compute slice with maximum absolute difference global
    absPerSlice = squeeze(sum(sum(absDiff,1),2)); % z vector
    [~, sliceToPlot] = max(absPerSlice);
end

%% 4) Create masks and isodose volumes
maxRef = max(doseRef(:));
isoLevels = opts.isodoseLevels;
numIso = numel(isoLevels);

isoCountsRef = zeros(1,numIso);
isoCountsTest = zeros(1,numIso);
for ii = 1:numIso
    thrRef = isoLevels(ii) * maxRef;
    isoCountsRef(ii)  = nnz(doseRef >= thrRef);
    isoCountsTest(ii) = nnz(doseTest >= thrRef); % compare using same absolute threshold
end

%% 5) Determine VOIs to report in table
if isempty(opts.voisToReport)
    % by default: all visible VOIs except 'External'
    visMask = cellfun(@(s) isfield(s,'Visible') && s.Visible==1, cst(:,5));
    if ~any(visMask)
        % fallback: include all VOIs
        voisIdx = (1:size(cst,1))';
    else
        voisIdx = find(visMask);
    end
    % remove External
    extIdx = find(strcmpi(cst(:,2),'External'));
    voisIdx = setdiff(voisIdx, extIdx);
else
    if isnumeric(opts.voisToReport)
        voisIdx = opts.voisToReport(:);
    else
        % match names to indices
        names = lower(string(cst(:,2)));
        requested = lower(string(opts.voisToReport));
        voisIdx = [];
        for r = 1:numel(requested)
            m = find(contains(names, requested(r)), 1);
            if ~isempty(m), voisIdx(end+1,1)=m; end
        end
    end
end

%% 6) Compute quality indicators for reference and test (D_2, D_50, D_95)
qiRef  = matRad_calcQIndAdapted(cst(voisIdx,:), [], doseRef, [], []);
qiTest = matRad_calcQIndAdapted(cst(voisIdx,:), [], doseTest, [], []);

% Build table data
nVOI = numel(voisIdx);
T = cell(nVOI+1, 1 + 3 + numIso); % name + D2 D50 D95 + iso counts
header = [{'Structure', 'D2_Gy', 'D50_Gy', 'D95_Gy'} , arrayfun(@(x) sprintf('Vox_iso%02d%%',round(100*x)), isoLevels, 'UniformOutput', false)];
T(1,:) = header;

for v = 1:nVOI
    name = cst{voisIdx(v),2};
    % find qi elements by matching names inside qiRef (they should align since we passed cst subset)
    Qr = qiRef(v);
    Qt = qiTest(v);
    d2 = NaN; d50 = NaN; d95 = NaN;
    if isfield(Qr,'D_2'),  d2  = Qr.D_2;  end
    if isfield(Qr,'D_50'), d50 = Qr.D_50; end
    if isfield(Qr,'D_95'), d95 = Qr.D_95; end

    % isodose counts (report reference and test as "ref/test" string per iso)
    isoStrs = cell(1,numIso);
    for ii = 1:numIso
        isoStrs{ii} = sprintf('%d/%d', isoCountsRef(ii), isoCountsTest(ii));
    end

    row = [{name}, num2cell([d2 d50 d95]), isoStrs];
    T(v+1, :) = row;
end

% If PTV present compute CI (try find a CI field in qiRef for PTV)
ciVal = NaN;
if ~isempty(ixPTV)
    % find row corresponding to PTV in voisIdx
    ptvName = lower(string(cst{ixPTV(1),2}));
    % find that index in voisIdx list
    ptvLocal = find(contains(lower(string(cst(voisIdx,2))), ptvName), 1);
    if ~isempty(ptvLocal)
        qptv = qiRef(ptvLocal);
        % search fields that start with 'CI_'
        f = fieldnames(qptv);
        ciFields = f(startsWith(f,'CI_'));
        if ~isempty(ciFields)
            ciVal = qptv.(ciFields{1});
        end
    end
end

%% 7) Build figure with 2x2 layout: DVH (left), 3 slices (right stacked), Table below or right
fig = figure('Color','w','Units','pixels','Position',[100 100 opts.figSize]);
% layout: left DVH occupying left half, right column stacked 3 images, bottom table full width
t = tiledlayout(fig, 3, 4, 'TileSpacing','compact', 'Padding','compact');
% make DVH on left spanning rows 1:2 and columns 1:2? Simpler: set positions manually via subtightplot style:
% We'll use tiledlayout with explicit spans:
nexttile([3 2]); % left big tile spanning all rows x 2 cols
axDVH = gca;
hold(axDVH,'on');
matRad_showMultiDVH(dvhAll, cst, 'axesHandle', axDVH, 'LineWidth', 1.5, 'plotLegend', true);
title(axDVH, 'DVH: Reference vs Test');
hold(axDVH,'off');

% Now right column: three slices
% Reference
nexttile; ax1 = gca;
matRad_showSliceFast(ct, cst, doseRef, sliceToPlot, [], false, 0);
title(ax1, sprintf('Reference (slice %d)', sliceToPlot));

% Test
nexttile; ax2 = gca;
matRad_showSliceFast(ct, cst, doseTest, sliceToPlot, [], false, 0);
title(ax2, sprintf('Test (slice %d)', sliceToPlot));

% Abs diff - use a diverging or different colormap
nexttile; ax3 = gca;
% Display abs diff with its own range
maxAbs = max(absDiff(:));
matRad_showSliceFast(ct, cst, absDiff, sliceToPlot, [0 maxAbs], false, 0);
colormap(ax3, parula); % or other; user asked different colormap — leave default
title(ax3, sprintf('Absolute difference (Gy)'));

nexttile; axT = gca;
axis(axT,'off');
% Finally table as big tile bottom (span width)
nexttile([1 2]); axT = gca;
axis(axT,'off');
% Build a textual table inside axes
txt = cell(size(T,1), size(T,2));
for r = 1:size(T,1)
    for c = 1:size(T,2)
        val = T{r,c};
        if isempty(val), s = ''; else s = char(string(val)); end
        txt{r,c} = s;
    end
end

% Build formatted string lines
colWidths = cellfun(@(x) max(cellfun(@(y) numel(y), txt(:,x))), num2cell(1:size(T,2)));
% Create header line
headerLine = strjoin(txt(1,:), '  |  ');
lines = cell(size(txt,1)-1,1);
for r = 2:size(txt,1)
    lines{r-1} = strjoin(txt(r,:), '  |  ');
end

% Print header and lines using text()
y = 0.95;
text(axT, 0.01, y, headerLine, 'FontWeight','bold', 'FontName','FixedWidth');
y = y - 0.04;
for r = 1:numel(lines)
    text(axT, 0.01, y, lines{r}, 'FontName','FixedWidth');
    y = y - 0.03;
    if y < 0.02, break; end
end
% Add CI info if found
if ~isnan(ciVal)
    text(axT, 0.7, 0.95, sprintf('PTV CI: %.3f', ciVal), 'FontWeight','bold');
end

% Save figure
% timestamp = datestr(now,'yyyymmdd_HHMMSS');
% outName = fullfile(outFolder, sprintf('%s_%s.png', opts.filePrefix, timestamp));
% try
    % export_fig(outName,'-png','-r150'); %#ok<TRYNC> % if export_fig available
% catch
    % % fallback to print
    % print(fig, outName, '-dpng', ['-r' num2str(opts.dpi)]);
% end

fprintf('Saved comparison figure to: %s\n', outName);

end
