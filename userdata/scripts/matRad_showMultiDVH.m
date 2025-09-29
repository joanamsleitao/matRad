function [fig, lgd, h] = matRad_showMultiDVH(dvhMulti, cst, varargin)
% MATRAD_PLOTMULTIDVH - Plot DVHs from multiple sources for each VOI
%
% Syntax:
%   matRad_plotMultiDVH(dvhResults, cst)
%
% Inputs:
%   dvhResults - struct of structs (dvhResults.source.voi) containing fields:
%                .doseGrid, .volumePoints, .name
%   cst        - matRad CST cell array
%
% Optional Name-Value Pairs:
%   'axesHandle'  - Axes to plot into (default: gca)
%   'LineWidth'   - Width of DVH lines (default: 2.0)
%   'plotLegend'  - true/false (default: true)
%
% Output:
%   A combined DVH plot with colored VOIs and styled sources.
%

%% Parse input
p = inputParser;
p.addRequired('dvhResults', @isstruct);
p.addRequired('cst', @iscell);
p.addParameter('axesHandle', [], @(x) isempty(x) || isgraphics(x, 'axes'));
p.addParameter('LineWidth', 2.0, @(x) isnumeric(x) && x > 0);
p.addParameter('plotLegend', true, @(x) islogical(x) && isscalar(x));
p.addParameter('annotateMetrics', false, @(x) islogical(x) && isscalar(x));
p.parse(dvhMulti, cst, varargin{:});

ax = gca;
if isempty(ax)
    fig = figure('Color','w');
    ax = gca;
else
    fig = gcf;
end
lineWidth = p.Results.LineWidth;
plotLegend = p.Results.plotLegend;

hold(ax, 'on');

matRad_cfg = MatRad_Config.instance();
annotateMetrics = p.Results.annotateMetrics;

%% Identify all sources and VOIs
sourceNames = fieldnames(dvhMulti);
voiNames = {dvhMulti.(sourceNames{1}).name}.';
numSources = numel(sourceNames);
numVois = size(dvhMulti.(sourceNames{1}),2);

% Generate line styles for sources
lineStyles = {'-', '--', ':', '-.'};
assert(numSources <= numel(lineStyles), 'Too many sources, not enough line styles!');

% Build color map for VOIs using CST
visibleIx = cellfun(@(c) c.Visible == 1, cst(:,5));
visibleNames = cst(visibleIx,2);
visibleColors = cell2mat(cellfun(@(c) c.visibleColor, cst(visibleIx,5), 'UniformOutput', false));
[~, voiColorIdx] = ismember(voiNames, visibleNames);
% voiColors = visibleColors(voiColorIdx,:);

%% Track legend handles
voiLegendHandles = gobjects(numVois,1);
sourceLegendHandles = gobjects(numSources,1);

maxDose = 0;
maxVol = 0;

for s = 1:numSources
    source = sourceNames{s};
    style = lineStyles{s};

    for v = 1:numVois
        voi = voiNames{v};
        dvh = dvhMulti.(source);
        dvh = dvh(v);
        if isempty(dvh.volumePoints)
            continue;
        end

        x = dvh.doseGrid;
        y = dvh.volumePoints;

        maxDose = max(maxDose, max(x));
        maxVol = max(maxVol, max(y));

        c = cst{v,5}.visibleColor;
        % Plot each line regardless of source
        h = plot(ax, x, y, ...
            'LineStyle', style, ...
            'Color', c, ...
            'LineWidth', lineWidth);
                    % HERE ERROR


        % Only add legend entry for the first source per VOI
        if s == 1
            h.DisplayName = string(voi);
            voiLegendHandles(v) = h;
        else
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        end

        % Optional: annotate key DVH metrics
        if annotateMetrics
            % D98: Dose at 98% volume
            [~, ix98] = min(abs(y - 98));

            text(ax, x(ix98), y(ix98), ' D_{98}', ...
                 'VerticalAlignment', 'bottom', ...
                 'HorizontalAlignment', 'left', ...
                 'FontSize', 8, ...
                 'Color', c);

            % D2: Dose at 2% volume
            [~, ix2] = min(abs(y - 2));
            text(ax, x(ix2), y(ix2), ' D_{2}', ...
                 'VerticalAlignment', 'top', ...
                 'HorizontalAlignment', 'left', ...
                 'FontSize', 8, ...
                 'Color', c);

            % % V20Gy: Volume receiving 20Gy (if applicable)
            % [~, ix20] = min(abs(x - 20));
            % v20 = y(ix20);
            % if v20 > 0
            %     text(ax, x(ix20), v20, ' V_{20Gy}', ...
            %          'VerticalAlignment', 'middle', ...
            %          'HorizontalAlignment', 'right', ...
            %          'FontSize', 8, ...
            %          'Color', voiColors(v,:));
            % end
        end
    end

    % Fake black line for source style (legend only)
    hFake = plot(ax, NaN, NaN, ...
        'LineStyle', style, ...
        'Color', [0 0 0], ...
        'LineWidth', lineWidth, ...
        'DisplayName', source);
    sourceLegendHandles(s) = hFake;
end


%% Styling
xlabel(ax, 'Dose [Gy]', 'FontSize', matRad_cfg.gui.fontSize);
ylabel(ax, 'Volume [%]', 'FontSize', matRad_cfg.gui.fontSize);
grid(ax, 'on');
grid(ax,'minor');
box(ax, 'on');

xlim(ax, [0 1.05*maxDose]);
ylim(ax, [0 100]);

set(ax, 'LineWidth', 1, 'FontSize', matRad_cfg.gui.fontSize);

%% Final legend
if plotLegend
    lgd = legend(ax, [voiLegendHandles; sourceLegendHandles], ...
        'Location', 'NorthEast', 'AutoUpdate', 'off');
    lgd.FontSize = matRad_cfg.gui.fontSize;
    lgd.TextColor = matRad_cfg.gui.textColor;
end

hold(ax, 'off');
end
