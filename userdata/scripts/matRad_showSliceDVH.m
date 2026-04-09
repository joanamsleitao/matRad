function [fig, hleg, dvh] = matRad_showSliceDVH(ct, cst, doseCube, dvh, figName, slice, doseWindow, boolPlotLegend, zoomFactor)
% MATRADJOANA_showSLICEANDDVH
%   Displays a dose distribution slice and the corresponding DVH side-by-side.
%
% SYNTAX:
%   [hleg, dvh] = matRadJoana_showSliceAndDVH(ct, cst, doseCube)
%   [hleg, dvh] = matRadJoana_showSliceAndDVH(ct, cst, doseCube, dvh, figName, slice, doseWindow, boolPlotLegend)
%
% DESCRIPTION:
%   This function plots:
%     1) The dose distribution over a selected CT slice.
%     2) The Dose-Volume Histogram (DVH) for the current plan.
%
%   It can automatically calculate the DVH if not provided, determine the slice
%   from the plan isocenter, and adjust the dose window to min/max values.
%
% INPUTS:
%   ct            - matRad CT structure
%   cst           - matRad structure table
%   doseCube      - 3D dose distribution
%   dvh           - (Optional) Pre-computed DVH structure
%   figName       - (Optional) Figure window name/title
%   slice         - (Optional) Slice index to display
%   doseWindow    - (Optional) [min max] dose range for display
%   boolPlotLegend- (Optional) Boolean flag to plot legend (currently unused)
%
% OUTPUTS:
%   hleg          - Handle to legend in the dose distribution plot
%   dvh           - DVH structure used for plotting
%
% EXAMPLE:
%   [hleg, dvh] = matRadJoana_SliceAndDVH(ct, cst, results.BroadFlash_Arc, [], 'Patient-01', [], [0 30]);
%
% -------------------------------------------------------------------------

%% -------------------- Input Handling --------------------
if ~exist('dvh', 'var') || isempty(dvh)
    dvh = matRad_calcDVH(cst, doseCube);
end

if ~exist('figName', 'var') || isempty(figName)
    figName = '';
end

if ~exist('slice', 'var') || isempty(slice)
    % Default: slice through isocenter
    isoCenterIdx = matRad_world2cubeIndex(matRad_getIsoCenter(cst, ct, 0), ct);
    slice = isoCenterIdx(3);
end

if ~exist('doseWindow', 'var') || isempty(doseWindow)
    doseWindow = [min(doseCube(:)), max(doseCube(:))];
end

if ~exist('boolPlotLegend', 'var') || isempty(boolPlotLegend)
    boolPlotLegend = true;
end

if ~exist('zoomFactor', 'var') || isempty(zoomFactor)
    zoomFactor = [];
end

% Get matRad GUI font size config
matRad_cfg = MatRad_Config.instance();
fontSizeValue = matRad_cfg.gui.fontSize;

%% -------------------- Figure Setup --------------------
fig = figure('Units', 'normalized', ...
       'OuterPosition', [0 0 1 1], ...
       'Color', [1 1 1], ...
       'Name', figName);

t = tiledlayout(1, 2); % 1 row, 2 columns
title(t, figName);

%% -------------------- Dose Slice Plot --------------------
nexttile
[~, hleg] = matRad_showSliceFast(ct, cst, doseCube, slice, doseWindow, [], zoomFactor);
set(gca, 'LineWidth', 0.5, 'FontSize', fontSizeValue);
title('Dose Distribution');

% Hide dose legend (will only use DVH legend)
doseLeg = get(gca, 'Legend');
doseLeg.Visible = 'off';

%% -------------------- DVH Plot --------------------
nexttile
matRad_showDVHAdapted(dvh, cst);
set(gca, 'LineWidth', 0.5, 'FontSize', fontSizeValue);
title('DVH');

% Place DVH legend outside plot
dvhLeg = get(gca, 'Legend');
dvhLeg.Location = 'bestoutside';

%% -------------------- Legend Consistency Check --------------------
if ~isequal(size(doseLeg.String, 2), size(dvhLeg.String, 2))
    warning('Legend mismatch: Dose distribution legend and DVH legend have different sizes.');
end

end
