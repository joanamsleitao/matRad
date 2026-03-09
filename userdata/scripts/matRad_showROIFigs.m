function hFigs = matRad_showROIFigs(ct, cst, slice, plane, outDir, levelZoom)
% matRad_showROIFigs - Export CT figures and individual ROI contour figures
%
% Syntax:
%   hFigs = matRad_showROIFigs(ct, cst)
%   hFigs = matRad_showROIFigs(ct, cst, slice)
%   hFigs = matRad_showROIFigs(ct, cst, slice, plane)
%   hFigs = matRad_showROIFigs(ct, cst, slice, plane, outDir)
%   hFigs = matRad_showROIFigs(ct, cst, slice, plane, outDir, levelZoom)
%
% Description:
%   Creates:
%   1. One CT-only figure (plain, white background)
%   2. One CT figure with all visible contours overlaid (white background)
%   3. One figure per visible ROI (contour only, transparent background)
%
%   CT figures can be zoomed using matRad_getZoomWindow. ROI-only figures
%   use the same zoom window so they align with the CT exports in PowerPoint.
%   CT figures are saved as PNG. ROI-only figures are saved as SVG.
%
% Inputs:
%   ct        - matRad CT struct
%   cst       - matRad CST cell array
%   slice     - (optional) slice index in selected plane (default: isocenter slice)
%   plane     - (optional) plane: coronal = 1, sagittal = 2, axial = 3 (default: 3)
%   outDir    - (optional) output directory for exported files (default: current folder)
%   levelZoom - (optional) zoom level for CT figures (default: [])
%
% Outputs:
%   hFigs - struct with fields:
%             .ct     - figure handle for plain CT
%             .ctCont - figure handle for CT with all visible contours
%             .roi    - array of figure handles, one per visible ROI
%
% Reference list entry:
%   | - | `matRad_showROIFigs` | Export CT and ROI contour figures for PPT |
%   | `hFigs = matRad_showROIFigs(ct, cst, slice, plane, outDir, levelZoom)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

%% --- Defaults
if ~exist('plane', 'var') || isempty(plane)
    plane = 3;
end

if ~exist('outDir', 'var') || isempty(outDir)
    outDir = pwd;
end

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

isoCenterIx = matRad_world2cubeIndex(matRad_getIsoCenter(cst, ct, 0), ct);

if ~exist('slice', 'var') || isempty(slice)
    slice = isoCenterIx(3);
else
    isoCenterIx(3) = slice;
end

if ~exist('levelZoom', 'var') || isempty(levelZoom)
    levelZoom = [];
end

cubeIdx = 1;

%% --- Aspect ratio helper
ratios = [1/ct.resolution.x 1/ct.resolution.y 1/ct.resolution.z];
if plane == 1
    res = [ratios(3) ratios(2)] ./ max([ratios(3) ratios(2)]);
elseif plane == 2
    res = [ratios(3) ratios(1)] ./ max([ratios(3) ratios(1)]);
else
    res = [ratios(2) ratios(1)] ./ max([ratios(2) ratios(1)]);
end

%% --- Zoom window
xlimVals = [];
ylimVals = [];
if ~isempty(levelZoom)
    [xlimVals, ylimVals] = matRad_getZoomWindow(isoCenterIx(2), isoCenterIx(1), ct, levelZoom);

    if xlimVals(1) == xlimVals(2) || ylimVals(1) == ylimVals(2)
        xlimVals = [xlimVals(1)-30, xlimVals(2)+30];
        ylimVals = [ylimVals(1)-30, ylimVals(2)+30];
    end
end

%% --- Visible ROI selection
nROI = size(cst, 1);
voiSelection = true(nROI, 1);
for k = 1:nROI
    if isfield(cst{k,5}, 'Visible') && cst{k,5}.Visible == 0
        voiSelection(k) = false;
    end
end

%% --- CT-only figure (plain)
hFigs.ct = figure('Visible', 'off', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
set(hFigs.ct, 'Color', 'white');
ax = axes('Parent', hFigs.ct);

matRad_plotCtSlice(ax, ct.cubeHU, cubeIdx, plane, slice);
set(ax, 'YDir', 'Reverse');
set(ax, 'DataAspectRatioMode', 'manual', 'DataAspectRatio', [res 1]);

if ~isempty(levelZoom)
    set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
end

axis(ax, 'off');
exportgraphics(hFigs.ct, fullfile(outDir, 'CT_plain.png'), ...
    'BackgroundColor', 'white', 'Resolution', 300);

%% --- CT figure with all visible contours
hFigs.ctCont = figure('Visible', 'off', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
set(hFigs.ctCont, 'Color', 'white');
ax = axes('Parent', hFigs.ctCont);

matRad_plotCtSlice(ax, ct.cubeHU, cubeIdx, plane, slice);
hold(ax, 'on');

matRad_plotVoiContourSlice(ax, cst, ct, cubeIdx, voiSelection, plane, slice, [], 'LineWidth', 5);

set(ax, 'YDir', 'Reverse');
set(ax, 'DataAspectRatioMode', 'manual', 'DataAspectRatio', [res 1]);

if ~isempty(levelZoom)
    set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
end

axis(ax, 'off');
exportgraphics(hFigs.ctCont, fullfile(outDir, 'CT_contours.png'), ...
    'BackgroundColor', 'white', 'Resolution', 300);

%% --- One figure per visible ROI
hFigs.roi = gobjects(0);
roiCount = 0;

for i = 1:nROI
    if ~voiSelection(i)
        continue
    end

    voiSel = false(nROI, 1);
    voiSel(i) = true;

    roiCount = roiCount + 1;
    hFig = figure('Visible', 'off', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
    set(hFig, 'Color', 'none');
    ax = axes('Parent', hFig);

    hold(ax, 'on');
    set(ax, 'Color', 'none');
    set(ax, 'YDir', 'Reverse');

    matRad_plotVoiContourSlice(ax, cst, ct, cubeIdx, voiSel, plane, slice, [], 'LineWidth', 5);

    set(ax, 'DataAspectRatioMode', 'manual', 'DataAspectRatio', [res 1]);

    if ~isempty(levelZoom)
        set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
    end

    axis(ax, 'off');

    roiName = matlab.lang.makeValidName(cst{i,2});
    % exportgraphics(ax, fullfile(outDir, [roiName '.svg']), ...
    %     'BackgroundColor', 'none', 'ContentType', 'vector');
saveas(hFig, fullfile(outDir, [roiName '.svg']));
    hFigs.roi(roiCount) = hFig;
end

fprintf('Created %d ROI figure(s) + 2 CT figure(s) in: %s\n', roiCount, outDir);

end