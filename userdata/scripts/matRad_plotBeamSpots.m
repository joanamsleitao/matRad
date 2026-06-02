function hOut = matRad_plotBeamSpots(ax, ct, cst, stf, iBeam, doseCube, varargin)
% matRad_plotBeamSpots - Plot all spots (or representative spots) for a single beam
%                        and highlight first/middle/last rays
%
% Syntax:
%   hOut = matRad_plotBeamSpots(ax, ct, cst, stf, iBeam)
%   hOut = matRad_plotBeamSpots(ax, ct, cst, stf, iBeam, doseCube)
%   hOut = matRad_plotBeamSpots(..., 'mode','midOnly', 'showBackground', true, 'markerSize', 6)
%
% Description:
%   Displays spots for every ray of beam `iBeam` on the provided axes `ax`.
%   By default all spots are shown; set 'mode' to 'midOnly' to plot only the
%   middle spot of each ray (reduces clutter). The first, middle and last
%   ray in the beam are emphasized with consistent marker shapes across beams:
%     - first ray  -> 'o'
%     - middle ray -> 's'
%     - last ray   -> '^'
%   Other rays use '.' marker.
%
% Inputs:
%   ax             - Axes handle (if empty, a new figure/axes is created)
%   ct             - matRad CT struct
%   cst            - matRad CST (cell array)
%   stf            - matRad STF struct (array of beams)
%   iBeam          - Index of beam to plot (scalar)
%   doseCube       - (optional) dose cube to show as background
%
% Name-Value optional inputs:
%   'mode'         - 'all' (default) | 'midOnly' (only middle spot per ray)
%   'showBackground' - true (default) | false
%   'markerSize'   - base marker size (default: 6)
%   'lineWidth'    - line width for emphasis (default: 1.2)
%   'colors'       - custom color map (default: lines(numel(stf)))
%
% Outputs:
%   hOut - struct with plot handles:
%          .spotHandles   - Nx1 array of handles for spot point plots (per ray)
%          .emphHandles   - handles for the emphasized rays (first/mid/last)
%          .bgHandle      - background handle returned from matRad_showSliceFast (if any)
%
% Example:
%   fig = figure; ax = axes(fig);
%   matRad_showSliceFast(ct, cst, doseCube); % optional
%   h = matRad_plotBeamSpots(gca, ct, cst, stf, 2, doseCube, 'mode','midOnly');
%
% Reference entry:
% | `matRad_plotBeamSpots` | `matRad_plotBeamSpots` | Plot all spots/rays for a beam with highlighted first/middle/last rays | `hOut = matRad_plotBeamSpots(ax, ct, cst, stf, iBeam)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% --- Parse inputs / defaults ---
p = inputParser;
addRequired(p,'ax');
addRequired(p,'ct');
addRequired(p,'cst');
addRequired(p,'stf');
addRequired(p,'iBeam', @(x) isnumeric(x) && isscalar(x));
addOptional(p,'doseCube', [], @(x) isempty(x) || isnumeric(x));
addParameter(p,'mode','all', @(s) any(strcmp(s,{'all','midOnly'})));
addParameter(p,'showBackground', true, @islogical);
addParameter(p,'markerSize', 6, @isnumeric);
addParameter(p,'lineWidth', 1.2, @isnumeric);
addParameter(p,'colors', [], @(x) isempty(x) || (isnumeric(x) && size(x,2)==3));
parse(p, ax, ct, cst, stf, iBeam, doseCube, varargin{:});
doseCube = p.Results.doseCube;
mode = p.Results.mode;
showBackground = p.Results.showBackground;
markerSize = p.Results.markerSize;
lineWidth = p.Results.lineWidth;
customColors = p.Results.colors;
ax = p.Results.ax;

hOut = struct('spotHandles', [], 'emphHandles', [], 'bgHandle', []);

% validate beam index
nBeams = numel(stf);
if iBeam < 1 || iBeam > nBeams
    error('iBeam (%d) out of range (1..%d)', iBeam, nBeams);
end

% prepare axes / background
if isempty(ax) || ~isgraphics(ax,'axes')
    fig = figure('Color','w');
    ax = axes(fig);
end
hold(ax,'on');

if showBackground
    % Attempt to show CT/CST/dose slice; signature may vary across matRad versions.
    % We call with the most common ordering: matRad_showSliceFast(ct, cst, doseCube)
    % If a version accepts an axes handle, it will use it; otherwise user can
    % call matRad_showSliceFast before calling this function.
    try
        % some matRad versions accept (ax, ct, cst, doseCube)
        bgRet = matRad_showSliceFast(ax, ct, cst, doseCube);
        hOut.bgHandle = bgRet;
    catch
        try
            % fallback: call without axes
            bgRet = matRad_showSliceFast(ct, cst, doseCube);
            hOut.bgHandle = bgRet;
        catch
            % give up silently (background optional)
            hOut.bgHandle = [];
        end
    end
end

% colors
if isempty(customColors)
    cmap = lines(nBeams);
else
    cmap = customColors;
end
beamColor = cmap(iBeam, :);

% get number of rays
beam = stf(iBeam);
if ~isfield(beam,'numOfRays')
    nRays = numel(beam.ray);
else
    nRays = beam.numOfRays;
    if isempty(nRays) || nRays==0
        nRays = numel(beam.ray);
    end
end

if nRays == 0
    warning('Beam %d contains no rays/spots.', iBeam);
    return;
end

% define emphasized ray indices
iFirst = 1;
iMid   = max(1, round((nRays+1)/2));
iLast  = nRays;

% marker mapping (same across beams)
markerFirst = 'o';
markerMid   = 's';
markerLast  = '^';
markerOther = '.';

spotH = gobjects(nRays,1);
emphH = gobjects(3,1); % first,middle,last (if present)

% loop rays
for iRay = 1:nRays
    % extract spot positions for this ray
    pts = getSpotPositionsFromRay(beam.ray(iRay));
    if isempty(pts)
        continue;
    end
    % pts is Nx2 or Nx3 -- assume first two cols are X,Y plotting coords
    if size(pts,2) >= 2
        XY = pts(:,1:2);
    else
        continue;
    end

    switch mode
        case 'all'
            % plot all spots of the ray
            if iRay==iFirst
                h = plot(ax, XY(:,1), XY(:,2), markerFirst, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', markerSize+2, 'LineWidth', lineWidth, 'LineStyle','none');
                emphH(1) = h;
            elseif iRay==iMid
                h = plot(ax, XY(:,1), XY(:,2), markerMid, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', markerSize+2, 'LineWidth', lineWidth, 'LineStyle','none');
                emphH(2) = h;
            elseif iRay==iLast
                h = plot(ax, XY(:,1), XY(:,2), markerLast, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', markerSize+2, 'LineWidth', lineWidth, 'LineStyle','none');
                emphH(3) = h;
            else
                h = plot(ax, XY(:,1), XY(:,2), markerOther, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', max(1,round(markerSize/2)), 'LineStyle','none');
            end
            spotH(iRay) = h;
        case 'midOnly'
            nSp = size(XY,1);
            iSpotMid = max(1, round((nSp+1)/2));
            XYmid = XY(iSpotMid, :);
            if iRay==iFirst
                h = plot(ax, XYmid(1), XYmid(2), markerFirst, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', markerSize+2, 'LineWidth', lineWidth, 'LineStyle','none');
                emphH(1) = h;
            elseif iRay==iMid
                h = plot(ax, XYmid(1), XYmid(2), markerMid, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', markerSize+2, 'LineWidth', lineWidth, 'LineStyle','none');
                emphH(2) = h;
            elseif iRay==iLast
                h = plot(ax, XYmid(1), XYmid(2), markerLast, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', markerSize+2, 'LineWidth', lineWidth, 'LineStyle','none');
                emphH(3) = h;
            else
                h = plot(ax, XYmid(1), XYmid(2), markerOther, ...
                    'Color', beamColor, 'MarkerFaceColor', beamColor, ...
                    'MarkerSize', max(1,round(markerSize/2)), 'LineStyle','none');
            end
            spotH(iRay) = h;
        otherwise
            error('Unknown mode %s', mode);
    end
end

% tidy up handles
hOut.spotHandles = spotH;
hOut.emphHandles = emphH(~arrayfun(@(x) isempty(x) || ~isgraphics(x), emphH));
if isempty(hOut.emphHandles)
    hOut.emphHandles = [];
end

% beam label
try
    text(ax, 0.02, 0.98, sprintf('Beam %d', iBeam), ...
        'Units','normalized','VerticalAlignment','top','HorizontalAlignment','left', ...
        'FontWeight','bold','Color',beamColor,'BackgroundColor','w','FontSize',10);
end

hold(ax,'off');

end

% -----------------------
% Helper: extract spot positions from a ray struct (robust)
% -----------------------
function pts = getSpotPositionsFromRay(rayStruct)
% tries several common fields created by matRad workflows:
% - rayStruct.spotsInfoSiddon or rayStruct.spotsInfoGeo or rayStruct.spotsInfo
% Each spotsInfo entry may contain .spotCube (1x3) or .spotPos or .pos.
% If multiple entries exist, collects all spotCube rows.

pts = [];
candNames = {'spotsInfoSiddon','spotsInfoGeo','spotsInfo','spots'};
found = false;
for i = 1:numel(candNames)
    nm = candNames{i};
    if isfield(rayStruct, nm)
        sInfo = rayStruct.(nm);
        found = true;
        break;
    end
end

if ~found
    % sometimes the ray itself contains a matrix of spot positions
    if isfield(rayStruct,'spotCube') && ~isempty(rayStruct.spotCube)
        pts = ensureNumericMatrix(rayStruct.spotCube);
        return;
    end
    pts = [];
    return;
end

% sInfo may be struct array or numeric
if isnumeric(sInfo)
    pts = ensureNumericMatrix(sInfo);
    return;
end

if isstruct(sInfo)
    outPts = [];
    for k = 1:numel(sInfo)
        entry = sInfo(k);
        % known field names that might contain coordinates:
        fldCandidates = {'spotCube','spotPos','pos','point','coords','xyz'};
        got = false;
        for f = 1:numel(fldCandidates)
            fName = fldCandidates{f};
            if isfield(entry, fName)
                dat = entry.(fName);
                datm = ensureNumericMatrix(dat);
                if ~isempty(datm)
                    outPts = [outPts; datm]; %#ok<AGROW>
                    got = true;
                    break;
                end
            end
        end
        if ~got
            % if entry has numeric scalar fields, try to collect [x y z]
            % common names: x,y,z
            if all(isfield(entry, {'x','y','z'}))
                datm = [entry.x, entry.y, entry.z];
                outPts = [outPts; datm]; %#ok<AGROW>
            end
        end
    end
    pts = outPts;
else
    pts = [];
end

end

function M = ensureNumericMatrix(x)
% convert various formats to Nx3 or Nx2 numeric matrix
M = [];
if isempty(x)
    return;
end
if isnumeric(x)
    if isvector(x)
        if numel(x) >= 2
            M = reshape(x, 1, numel(x)); % 1xN
        end
    elseif ismatrix(x)
        M = x;
    else
        M = reshape(x, [], size(x, ndims(x))); % best effort
    end
    return;
end
% try structs with fields
if isstruct(x) && numel(x)==1
    fields = fieldnames(x);
    vals = [];
    for i=1:numel(fields)
        v = x.(fields{i});
        if isnumeric(v) && isscalar(v)
            vals = [vals, v]; %#ok<AGROW>
        end
    end
    if ~isempty(vals)
        M = vals;
    else
        M = [];
    end
else
    M = [];
end
end