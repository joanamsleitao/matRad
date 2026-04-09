function [cmap, ticks, tickLabels] = matRad_cmapJetBin(n, binSize)
% matRad_cmapJetBin - Generate a custom binned jet colormap with colorbar ticks
%
% Syntax:
%   cmap = matRad_cmapJetBin(n)
%   [cmap, ticks, tickLabels] = matRad_cmapJetBin(n)
%   [cmap, ticks, tickLabels] = matRad_cmapJetBin(n, binSize)
%
% Description:
%   Generates a jet-based colormap with four zones:
%     Zone 1 (rows 1..4):    flat color = 2nd entry of jet(n)
%     Zone 2 (rows 5..17):   binned jet, each bin uses its middle-row color
%     Zone 3 (rows 18..21):  flat color = [1.0 0.4286 0]
%     Zone 4 (rows 22..n):   flat color = [0.66 0 0]
%
%   The function also returns colorbar tick positions and tick labels that
%   match the grouped structure of the colormap.
%
% Inputs:
%   n       - Number of colors in the output colormap
%   binSize - (optional) Number of rows per bin in zone 2 (default: 3)
%
% Outputs:
%   cmap       - [n x 3] colormap matrix
%   ticks      - Tick positions for colorbar
%   tickLabels - Cell array of tick labels
%
% Example:
%   [cmap, ticks, tickLabels] = matRad_cmapJetBin(25, 3);
%   colormap(cmap);
%   cb = colorbar;
%   cb.Ticks = ticks;
%   cb.TickLabels = tickLabels;
%
% Reference list entry:
%   | - | `matRad_cmapJetBin` | Generate a custom binned jet colormap and matching colorbar ticks | `[cmap, ticks, tickLabels] = matRad_cmapJetBin(n, binSize)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

    if nargin < 2
        binSize = 3;
    end

    % Zone boundaries
    headEnd   = 4;    % rows 1..4
    binStart  = 5;    % rows 5..17
    binEndMax = 18;
    midStart  = 19;   % rows 18..21
    midEnd    = 21;
    tailStart = 22;   % rows 22..n

    % Base colormap
    baseJet = jet(n);

    % Pre-allocate output
    cmap = zeros(n, 3);

    % Zone 1
    cmap(1:headEnd, :) = repmat(baseJet(2, :), headEnd, 1);

    % Zone 2
    i = binStart;
    while i <= binEndMax
        thisBinEnd = min(i + binSize - 1, binEndMax);
        binMid = round((i + thisBinEnd) / 2);
        cmap(i:thisBinEnd, :) = repmat(baseJet(binMid, :), thisBinEnd - i + 1, 1);
        i = i + binSize;
    end

    % Zone 3
    cmap(midStart:midEnd, :) = repmat([1.0 0.4286 0], midEnd - midStart + 1, 1);

    % Zone 4
    if tailStart <= n
        cmap(tailStart:n, :) = repmat([0.66 0 0], n - tailStart + 1, 1);
    end

    cmap = round(cmap(:, :),1);

% Build ticks at rows where the color changes
    ticks = [1, headEnd];

    i = headEnd+binSize;
    while i <= binEndMax
        ticks(end+1) = i; %#ok<AGROW>
        i = i + binSize;
    end

    ticks = [ticks, binEndMax, midEnd];

    if ticks(end) ~= n
        ticks = [ticks, n];
    end

    ticks = unique(ticks, 'stable');

    % Tick labels
    tickLabels = arrayfun(@num2str, ticks, 'UniformOutput', false);

end