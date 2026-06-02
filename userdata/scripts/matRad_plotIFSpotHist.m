function [hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHist(ifData, varargin)
% matRad_plotIFSpotHist - Plot stacked bar chart of interface spots per beam
%                         and per energy layer
%
% Syntax:
%   [hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHist(ifData)
%   [hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHist(ifData, 'Name', Value, ...)
%
% Description:
%   Creates a stacked bar chart with one bar per beam and stacked segments
%   corresponding to energy layers (ELs). The height of each segment is the
%   number of spots inside the interface VOI for that beam and energy layer.
%
% Inputs:
%   ifData - struct returned by matRad_collectIFSpots
%
% Name-Value Pairs:
%   'UseInterfaceOnly' - true/false (default: true)
%       If true, counts only ifData.beam(ixBeam).spotTblInterface.
%       If false, counts all spots in ifData.beam(ixBeam).spotTblAll.
%
%   'ShowTotals' - true/false (default: true)
%       If true, annotates the total number of spots above each bar.
%
%   'FigName' - figure name (default: 'Interface spot histogram')
%
%   'BarWidth' - bar width (default: 0.75)
%
%   'SortByTotal' - true/false (default: false)
%       If true, beams are sorted by total number of spots.
%
% Outputs:
%   hFig       - figure handle
%   hAx        - axes handle
%   hBar       - bar handles, one per energy layer
%   summaryTbl - table with beam/energy counts
%
% Reference entry:
% | `N/A` | `matRad_plotIFSpotHist` | Stacked bar chart of interface spots per beam and energy layer | `[hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHist(ifData)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

p = inputParser;
p.addRequired('ifData', @(x) isstruct(x) && isfield(x, 'beam'));
p.addParameter('UseInterfaceOnly', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('ShowTotals', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('FigName', 'Interface spot histogram', @(x) ischar(x) || isstring(x));
p.addParameter('BarWidth', 0.75, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('SortByTotal', false, @(x) islogical(x) || isnumeric(x));
p.parse(ifData, varargin{:});

useInterfaceOnly = logical(p.Results.UseInterfaceOnly);
showTotals       = logical(p.Results.ShowTotals);
figName          = string(p.Results.FigName);
barWidth         = p.Results.BarWidth;
sortByTotal      = logical(p.Results.SortByTotal);

beamStruct = ifData.beam;
nBeams = numel(beamStruct);

% -------------------------------------------------------------------------
% Collect all energy layers across all beams
% -------------------------------------------------------------------------
allE = [];
for ixBeam = 1:nBeams
    if isfield(beamStruct(ixBeam), 'el') && ~isempty(beamStruct(ixBeam).el)
        e = [beamStruct(ixBeam).el.energyMeV];
        allE = [allE; e(:)]; %#ok<AGROW>
    end
end

allE = unique(allE, 'sorted');

if isempty(allE)
    warning('matRad_plotIFSpotHist:NoEnergyLayers', ...
        'No energy layers found in ifData.');
    hFig = figure('Color', 'w', 'Name', figName);
    hAx = axes(hFig);
    hBar = gobjects(0);
    summaryTbl = table();
    title(hAx, 'No energy layers found');
    return;
end

nE = numel(allE);

% -------------------------------------------------------------------------
% Build count matrix: rows = beams, cols = energy layers
% -------------------------------------------------------------------------
counts = zeros(nBeams, nE);
beamTotals = zeros(nBeams, 1);

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

    if isempty(T) || ~istable(T) || ~ismember('energy', T.Properties.VariableNames)
        continue;
    end

    for iE = 1:nE
        counts(ixBeam, iE) = sum(T.energy == allE(iE));
    end

    beamTotals(ixBeam) = sum(counts(ixBeam, :));
end

% -------------------------------------------------------------------------
% Optional sorting by total count
% -------------------------------------------------------------------------
beamIdx = (1:nBeams).';
beamLabels = arrayfun(@(b) sprintf('Beam %d', b), beamIdx, 'UniformOutput', false);

if sortByTotal
    [beamTotals, ord] = sort(beamTotals, 'descend');
    counts = counts(ord, :);
    beamIdx = beamIdx(ord);
    beamLabels = beamLabels(ord);
end

% -------------------------------------------------------------------------
% Build summary table (long format)
% -------------------------------------------------------------------------
beamCol = [];
energyCol = [];
nSpotsCol = [];

for ixBeam = 1:nBeams
    for iE = 1:nE
        beamCol(end+1,1)   = beamIdx(ixBeam); %#ok<AGROW>
        energyCol(end+1,1)  = allE(iE); %#ok<AGROW>
        nSpotsCol(end+1,1)  = counts(ixBeam, iE); %#ok<AGROW>
    end
end

summaryTbl = table(beamCol, energyCol, nSpotsCol, ...
    'VariableNames', {'ixBeam', 'energyMeV', 'nSpots'});

% -------------------------------------------------------------------------
% Plot
% -------------------------------------------------------------------------
hFig = figure('Color', 'w', 'Name', figName);
hAx = axes(hFig);
hold(hAx, 'on');

palette = [ ...
    0.0000 0.4470 0.7410;  % blue
    0.8500 0.3250 0.0980;  % orange
    0.9290 0.6940 0.1250;  % yellow
    0.4940 0.1840 0.5560;  % purple
    0.4660 0.6740 0.1880;  % green
    0.3010 0.7450 0.9330;  % cyan
    0.6350 0.0780 0.1840;  % dark red
    0.2000 0.2000 0.2000;  % dark gray
    0.8000 0.4000 0.7000;  % pinkish
    0.1000 0.6000 0.6000]; % teal

nPalette = size(palette, 1);

x = 1:nBeams;
hBar = bar(hAx, x, counts, barWidth, 'stacked');

for iE = 1:nE
    col = palette(mod(iE-1, nPalette) + 1, :);
    hBar(iE).FaceColor = col;
    hBar(iE).EdgeColor = 'none';
    hBar(iE).DisplayName = sprintf('%g MeV', allE(iE));
end

set(hAx, 'XTick', x, 'XTickLabel', beamLabels);
xlabel(hAx, 'Beam');
ylabel(hAx, 'Number of interface spots');
title(hAx, 'Interface spots per beam and energy layer', 'Interpreter', 'none');
grid(hAx, 'on');
box(hAx, 'on');
legend(hAx, 'show', 'Location', 'eastoutside', 'Interpreter', 'none');

% -------------------------------------------------------------------------
% Annotate totals
% -------------------------------------------------------------------------
if showTotals
    yMax = max(beamTotals);
    yOffset = max(1, round(0.02 * max(1, yMax)));

    for ixBeam = 1:nBeams
        if beamTotals(ixBeam) > 0
            text(hAx, x(ixBeam), beamTotals(ixBeam) + yOffset, sprintf('%d', beamTotals(ixBeam)), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontWeight', 'bold', ...
                'Color', [0.15 0.15 0.15]);
        end
    end
end

end