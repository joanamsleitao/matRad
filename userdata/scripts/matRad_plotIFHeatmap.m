function [hFig, hAx, summaryTbl, counts] = matRad_plotIFHeatmap(ifData, varargin)
% matRad_plotIFHeatmap - Plot a heatmap of interface spot counts per beam
%                        and energy layer
%
% Syntax:
%   [hFig, hAx, summaryTbl, counts] = matRad_plotIFHeatmap(ifData)
%   [hFig, hAx, summaryTbl, counts] = matRad_plotIFHeatmap(ifData, 'Name', Value, ...)
%
% Description:
%   Creates a heatmap with:
%     - rows   = beams
%     - columns= energy layers
%     - values = number of interface spots
%
%   This is intended as a compact overview of the output from
%   matRad_collectIFSpots.
%
% Inputs:
%   ifData - struct returned by matRad_collectIFSpots
%
% Name-Value Pairs:
%   'UseInterfaceOnly' - true/false (default: true)
%       If true, counts only ifData.beam(ixBeam).spotTblInterface.
%       If false, counts all spots in ifData.beam(ixBeam).spotTblAll.
%
%   'SortBeamsByTotal' - true/false (default: false)
%       If true, beams are sorted by total number of selected spots.
%
%   'SortEnergiesByTotal' - true/false (default: false)
%       If true, energy layers are sorted by total count across beams.
%
%   'ShowValues' - true/false (default: true)
%       If true, the numeric counts are written into each heatmap cell.
%
%   'GantryAngles' - numeric vector (default: [])
%       Gantry angles per beam, e.g. [stf(:).gantryAngle].
%       If provided, y-tick labels are shown as:
%           Beam N (gantry XXX.X°)
%
%   'FigName' - figure name (default: 'Interface spot heatmap')
%
%   'ColormapName' - colormap name (default: 'turbo')
%
% Outputs:
%   hFig       - figure handle
%   hAx        - axes handle
%   summaryTbl - long-format table with beam/energy/count entries
%   counts     - numeric matrix [nBeams x nEnergies]
%
% Reference entry:
% | `N/A` | `matRad_plotIFHeatmap` | Heatmap of interface spot counts per beam and energy layer | `[hFig, hAx, summaryTbl, counts] = matRad_plotIFHeatmap(ifData)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

p = inputParser;
p.addRequired('ifData', @(x) isstruct(x) && isfield(x, 'beam'));
p.addParameter('UseInterfaceOnly', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('SortBeamsByTotal', false, @(x) islogical(x) || isnumeric(x));
p.addParameter('SortEnergiesByTotal', false, @(x) islogical(x) || isnumeric(x));
p.addParameter('ShowValues', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('GantryAngles', [], @(x) isnumeric(x) || isempty(x));
p.addParameter('FigName', 'Interface spot heatmap', @(x) ischar(x) || isstring(x));
p.addParameter('ColormapName', 'turbo', @(x) ischar(x) || isstring(x));
p.parse(ifData, varargin{:});

useInterfaceOnly    = logical(p.Results.UseInterfaceOnly);
sortBeamsByTotal    = logical(p.Results.SortBeamsByTotal);
sortEnergiesByTotal = logical(p.Results.SortEnergiesByTotal);
showValues          = logical(p.Results.ShowValues);
gantryAngles        = p.Results.GantryAngles;
figName             = string(p.Results.FigName);
cmapName            = string(p.Results.ColormapName);

beamStruct = ifData.beam;
nBeams = numel(beamStruct);

if ~isempty(gantryAngles)
    gantryAngles = gantryAngles(:);
    if numel(gantryAngles) ~= nBeams
        warning('matRad_plotIFHeatmap:GantryAngleSizeMismatch', ...
            'GantryAngles has %d entries but ifData.beam has %d beams. Gantry angles will be ignored.', ...
            numel(gantryAngles), nBeams);
        gantryAngles = [];
    end
end

% -------------------------------------------------------------------------
% Gather all energy layers and build counts
% -------------------------------------------------------------------------
allE = [];
beamTotals = zeros(nBeams,1);

for ixBeam = 1:nBeams
    if useInterfaceOnly
        if isfield(beamStruct(ixBeam), 'spotTblInterface') && ~isempty(beamStruct(ixBeam).spotTblInterface)
            T = beamStruct(ixBeam).spotTblInterface;
        else
            T = table();
        end
    else
        if isfield(beamStruct(ixBeam), 'spotTblAll') && ~isempty(beamStruct(ixBeam).spotTblAll)
            T = beamStruct(ixBeam).spotTblAll;
        else
            T = table();
        end
    end

    if istable(T) && ~isempty(T) && ismember('energy', T.Properties.VariableNames)
        allE = [allE; T.energy(:)]; %#ok<AGROW>
        beamTotals(ixBeam) = height(T);
    end
end

allE = unique(allE(:), 'sorted');
nE = numel(allE);

if isempty(allE)
    warning('matRad_plotIFHeatmap:NoEnergyLayers', 'No energy layers found in ifData.');
    hFig = figure('Color', 'w', 'Name', figName);
    hAx = axes(hFig);
    set(hAx, 'Color', 'w');
    summaryTbl = table();
    counts = zeros(nBeams, 0);
    title(hAx, 'No energy layers found');
    return;
end

counts = zeros(nBeams, nE);

for ixBeam = 1:nBeams
    if useInterfaceOnly
        if isfield(beamStruct(ixBeam), 'spotTblInterface') && ~isempty(beamStruct(ixBeam).spotTblInterface)
            T = beamStruct(ixBeam).spotTblInterface;
        else
            T = table();
        end
    else
        if isfield(beamStruct(ixBeam), 'spotTblAll') && ~isempty(beamStruct(ixBeam).spotTblAll)
            T = beamStruct(ixBeam).spotTblAll;
        else
            T = table();
        end
    end

    if ~istable(T) || isempty(T) || ~ismember('energy', T.Properties.VariableNames)
        continue;
    end

    for iE = 1:nE
        counts(ixBeam, iE) = sum(T.energy == allE(iE));
    end
end

% -------------------------------------------------------------------------
% Optional sorting
% -------------------------------------------------------------------------
beamOrder = (1:nBeams).';
energyOrder = (1:nE).';

if sortBeamsByTotal
    [~, beamOrder] = sort(sum(counts, 2), 'descend');
end

if sortEnergiesByTotal
    [~, energyOrder] = sort(sum(counts, 1), 'descend');
end

countsPlot = counts(beamOrder, energyOrder);

% Beam labels with optional gantry angles in the y-ticks
beamLabels = cell(numel(beamOrder), 1);
for ii = 1:numel(beamOrder)
    ixBeam = beamOrder(ii);

    if isempty(gantryAngles)
        beamLabels{ii} = sprintf('Beam %d', ixBeam);
    else
        beamLabels{ii} = sprintf('Beam %d (gantry %.1f°)', ixBeam, gantryAngles(ixBeam));
        % beamLabels{ii} = sprintf('Beam %d\n(gantry %.1f°)', ixBeam, gantryAngles(ixBeam));
    end
end

% EL labels rounded to 1 decimal
energyVals   = round(allE(energyOrder), 1);
energyLabels = arrayfun(@(e) sprintf('%.1f MeV', e), energyVals, 'UniformOutput', false);

% -------------------------------------------------------------------------
% Build summary table in long format
% -------------------------------------------------------------------------
beamCol = [];
energyCol = [];
nSpotsCol = [];

for iB = 1:numel(beamOrder)
    for iE = 1:numel(energyOrder)
        beamCol(end+1,1)   = beamOrder(iB); %#ok<AGROW>
        energyCol(end+1,1)  = allE(energyOrder(iE)); %#ok<AGROW>
        nSpotsCol(end+1,1)  = countsPlot(iB, iE); %#ok<AGROW>
    end
end

summaryTbl = table(beamCol, energyCol, nSpotsCol, ...
    'VariableNames', {'ixBeam', 'energyMeV', 'nSpots'});

% -------------------------------------------------------------------------
% Plot heatmap
% -------------------------------------------------------------------------
hFig = figure('Color', 'w', 'Name', figName);
hAx = axes(hFig);
set(hAx, 'Color', 'w');

imagesc(hAx, countsPlot);
axis(hAx, 'tight');
set(hAx, 'YDir', 'normal');
hAx.XColor = 'k';
hAx.YColor = 'k';

colormap(hAx, cmapName);
cb = colorbar(hAx);
cb.Color = 'k';
cb.Label.String = 'Number of interface spots';

xlabel(hAx, 'Energy layer');
ylabel(hAx, 'Beam');
title(hAx, 'Interface spot heatmap: beams vs energy layers', ...
    'Color', 'k', 'Interpreter', 'none');

set(hAx, ...
    'XTick', 1:numel(energyLabels), ...
    'XTickLabel', energyLabels, ...
    'YTick', 1:numel(beamLabels), ...
    'YTickLabel', beamLabels);

xtickangle(hAx, 45);
box(hAx, 'on');
hold(hAx, 'on');

% -------------------------------------------------------------------------
% Add visible grid lines between cells
% -------------------------------------------------------------------------
for x = 0.5:1:(nE + 0.5)
    xline(hAx, x, '-', ...
        'Color', [0.85 0.85 0.85], ...
        'LineWidth', 0.75, ...
        'HandleVisibility', 'off');
end

for y = 0.5:1:(nBeams + 0.5)
    yline(hAx, y, '-', ...
        'Color', [0.85 0.85 0.85], ...
        'LineWidth', 0.75, ...
        'HandleVisibility', 'off');
end

% -------------------------------------------------------------------------
% Show numeric values in cells
% -------------------------------------------------------------------------
if showValues
    maxVal = max(countsPlot(:));
    if maxVal == 0
        textColor = [0.2 0.2 0.2];
    else
        textColor = 'w';
    end

    for iB = 1:size(countsPlot,1)
        for iE = 1:size(countsPlot,2)
            val = countsPlot(iB, iE);
            if val > 0
                if maxVal > 0 && val < 0.5 * maxVal
                    tColor = [0.1 0.1 0.1];
                else
                    tColor = textColor;
                end
                text(hAx, iE, iB, sprintf('%d', val), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontWeight', 'bold', ...
                    'Color', tColor);
            end
        end
    end
end

end