function [hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHistByBeam(ifData, varargin)
% matRad_plotIFSpotHistByBeam - Plot interface spots per beam as individual
%                               stacked bars, sorted by EL frequency within
%                               each beam
%
% Syntax:
%   [hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHistByBeam(ifData)
%   [hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHistByBeam(ifData, 'Name', Value, ...)
%
% Description:
%   Creates one subplot per beam. Each beam is shown as a single stacked bar
%   whose segments correspond to energy layers (ELs), sorted from most to
%   least common within that beam.
%
%   This is the correct visualization if you want the EL order to differ
%   between beams. A single stacked bar chart cannot have a different stack
%   order per beam.
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
%       If true, annotates the total number of interface spots above each bar.
%
%   'FigName' - figure name (default: 'Interface spot histogram by beam')
%
%   'SortBeamsByTotal' - true/false (default: false)
%       If true, beams are ordered by total number of spots descending.
%
% Outputs:
%   hFig       - figure handle
%   hAx        - axes handles, one per beam
%   hBar       - bar handles, one per beam
%   summaryTbl - table with beam/energy counts
%
% Reference entry:
% | `N/A` | `matRad_plotIFSpotHistByBeam` | One stacked bar per beam, ELs sorted within each beam | `[hFig, hAx, hBar, summaryTbl] = matRad_plotIFSpotHistByBeam(ifData)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

p = inputParser;
p.addRequired('ifData', @(x) isstruct(x) && isfield(x, 'beam'));
p.addParameter('UseInterfaceOnly', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('ShowTotals', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('FigName', 'Interface spot histogram by beam', @(x) ischar(x) || isstring(x));
p.addParameter('SortBeamsByTotal', false, @(x) islogical(x) || isnumeric(x));
p.parse(ifData, varargin{:});

useInterfaceOnly = logical(p.Results.UseInterfaceOnly);
showTotals       = logical(p.Results.ShowTotals);
figName          = string(p.Results.FigName);
sortBeamsByTotal = logical(p.Results.SortBeamsByTotal);

beamStruct = ifData.beam;
nBeams = numel(beamStruct);

% -------------------------------------------------------------------------
% Collect totals and all energy layers
% -------------------------------------------------------------------------
beamTotals = zeros(nBeams, 1);
allE = [];

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

    if istable(T) && ismember('energy', T.Properties.VariableNames) && ~isempty(T)
        beamTotals(ixBeam) = height(T);
        allE = [allE; T.energy(:)]; %#ok<AGROW>
    end
end

allE = unique(allE, 'sorted');

if isempty(allE)
    warning('matRad_plotIFSpotHistByBeam:NoEnergyLayers', ...
        'No energy layers found in ifData.');
    hFig = figure('Color', 'w', 'Name', figName);
    hAx = axes(hFig);
    hBar = gobjects(0);
    summaryTbl = table();
    title(hAx, 'No energy layers found');
    return;
end

% Optional beam sorting
beamOrder = (1:nBeams).';
if sortBeamsByTotal
    [~, ord] = sort(beamTotals, 'descend');
    beamOrder = beamOrder(ord);
end

% -------------------------------------------------------------------------
% Build summary table (long format)
% -------------------------------------------------------------------------
beamCol = [];
energyCol = [];
nSpotsCol = [];

for ii = 1:nBeams
    ixBeam = beamOrder(ii);

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

    for iE = 1:numel(allE)
        beamCol(end+1,1)   = ixBeam; %#ok<AGROW>
        energyCol(end+1,1) = allE(iE); %#ok<AGROW>
        nSpotsCol(end+1,1) = sum(T.energy == allE(iE)); %#ok<AGROW>
    end
end

summaryTbl = table(beamCol, energyCol, nSpotsCol, ...
    'VariableNames', {'ixBeam', 'energyMeV', 'nSpots'});

% -------------------------------------------------------------------------
% Plot: one subplot per beam
% -------------------------------------------------------------------------
nRows = nBeams;
hFig = figure('Color', 'w', 'Name', figName);
tiledlayout(hFig, nRows, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

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
hAx = gobjects(nBeams, 1);
hBar = gobjects(nBeams, 1);

for ii = 1:nBeams
    ixBeam = beamOrder(ii);

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

    hAx(ii) = nexttile;
    hold(hAx(ii), 'on');

    if isempty(T) || ~istable(T) || ~ismember('energy', T.Properties.VariableNames)
        title(hAx(ii), sprintf('Beam %d: no spots', ixBeam), 'Interpreter', 'none');
        axis(hAx(ii), 'off');
        continue;
    end

    % Counts per energy for this beam
    counts = zeros(1, numel(allE));
    for iE = 1:numel(allE)
        counts(iE) = sum(T.energy == allE(iE));
    end

    % Sort ELs from most to least common within this beam
    [countsSorted, ord] = sort(counts, 'descend');
    energiesSorted = allE(ord);

    % Keep only nonzero layers for cleaner plots
    keep = countsSorted > 0;
    countsSorted = countsSorted(keep);
    energiesSorted = energiesSorted(keep);

    if isempty(countsSorted)
        title(hAx(ii), sprintf('Beam %d: no interface spots', ixBeam), 'Interpreter', 'none');
        axis(hAx(ii), 'off');
        continue;
    end

    % Single stacked bar for this beam
    hb = bar(hAx(ii), 1, countsSorted, 0.6, 'stacked');
    hBar(ii) = hb(1);

    for iE = 1:numel(countsSorted)
        col = palette(mod(iE-1, nPalette) + 1, :);
        hb(iE).FaceColor = col;
        hb(iE).EdgeColor = 'none';
        hb(iE).DisplayName = sprintf('%g MeV', energiesSorted(iE));
    end

    ylabel(hAx(ii), 'Spots');
    title(hAx(ii), sprintf('Beam %d | total = %d', ixBeam, sum(countsSorted)), 'Interpreter', 'none');
    grid(hAx(ii), 'on');
    box(hAx(ii), 'on');
    xlim(hAx(ii), [0.5 1.5]);
    set(hAx(ii), 'XTick', 1, 'XTickLabel', {''});

    if showTotals
        yMax = sum(countsSorted);
        text(hAx(ii), 1, yMax + max(1, round(0.02 * max(1, yMax))), sprintf('%d', yMax), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontWeight', 'bold', ...
            'Color', [0.15 0.15 0.15]);
    end

    % Legend only on first subplot to avoid clutter
    if ii == 1
        legend(hAx(ii), 'show', 'Location', 'eastoutside', 'Interpreter', 'none');
    end
end

xlabel(hAx(end), 'Beam');

sgtitle(hFig, 'Interface spots per beam, with ELs sorted within each beam', 'Interpreter', 'none');

end