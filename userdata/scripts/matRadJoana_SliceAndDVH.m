function [hleg, dvh] = matRadJoana_SliceAndDVH(ct, cst, doseCube, dvh, figName, slice, doseWindow, boolPlotLegend)
% matRadJoana_SliceAndDVH(ct, cst, results.BroadFlash_Arc, dvh, replace(wildcard, '_', '-'), [], [0 30])
if ~exist('dvh', 'var') || isempty(dvh)
    dvh = matRad_calcDVH(cst, doseCube);
end

if ~exist('figName', 'var') || isempty(figName)
    figName = '';
end

if ~exist('slice', 'var') || isempty(slice)
    slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = slice(3);
end

if ~exist('doseWindow', 'var') || isempty(doseWindow)
    doseWindow = [min(doseCube(:)), max(doseCube(:))];
end

if ~exist('boolPlotLegend', 'var') || isempty(boolPlotLegend)
    boolPlotLegend = 1;
end

matRad_cfg = MatRad_Config.instance();
fontSizeValue = matRad_cfg.gui.fontSize;

%%
figure('units','normalized','outerposition',[0 0 1 1], ...
    'Color', [1 1 1], ...
    'Name', figName)
% Color - [1 1 1] or 'none'

%%
t = tiledlayout(1,2); % 1 row, 2 columns
title(t, figName);

nexttile
[~, hleg] = matRadJoana_ShowSliceFast(ct, cst, doseCube, slice, doseWindow);
set(gca, 'LineWidth', 0.5, 'FontSize', fontSizeValue);
title('Dose Distribution')

doseLeg = get(gca, 'Legend');
doseLeg.Visible = 'off';

nexttile
% dvh = matRad_calcDVH(cst, doseCube); 
matRadJoana_showDVH(dvh, cst);
set(gca, 'LineWidth', 0.5, 'FontSize', fontSizeValue);
title('DVH')
dvhLeg = get(gca, 'Legend');
dvhLeg.Location = 'bestoutside';

%% Check legend
if ~isequal(size(doseLeg.String, 2), size(dvhLeg.String, 2))
    warning('The size of the legends for the dose distribution and dvh do not match.Please check.')
end

end