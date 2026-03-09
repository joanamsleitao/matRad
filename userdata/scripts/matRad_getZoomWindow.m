function [xlimVals, ylimVals] = matRad_getZoomWindow(xCenter, yCenter, ct, zoomFactor)
% matRad_getZoomWindow Computes x/y limits centered on a point for zooming
%
% INPUTS:
%   - xCenter, yCenter: Coordinates in cube space (column, row)
%   - ct: matRad CT struct (to get size)
%   - zoomWidth: (optional) Half-width of zoom box in pixels (default: 20)
%
% OUTPUTS:
%   - xlimVals: [xmin, xmax]
%   - ylimVals: [ymin, ymax]
%
%%
ctSize = ct.cubeDim;  % [rows, cols, slices]
rows = ctSize(1);
cols = ctSize(2);

if nargin < 4 || zoomFactor == 0
    zoomWidth = 20;
else
    zoomWidth = rows*(1 - zoomFactor);
end

xmin = max(1, round(xCenter - zoomWidth));
xmax = min(cols, round(xCenter + zoomWidth));

ymin = max(1, round(yCenter - zoomWidth));
ymax = min(rows, round(yCenter + zoomWidth));

xlimVals = [xmin, xmax];
ylimVals = [ymin, ymax];

    % if xlimVals(1) ~= xlimVals(2) && ylimVals(1) ~= ylimVals(2)
    %     set(axesHandle, 'XLim', xlimVals, 'YLim', ylimVals);
    % else
    %     xlimVals = [xlimVals(1)-30, xlimVals(2)+30];
    %     ylimVals = [ylimVals(1)-30, ylimVals(2)+30];
    %     set(axesHandle, 'XLim', xlimVals, 'YLim', ylimVals);
    % end
end
