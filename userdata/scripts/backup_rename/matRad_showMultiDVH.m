function [fig, lgd, h, axDVH] = matRad_showMultiDVH(dvhMulti, cst, varargin)
% matRad_showMultiDVH - Plot DVHs from multiple sources for each VOI
%
% Syntax:
%   [fig, lgd, h] = matRad_showMultiDVH(dvhMulti, cst)
%
% Optional Name-Value Pairs:
%   'axesHandle'      - Axes to plot into (default: gca)
%   'LineWidth'       - Width of DVH lines (default: 4.0)
%   'plotLegend'      - true/false (default: true)
%   'splitLegend'     - true/false (default: false). If true, creates 2 legends:
%                       one for VOIs and one for sources (plans).
%   'legendLocation'  - legend location for VOI legend (default: 'NorthEast')
%   'legendLocation2' - legend location for source legend (default: 'SouthEast')
%   'annotateMetrics' - true/false (default: false)
%
% Outputs:
%   fig - Figure handle
%   lgd - Legend handle OR struct with fields .roi and .source if splitLegend==true
%   h   - Struct of line handles (h.voi, h.source)
%   axDVH - Axes handle

%% Parse input
p = inputParser;
p.addRequired('dvhMulti', @isstruct);
p.addRequired('cst', @iscell);
p.addParameter('axesHandle', [], @(x) isempty(x) || isgraphics(x, 'axes'));
p.addParameter('LineWidth', 4.0, @(x) isnumeric(x) && x > 0);
p.addParameter('plotLegend', true, @(x) islogical(x) && isscalar(x));
p.addParameter('splitLegend', false, @(x) islogical(x) && isscalar(x));
p.addParameter('legendLocation', 'NorthEast', @(x) ischar(x) || isstring(x));
p.addParameter('legendLocation2', 'SouthEast', @(x) ischar(x) || isstring(x));
p.addParameter('annotateMetrics', false, @(x) islogical(x) && isscalar(x));
p.parse(dvhMulti, cst, varargin{:});

axDVH = p.Results.axesHandle;
if isempty(axDVH)
    fig = figure('Color','w');
    axDVH = gca;
else
    fig = gcf;
end

lineWidth       = p.Results.LineWidth;
plotLegend      = p.Results.plotLegend;
splitLegend     = p.Results.splitLegend;
legendLocation  = char(p.Results.legendLocation);
legendLocation2 = char(p.Results.legendLocation2);
annotateMetrics = p.Results.annotateMetrics;

hold(axDVH, 'on');

matRad_cfg = MatRad_Config.instance();

%% Identify all sources and VOIs
sourceNames = fieldnames(dvhMulti);
numSources  = numel(sourceNames);

firstDVH = dvhMulti.(sourceNames{1});
voiNames = {firstDVH.name}.';
numVois  = numel(voiNames);

lineStyles = {'-', ':', '-.', '--'};
if numSources > numel(lineStyles)
    warning('More sources than line styles available. Reusing styles.');
    lineStyles = repmat(lineStyles, 1, ceil(numSources/numel(lineStyles)));
end

%% Track legend handles
voiLegendHandles    = gobjects(numVois, 1);
sourceLegendHandles = gobjects(numSources, 1);

maxDose = 0;

%% Plot DVHs
for s = 1:numSources
    source   = sourceNames{s};
    style    = lineStyles{s};
    dvhArray = dvhMulti.(source);

    for v = 1:numVois
        dvh = dvhArray(v);

        if isempty(dvh.volumePoints)
            continue;
        end

        x = dvh.doseGrid;
        y = dvh.volumePoints;

        firstZeroIdx = find(y <= 0, 1, 'first');
        if ~isempty(firstZeroIdx)
            x = x(1:firstZeroIdx);
            y = y(1:firstZeroIdx);
        end

        maxDose = max(maxDose, max(x));

        c = cst{v, 5}.visibleColor;

        hLine = plot(axDVH, x, y, ...
            'LineStyle', style, ...
            'Color', c, ...
            'LineWidth', lineWidth);

        if s == 1
            hLine.DisplayName = string(voiNames{v});
            voiLegendHandles(v) = hLine;
        else
            hLine.Annotation.LegendInformation.IconDisplayStyle = 'off';
        end

        if annotateMetrics
            [~, ix98] = min(abs(y - 98));
            text(axDVH, x(ix98), y(ix98), ' D_{98}', ...
                 'VerticalAlignment', 'bottom', ...
                 'FontSize', 8, 'Color', c);

            [~, ix2] = min(abs(y - 2));
            text(axDVH, x(ix2), y(ix2), ' D_{2}', ...
                 'VerticalAlignment', 'top', ...
                 'FontSize', 8, 'Color', c);
        end
    end

    hFake = plot(axDVH, NaN, NaN, ...
        'LineStyle', style, ...
        'Color', [0 0 0], ...
        'LineWidth', lineWidth, ...
        'DisplayName', strrep(source, '_', ' '));
    sourceLegendHandles(s) = hFake;
end

%% Styling
xlabel(axDVH, 'Dose [Gy]', 'FontSize', matRad_cfg.gui.fontSize);
ylabel(axDVH, 'Volume [%]', 'FontSize', matRad_cfg.gui.fontSize);
grid(axDVH, 'on'); grid(axDVH, 'minor'); box(axDVH, 'on');

xlim(axDVH, [0 1.05*maxDose]);
ylim(axDVH, [0 100]);

set(axDVH, 'LineWidth', 1, 'FontSize', matRad_cfg.gui.fontSize);

fontsize(12, 'points')

%% Legend(s)
lgd = [];
if plotLegend
    if ~splitLegend
        lgd = legend(axDVH, [voiLegendHandles; sourceLegendHandles], ...
            'Location', legendLocation, 'AutoUpdate', 'off');
        lgd.FontSize  = matRad_cfg.gui.fontSize;
        lgd.TextColor = matRad_cfg.gui.textColor;

    else
        % 1) ROI legend on the main axes
        lgdROI = legend(axDVH, voiLegendHandles, ...
            'Location', legendLocation, 'AutoUpdate', 'off');
        lgdROI.Title.String = 'ROIs';
        lgdROI.FontSize  = matRad_cfg.gui.fontSize;
        lgdROI.TextColor = matRad_cfg.gui.textColor;

        % 2) Source legend in a tiny overlay axes (so we can have a second legend)
        axLeg = axes('Parent', fig, 'Position', axDVH.Position, 'Color', 'none', ...
            'XTick', [], 'YTick', [], 'Box', 'off', 'Visible', 'off'); %#ok<LAXES>
        hold(axLeg, 'on');

        % Re-parent the fake lines so the 2nd legend can "see" them
        for i = 1:numel(sourceLegendHandles)
            if isgraphics(sourceLegendHandles(i))
                sourceLegendHandles(i).Parent = axLeg;
            end
        end

        lgdSRC = legend(axLeg, sourceLegendHandles, ...
            'Location', legendLocation2, 'AutoUpdate', 'off');
        lgdSRC.Title.String = 'Plans';
        lgdSRC.FontSize  = matRad_cfg.gui.fontSize;
        lgdSRC.TextColor = matRad_cfg.gui.textColor;

        % Return both
        lgd = struct();
        lgd.roi    = lgdROI;
        lgd.source = lgdSRC;
        lgd.ax     = axLeg;
    end
end

%% Output handles
h = struct();
h.voi    = voiLegendHandles;
h.source = sourceLegendHandles;

hold(axDVH, 'off');
end