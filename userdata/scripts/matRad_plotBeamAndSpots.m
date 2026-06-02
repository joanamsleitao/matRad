function hFig = matRad_plotBeamAndSpots(ct, cst, stf, doseCube, varargin)
% matRad_plotBeamAndSpots - Left: overview of all beams; Right: per-beam spot plots
%
% Syntax:
%   hFig = matRad_plotBeamAndSpots(ct, cst, stf, doseCube)
%   hFig = matRad_plotBeamAndSpots(ct, cst, stf, doseCube, 'beams', [1 3 5], 'tilesPerRow', 3, ...)
%
% Description:
%   Creates a figure using tiledlayout with two columns:
%     - Left:  one large tile for the overview plot of all beams (color-coded labels).
%     - Right: tiled subplots, one per beam, calling matRad_plotBeamSpots
%              to draw spots for that beam. Each tile title color matches
%              the corresponding label color in the overview.
%
% Inputs:
%   ct         - matRad CT struct
%   cst        - matRad CST (cell array)
%   stf        - matRad STF struct (array of beams)
%   doseCube   - (optional) dose cube to use as background in overview/tiles
%
% Name-Value Options:
%   'beams'            - vector of beam indices to plot (default: all beams)
%   'tilesPerRow'      - number of tiles per row in the right panel (default: 3)
%   'mode'             - 'all' (default) | 'midOnly' (passed to matRad_plotBeamSpots)
%   'showBgOverview'   - true/false (default true) - show background for overview
%   'showBgTiles'      - true/false (default false) - show background per tile
%   'markerSize'       - base marker size forwarded to matRad_plotBeamSpots (default 6)
%   'tileTitleFontSize' - font size for tile titles (default 10)
%   'figureName'       - string for figure name (default: 'Beam Overview and Spots')
%
% Output:
%   hFig - handle to the created figure
%
% Example:
%   hFig = matRad_plotBeamAndSpots(ct, cst, stf, doseCube, 'tilesPerRow',4, 'mode','midOnly');
%
% Reference entry:
% | `matRad_plotBeamAndSpots` | `matRad_plotBeamAndSpots` | Create overview of beams (left) and per-beam spot plots (right) with matching colors | `hFig = matRad_plotBeamAndSpots(ct,cst,stf,doseCube,'tilesPerRow',3)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% --- Parse inputs ---
p = inputParser;
addRequired(p,'ct');
addRequired(p,'cst');
addRequired(p,'stf');
addOptional(p,'doseCube', [], @(x) isempty(x) || isnumeric(x));
addParameter(p,'beams', [], @(x) isempty(x) || (isnumeric(x) && all(x==floor(x))));
addParameter(p,'tilesPerRow', 3, @(x) isnumeric(x) && isscalar(x) && x>=1);
addParameter(p,'mode', 'midOnly', @(s) any(strcmp(s,{'all','midOnly'})));
addParameter(p,'showBgOverview', true, @islogical);
addParameter(p,'showBgTiles', false, @islogical);
addParameter(p,'markerSize', 6, @isnumeric);
addParameter(p,'tileTitleFontSize', 10, @isnumeric);
addParameter(p,'figureName', 'Beam Overview and Spots', @ischar);
parse(p, ct, cst, stf, doseCube, varargin{:});

doseCube = p.Results.doseCube;
beamList = p.Results.beams;
tilesPerRow = p.Results.tilesPerRow;
mode = p.Results.mode;
showBgOverview = p.Results.showBgOverview;
showBgTiles = p.Results.showBgTiles;
markerSize = p.Results.markerSize;
tileTitleFontSize = p.Results.tileTitleFontSize;
figureName = p.Results.figureName;

% validate stf
nTotalBeams = numel(stf);
if isempty(beamList)
    beamList = 1:nTotalBeams;
end
beamList = beamList(beamList>=1 & beamList<=nTotalBeams);
nBeams = numel(beamList);
if nBeams == 0
    error('No valid beams selected.');
end

% colors: one per beam (consistent)
cmap = lines(nTotalBeams);
beamColors = cmap(1:nTotalBeams, :);

% --- Compute number of rows needed for tiles ---
trows = ceil(nBeams / tilesPerRow);

% --- Create figure and main tiledlayout ---
hFig = figure('Name', figureName, 'Color', 'w', 'Units','normalized', 'OuterPosition', [0 0 1 1]);

% Main layout: 2 columns
% - Column 1: 1 wide tile for overview
% - Column 2: trows rows, tilesPerRow columns for beam tiles
mainLayout = tiledlayout(hFig, trows, 1 + tilesPerRow, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Left Tile: Overview Plot ---
axOv = nexttile(mainLayout, [trows, 1]); % Span all rows in column 1
hold(axOv,'on');

if showBgOverview
    try
        % try with axes argument
        try
            matRad_showSliceFast(axOv, ct, cst, doseCube);
        catch
            matRad_showSliceFast(ct, cst, doseCube);
        end
    catch
        % ignore if fails
    end
end

% compute representative XY for each selected beam
repXY = nan(nBeams, 2);
for k = 1:nBeams
    bi = beamList(k);
    try
        repXY(k, :) = getRepresentativeBeamXY(stf(bi));
    catch
        repXY(k, :) = [NaN NaN];
    end
end

% plot markers and labels in overview
for k = 1:nBeams
    bi = beamList(k);
    col = beamColors(bi, :);
    xy = repXY(k,:);
    if any(isnan(xy))
        continue;
    end
    plot(axOv, xy(1), xy(2), 'o', 'MarkerEdgeColor','k', 'MarkerFaceColor', col, ...
        'MarkerSize', markerSize+4, 'LineWidth',1.2);
    text(axOv, xy(1)+1, xy(2)+1, sprintf('Beam %d', bi), 'Color', col, ...
        'FontWeight','bold','FontSize', 10, 'Interpreter','none');
end

title(axOv, 'Overview: Beam Positions', 'FontWeight','bold');
axis(axOv,'equal');
hold(axOv,'off');

% --- Right Tiles: Per-Beam Plots ---
for k = 1:nBeams
    bi = beamList(k);
    % compute tile linear index in the right panel grid
    row = mod(k-1, trows) + 1; % 1-based row index
    col = floor((k-1)/trows) + 1; % 0-based column index within right panel
    % Adjust column index to account for the overview column (add 1)
    tileIndex = sub2ind([trows, 1 + tilesPerRow], row, col + 1);
    
    ax = nexttile(mainLayout, tileIndex);
    
    % call matRad_plotBeamSpots on this axes
    try
        % use showBackground according to option
        showBgThis = showBgTiles;
        % pass custom colors so beamColor is consistent
        matRad_plotBeamSpots(ax, ct, cst, stf, bi, doseCube, ...
            'mode', mode, 'showBackground', showBgThis, 'markerSize', markerSize, 'colors', beamColors);
    catch ME
        warning('Could not call matRad_plotBeamSpots for beam %d: %s', bi, ME.message);
        % still set title
    end
    
    % set tile title colored to match overview label
    col = beamColors(bi, :);
    tStr = sprintf('Beam %d', bi);
    title(ax, tStr, 'Color', col, 'FontWeight','bold', 'FontSize', tileTitleFontSize);
    axis(ax,'equal');
end

% --- Fill unused tiles with empty axes to maintain layout ---
nTotalRightTiles = trows * tilesPerRow;
if nTotalRightTiles > nBeams
    for k = nBeams+1:nTotalRightTiles
        row = mod(k-1, trows) + 1;
        col = floor((k-1)/trows) + 1;
        tileIndex = sub2ind([trows, 1 + tilesPerRow], row, col + 1);
        axEmpty = nexttile(mainLayout, tileIndex);
        axis(axEmpty,'off');
    end
end

end

% -----------------------
% Helper: compute representative XY for a beam
% tries middle spots of middle rays and falls back to median of available spots
% -----------------------
function XY = getRepresentativeBeamXY(beam)
% collect candidate positions from rays (middle spot per ray)
ptsAll = [];
if isfield(beam, 'ray') && ~isempty(beam.ray)
    for r = 1:numel(beam.ray)
        ray = beam.ray(r);
        % try fields in order
        candFields = {'spotsInfoSiddon','spotsInfoGeo','spotsInfo','spots'};
        found = false;
        for f = 1:numel(candFields)
            nm = candFields{f};
            if isfield(ray, nm) && ~isempty(ray.(nm))
                sInfo = ray.(nm);
                % support struct-array or numeric
                if isnumeric(sInfo)
                    M = ensureNumericMatrix(sInfo);
                    if ~isempty(M)
                        nSp = size(M,1);
                        mid = max(1, round((nSp+1)/2));
                        ptsAll = [ptsAll; M(mid,1:2)]; %#ok<AGROW>
                        found = true;
                        break;
                    end
                elseif isstruct(sInfo)
                    % take first available spotCube/spotPos
                    got = false;
                    for si = 1:numel(sInfo)
                        entry = sInfo(si);
                        possible = {'spotCube','spotPos','pos','xyz','point'};
                        for pf = 1:numel(possible)
                            fld = possible{pf};
                            if isfield(entry, fld) && ~isempty(entry.(fld))
                                M = ensureNumericMatrix(entry.(fld));
                                if ~isempty(M)
                                    ptsAll = [ptsAll; M(1,1:2)]; %#ok<AGROW>
                                    got = true;
                                    break;
                                end
                            end
                        end
                        if got
                            break;
                        end
                    end
                    if got
                        found = true;
                        break;
                    end
                end
            end
        end
        if ~found
            % fallback: if ray has a spotCube directly
            if isfield(ray,'spotCube') && ~isempty(ray.spotCube)
                M = ensureNumericMatrix(ray.spotCube);
                if ~isempty(M)
                    ptsAll = [ptsAll; M(1,1:2)]; %#ok<AGROW>
                end
            end
        end
    end
end

if isempty(ptsAll)
    XY = [NaN NaN];
else
    % use median to avoid outliers
    XY = median(ptsAll, 1);
end
end

function M = ensureNumericMatrix(x)
% convert various formats to Nx2/3 numeric matrix
M = [];
if isempty(x)
    return;
end
if isnumeric(x)
    if isvector(x)
        M = reshape(x, 1, numel(x));
    else
        M = x;
    end
    return;
end
if isstruct(x)
    % attempt to extract numeric triplets from fields
    fields = fieldnames(x);
    vals = [];
    for i=1:numel(fields)
        v = x.(fields{i});
        if isnumeric(v) && isscalar(v)
            vals = [vals, v]; %#ok<AGROW>
        end
    end
    if ~isempty(vals)
        M = reshape(vals, 1, numel(vals));
    end
    return;
end
end