function matRad_addDVHBand(ax, dvhLow, dvhHigh, cst, voiIdxList, varargin)
% matRad_addDVHBand - Add shaded uncertainty band matching VOI colors
%
% Syntax:
%   matRad_addDVHBand(ax, dvhLow, dvhHigh, cst, voiIdxList)
%   matRad_addDVHBand(..., 'alpha', 0.15)
%
% Inputs:
%   ax          - Axes handle
%   dvhLow      - DVH struct array (lower bound)
%   dvhHigh     - DVH struct array (upper bound)
%   cst         - matRad CST cell array (for color lookup)
%   voiIdxList  - Vector of VOI indices to shade
%
% Name-Value Parameters:
%   'alpha' - Transparency 0-1 (default: 0.12)
%   'color' - Optional override RGB. If provided, all bands use this color.

    p = inputParser;
    p.addParameter('color', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==3));
    p.addParameter('alpha', 0.12, @(x) isnumeric(x) && isscalar(x));
    p.parse(varargin{:});
    
    overrideCol = p.Results.color;
    a           = p.Results.alpha;

    hold(ax, 'on');

    for ii = 1:numel(voiIdxList)
        v = voiIdxList(ii);

        % Safety checks
        if v > numel(dvhLow) || v > numel(dvhHigh) || v > size(cst,1)
            continue;
        end

        % Determine color: use override if provided, else pull from CST
        if ~isempty(overrideCol)
            col = overrideCol;
        else
            try
                col = cst{v, 5}.visibleColor;
            catch
                col = [0.5 0.5 0.5]; % Fallback gray if color missing
            end
        end

        [xL, yL] = local_dvhXY(dvhLow(v));
        [xH, yH] = local_dvhXY(dvhHigh(v));

        % Interpolate to common grid if needed
        if ~isequal(xL, xH)
            yH = interp1(xH, yH, xL, 'linear', 'extrap');
        end

        x  = xL(:);
        y1 = yL(:);
        y2 = yH(:);

        % Create filled polygon
        X = [x; flipud(x)];
        Y = [y1; flipud(y2)];

        fill(ax, X, Y, col, ...
            'FaceAlpha', a, ...
            'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end
    
    hold(ax, 'off');
end

function [x, y] = local_dvhXY(dvh)
    if isfield(dvh, 'doseGrid'), x = dvh.doseGrid;
    elseif isfield(dvh, 'dose'), x = dvh.dose;
    else, error('DVH struct missing dose grid field'); end

    if isfield(dvh, 'volumePoints'), y = dvh.volumePoints;
    elseif isfield(dvh, 'volume'), y = dvh.volume;
    else, error('DVH struct missing volume field'); end
end