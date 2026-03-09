function hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesPerPlane, alteredSlices, plane, sliceInterval)
% matRad_showAllPlanes - Visualize CT, CST, and optionally dose in 3 planes
%                        and highlight altered slices if provided
%
% Syntax:
%   hFig = matRad_showAllPlanes(ct, cst)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesPerPlane)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesPerPlane, alteredSlices)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesPerPlane, alteredSlices, plane)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesPerPlane, alteredSlices, plane, sliceInterval)
%
% Description:
%   Displays CT, CST, and optionally dose in the three anatomical planes.
%   If 'alteredSlices' is provided, those slices are visually highlighted
%   (title color + asterisk marker) in the axial plane.
%   If 'sliceInterval' is provided, only slices within that range are shown.
%
% Inputs:
%   ct            - matRad CT struct
%   cst           - matRad CST (cell array of VOIs)
%   doseCube      - (optional) dose cube to overlay
%   nSlicesPerPlane - (optional) total target number of slices to show per plane (default: 30)
%   alteredSlices - (optional) indices of altered slices (only relevant for axial plane)
%   plane         - (optional) which plane(s) to show: 1=coronal, 2=sagittal, 3=axial (default: 1:3)
%   sliceInterval - (optional) [min max] slice range to focus on (default: [] = all slices)
%                   Can be a single interval [min max] applied to all planes, or
%                   a cell array {[min1 max1], [min2 max2], [min3 max3]} for each plane
%
% Outputs:
%   hFig - struct with figure handles per plane and figure batch
%
% Examples:
%   % Show only axial slices 40-60
%   hFig = matRad_showAllPlanes(ct, cst, dose, 20, [], 3, [40 60]);
%
%   % Show different intervals for each plane
%   hFig = matRad_showAllPlanes(ct, cst, dose, 20, [], 1:3, {[30 50], [40 60], [45 65]});
%
% -------------------------------------------------------------------------
% Author: Joana Leitão & ChatGPT (2025)
% -------------------------------------------------------------------------

if nargin < 3 || isempty(doseCube)
    doseCube = [];
    doseWindow = [];
else
    doseWindow = [0 max(doseCube(:)) * 1.001]; % Safe dose range if present
end

if nargin < 4 || isempty(nSlicesPerPlane)
    nSlicesPerPlane = 30;
end

if nargin < 5
    alteredSlices = [];
end

if nargin < 6 || isempty(plane)
    plane = 1:3;
end

if nargin < 7 || isempty(sliceInterval)
    sliceInterval = [];
end

maxSlicesPerFigure = 4; % maximum tiles per figure
matRad_cfg = MatRad_Config.instance();
planeNames = {'coronal','sagittal','axial'};
cubeDim = ct.cubeDim;

% Isocenter for reference
if ~isempty(cst)
    isoCenter = matRad_world2cubeIndex(matRad_getIsoCenter(cst, ct, 0), ct);
else
    isoCenter = round(cubeDim ./ 2);
end

cstHandle = cst;

% Parse sliceInterval input
if ~isempty(sliceInterval)
    if iscell(sliceInterval)
        % Cell array: one interval per plane
        if numel(sliceInterval) ~= 3
            error('sliceInterval as cell array must have 3 elements (one per plane).');
        end
        intervalPerPlane = sliceInterval;
    elseif isnumeric(sliceInterval) && numel(sliceInterval) == 2
        % Single interval: apply to all planes
        intervalPerPlane = {sliceInterval, sliceInterval, sliceInterval};
    else
        error('sliceInterval must be [min max] or {[min1 max1], [min2 max2], [min3 max3]}.');
    end
else
    intervalPerPlane = {[], [], []};
end

for thisPlane = plane
    nSlices = cubeDim(thisPlane);

    % Determine slice range for this plane
    interval = intervalPerPlane{thisPlane};
    if ~isempty(interval)
        % Validate and clamp interval
        sliceMin = max(1, min(interval));
        sliceMax = min(nSlices, max(interval));

        if sliceMin > sliceMax
            warning('Invalid slice interval [%d %d] for %s plane. Skipping.', ...
                sliceMin, sliceMax, planeNames{thisPlane});
            continue;
        end

        % Sample within the specified interval
        nAvailable = sliceMax - sliceMin + 1;
        nShow = min(nSlicesPerPlane, nAvailable);
        sliceIdx = unique(round(linspace(sliceMin, sliceMax, nShow)));
    else
        % Default: sample across entire volume
        step = max(1, round(nSlices / nSlicesPerPlane));
        sliceIdx = 1:step:nSlices;
    end

    numSlices = numel(sliceIdx);

    if numSlices == 0
        warning('No slices to display for %s plane.', planeNames{thisPlane});
        continue;
    end

    nFigs = ceil(numSlices / maxSlicesPerFigure);

    for f = 1:nFigs
        startIdx = (f-1)*maxSlicesPerFigure + 1;
        endIdx = min(f*maxSlicesPerFigure, numSlices);
        currentSlices = sliceIdx(startIdx:endIdx);

        % Create figure
        if ~isempty(interval)
            figTitle = sprintf('CT & CST - %s plane (set %d) [interval %d–%d]', ...
                planeNames{thisPlane}, f, sliceMin, sliceMax);
        else
            figTitle = sprintf('CT & CST - %s plane (set %d)', planeNames{thisPlane}, f);
        end

        hFig.(planeNames{thisPlane})(f).fig = figure('Color', 'w', ...
            'Name', figTitle, ...
            'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

        nTiles = numel(currentSlices);
        nRows = ceil(nTiles / 5);
        nCols = min(nTiles, 5);

        t = tiledlayout(hFig.(planeNames{thisPlane})(f).fig, nRows, nCols, ...
            'TileSpacing', 'compact', 'Padding', 'compact');

        if ~isempty(interval)
            titleStr = sprintf('%s plane | interval [%d–%d] | showing slices %d–%d', ...
                planeNames{thisPlane}, sliceMin, sliceMax, currentSlices(1), currentSlices(end));
        else
            titleStr = sprintf('%s plane (slices %d–%d)', ...
                planeNames{thisPlane}, currentSlices(1), currentSlices(end));
        end

        title(t, titleStr, 'Color', matRad_cfg.gui.highlightColor, 'FontWeight', 'bold');

        for i = 1:numel(currentSlices)
            nexttile;
            sliceNumber = currentSlices(i);
            isoCenterIx = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
            isoCenterIx(3) = sliceNumber;
            hold on;

            % Plot slice
            matRad_plotSliceWrapper(gca, ct, cstHandle, 1, doseCube, ...
                thisPlane, sliceNumber, [], [], [], [], [0 75]);

            % Highlight altered slices in the axial plane
            if thisPlane == 3 && ismember(sliceNumber, alteredSlices)
                title(sprintf('Slice %d *', sliceNumber), ...
                    'Color', [0.9 0.4 0.0], 'FontWeight', 'bold'); % orange color
            else
                title(sprintf('Slice %d', sliceNumber), ...
                    'Color', matRad_cfg.gui.textColor);
            end

            [xlimVals, ylimVals] = matRad_getZoomWindow(isoCenterIx(2), isoCenterIx(1), ct, 0.75);
            if xlimVals(1) ~= xlimVals(2) && ylimVals(1) ~= ylimVals(2)
                set(gca, 'XLim', xlimVals, 'YLim', ylimVals);
            else
                xlimVals = [xlimVals(1)-30, xlimVals(2)+30];
                ylimVals = [ylimVals(1)-30, ylimVals(2)+30];
                set(gca, 'XLim', xlimVals, 'YLim', ylimVals);
            end
        end
    end
end

% Summary message
if ~isempty(sliceInterval)
    if iscell(sliceInterval)
        disp('✅ CT + CST slices displayed with custom intervals per plane.');
    else
        disp(sprintf('✅ CT + CST slices displayed — focused on interval [%d–%d].', ...
            sliceInterval(1), sliceInterval(2)));
    end
else
    if isempty(alteredSlices)
        disp('✅ CT + CST slices displayed (no altered slices provided).');
    else
        disp(['✅ CT + CST slices displayed — altered slices highlighted (n = ' num2str(numel(alteredSlices)) ').']);
    end
end

end