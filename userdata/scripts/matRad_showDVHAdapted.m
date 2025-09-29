function fig = matRad_showDVHAdapted(dvhInput, cst, varargin)
% MATRAD_SHOWDVH - Plot DVHs from single or multiple sources for each VOI
%
% Syntax:
%   matRad_showDVH(dvh, cst)
%   matRad_showDVH(dvhStruct, cst, ...)
%
% Inputs:
%   dvhInput     - Either a struct array of DVH data, or a struct of structs (dvh.source.voi)
%   cst          - matRad CST cell array
%
% Optional Name-Value Pairs:
%   'axesHandle'     - Axes to plot into (default: gca)
%   'LineWidth'      - Width of DVH lines (default: 2.0)
%   'plotLegend'     - true/false to show legend (default: true)
%   'annotateMetrics' - true/false to annotate D98/D2 on graph (default: false)
%
% Output:
%   A DVH plot on the specified axes
%

%% Parse input
p = inputParser;
p.addRequired('dvhInput', @isstruct);
p.addRequired('cst', @iscell);
p.addParameter('axesHandle', [], @(x) isempty(x) || isgraphics(x, 'axes'));
p.addParameter('LineWidth', 2.0, @(x) isnumeric(x) && x > 0);
p.addParameter('plotLegend', true, @(x) islogical(x) && isscalar(x));
p.addParameter('annotateMetrics', false, @(x) islogical(x) && isscalar(x));
p.parse(dvhInput, cst, varargin{:});

ax = gca;
if isempty(ax)
    fig = figure('Color','w');
    ax = gca;
else
    fig = gcf;
end
lineWidth = p.Results.LineWidth;
plotLegend = p.Results.plotLegend;
annotateMetrics = p.Results.annotateMetrics;

matRad_cfg = MatRad_Config.instance();
hold(ax, 'on');

%% Determine if multi-source DVH
% Determine if input is a multi-source DVH (dvh.source.voi)
isMultiSource = isstruct(dvhInput) && ...
    ~isfield(dvhInput, 'doseGrid') && ...
    all(structfun(@(s) isstruct(s) && isfield(s, 'doseGrid'), dvhInput));

if isMultiSource
    sourceNames = fieldnames(dvhInput);
    voiNames = {dvhInput.(sourceNames{1}).name}.';
    numSources = numel(sourceNames);
    dvhArray = dvhInput;
else
    sourceNames = {'Primary'};
    dvhArray.Primary = dvhInput;
    voiNames = {dvhInput.name}.';
    numSources = 1;
end
numVois = numel(voiNames);

% Generate line styles for sources
lineStyles = {'-', '--', ':', '-.'};
assert(numSources <= numel(lineStyles), 'Too many sources for line styles.');

% Get colors from CST
visibleIx = cellfun(@(c) c.Visible == 1, cst(:,5));
visibleNames = cst(visibleIx,2);
visibleColors = cell2mat(cellfun(@(c) c.visibleColor, cst(visibleIx,5), 'UniformOutput', false));
[~, voiColorIdx] = ismember(voiNames, visibleNames);
voiColors = visibleColors(voiColorIdx,:);

%% Legend handles
voiLegendHandles = gobjects(numVois,1);
sourceLegendHandles = gobjects(numSources,1);

maxDose = 0;
maxVol = 0;

for s = 1:numSources
    source = sourceNames{s};
    style = lineStyles{s};

    for v = 1:numVois
        voi = voiNames{v};
        dvh = dvhArray.(source);
        dvh = dvh(v);
        if isempty(dvh.volumePoints)
            continue;
        end

        x = dvh.doseGrid;
        y = dvh.volumePoints;
        maxDose = max(maxDose, max(x));
        maxVol = max(maxVol, max(y));

        % Plot VOI line with its color and source style
        h = plot(ax, x, y, ...
            'LineStyle', style, ...
            'Color', voiColors(v,:), ...
            'LineWidth', lineWidth);

        % Only label the first source's VOIs
        if s == 1
            h.DisplayName = string(voi);
            voiLegendHandles(v) = h;
        else
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        end

        % Optional: annotate D98 and D2
        if annotateMetrics && s == 1
            [~, ix98] = min(abs(y - 98));
            text(ax, x(ix98), y(ix98), ' D_{98}', ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 8, ...
                'Color', voiColors(v,:));

            [~, ix2] = min(abs(y - 2));
            text(ax, x(ix2), y(ix2), ' D_{2}', ...
                'VerticalAlignment', 'top', ...
                'HorizontalAlignment', 'left', ...
                'FontSize', 8, ...
                'Color', voiColors(v,:));
        end
    end

    % Fake black line for source legend
    hFake = plot(ax, NaN, NaN, ...
        'LineStyle', style, ...
        'Color', [0 0 0], ...
        'LineWidth', lineWidth, ...
        'DisplayName', source);
    sourceLegendHandles(s) = hFake;
end

%% Final plot styling
xlabel(ax, 'Dose [Gy]', 'FontSize', matRad_cfg.gui.fontSize);
ylabel(ax, 'Volume [%]', 'FontSize', matRad_cfg.gui.fontSize);
grid(ax, 'on'); grid(ax, 'minor');
box(ax, 'on');
xlim(ax, [0 1.05*maxDose]);
ylim(ax, [0 1.1*maxVol]);
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