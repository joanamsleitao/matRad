function hFig = matRad_comp2DosesAllPlanes(ct, cst, doseRef, doseTest, nSlicesTarget, plane, varargin)
% matRad_comp2DosesAllPlanes - Compare two dose distributions across multiple slices
%
% Description:
%   Displays two dose distributions (reference on top row, test on bottom row)
%   across multiple slices in selected plane(s).
%
% Plane convention (matches matRad_plotDoseSlice):
%   plane = 1 coronal, 2 sagittal, 3 axial
%
% Name-Value Pairs:
%   'maxSlicesPerFigure'    - max slice columns per figure (default: 5)
%   'doseWindow'            - [min max] in Gy (default: auto from max of both doses)
%   'labelRef'              - label for reference dose (default: 'Reference')
%   'labelTest'             - label for test dose (default: 'Test')
%   'sliceInterval'         - restrict selection to an interval:
%                             - [] (default): uses entire volume
%                             - [min max]: applies to all planes
%                             - {[min1 max1],[min2 max2],[min3 max3]} for per-plane
%
% -------------------------------------------------------------------------
% Author: Joana Leitão & ChatGPT (2025)
% -------------------------------------------------------------------------

%% Parse inputs
p = inputParser;
addParameter(p, 'maxSlicesPerFigure', 5, @(x)isnumeric(x) && isscalar(x) && x>=1);
addParameter(p, 'doseWindow', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
addParameter(p, 'labelRef', 'Reference', @(x)ischar(x) || isstring(x));
addParameter(p, 'labelTest', 'Test', @(x)ischar(x) || isstring(x));
addParameter(p, 'sliceInterval', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2) || iscell(x));

parse(p, varargin{:});
opts = p.Results;

if nargin < 5 || isempty(nSlicesTarget)
    nSlicesTarget = 30;
end
if nargin < 6 || isempty(plane)
    plane = 3; % default axial
end

%% Validate dose cubes
if ~isequal(size(doseRef), size(doseTest))
    error('doseRef and doseTest must have identical dimensions.');
end

cubeDim = size(doseRef);

%% Dose window
if isempty(opts.doseWindow)
    maxDose = max([doseRef(:); doseTest(:)]);
    opts.doseWindow = [0 1.05 * maxDose];
end

%% Resolve sliceInterval (global or per-plane)
intervalPerPlane = {[], [], []};
if ~isempty(opts.sliceInterval)
    if iscell(opts.sliceInterval)
        if numel(opts.sliceInterval) ~= 3
            error('sliceInterval as cell array must be {[min1 max1],[min2 max2],[min3 max3]}.');
        end
        intervalPerPlane = opts.sliceInterval;
    else
        intervalPerPlane = {opts.sliceInterval, opts.sliceInterval, opts.sliceInterval};
    end
end

%% Isocenter index (for zoom window)
if ~isempty(cst)
    try
        isoCenterIx0 = matRad_world2cubeIndex(matRad_getIsoCenter(cst, ct, 0), ct);
    catch
        isoCenterIx0 = round(cubeDim ./ 2);
    end
else
    isoCenterIx0 = round(cubeDim ./ 2);
end

planeNames = {'coronal','sagittal','axial'};
hFig = struct();
totalSlicesShown = 0;

%% Loop over planes
for thisPlane = plane(:)'
    
    nSlices = cubeDim(thisPlane);
    
    % Determine slice range
    interval = intervalPerPlane{thisPlane};
    if ~isempty(interval)
        sliceMin = max(1, min(interval));
        sliceMax = min(nSlices, max(interval));
        if sliceMin > sliceMax
            warning('Invalid sliceInterval [%d %d] for %s. Skipping plane.', ...
                sliceMin, sliceMax, planeNames{thisPlane});
            continue;
        end
    else
        sliceMin = 1;
        sliceMax = nSlices;
    end
    
    % Sample slices uniformly within the interval
    nShow = min(nSlicesTarget, (sliceMax - sliceMin + 1));
    sliceIdx = unique(round(linspace(sliceMin, sliceMax, nShow)));
    
    numSlices = numel(sliceIdx);
    if numSlices == 0
        warning('No slices to display for %s plane.', planeNames{thisPlane});
        continue;
    end
    
    % Split into figures
    nFigs = ceil(numSlices / opts.maxSlicesPerFigure);
    
    for f = 1:nFigs
        startIdx = (f-1)*opts.maxSlicesPerFigure + 1;
        endIdx   = min(f*opts.maxSlicesPerFigure, numSlices);
        currentSlices = sliceIdx(startIdx:endIdx);
        
        figName = sprintf('Dose Comparison - %s plane (set %d/%d)', planeNames{thisPlane}, f, nFigs);
        
        hFig.(planeNames{thisPlane})(f).fig = figure('Color','w', ...
            'Name', figName, 'Units','normalized', 'OuterPosition',[0 0 1 1]);
        
        nCols = numel(currentSlices);
        t = tiledlayout(2, nCols, 'TileSpacing','compact', 'Padding','compact');
        
        if ~isempty(interval)
            intervalStr = sprintf('interval [%d–%d]', sliceMin, sliceMax);
        else
            intervalStr = 'all slices';
        end
        
        title(t, sprintf('%s | %s vs %s | %s | showing slices %d–%d', ...
            planeNames{thisPlane}, string(opts.labelRef), string(opts.labelTest), ...
            intervalStr, currentSlices(1), currentSlices(end)), ...
            'FontWeight','bold', 'Interpreter','none');
        
        for i = 1:nCols
            sliceNumber = currentSlices(i);
            
            % Zoom reference: set the current plane slice on the isocenter index
            isoCenterIx = isoCenterIx0;
            isoCenterIx(thisPlane) = sliceNumber;
            
            topTile = i;
            botTile = i + nCols;
            
            % --- Top row: Reference dose ---
            ax1 = nexttile(topTile);
            hold(ax1, 'on');
            
            matRad_plotSliceWrapper(ax1, ct, cst, 1, ...
                doseRef, thisPlane, sliceNumber, [], ...
                [], [], [], opts.doseWindow, ...
                [], [], [], 0);
            
            [xlimVals, ylimVals] = matRad_getZoomWindow(isoCenterIx(2), isoCenterIx(1), ct, 0.85);
            applyZoom(ax1, xlimVals, ylimVals);
            
            title(ax1, sprintf('%s\nSlice %d', string(opts.labelRef), sliceNumber), 'FontSize', 9);
            
            % --- Bottom row: Test dose ---
            ax2 = nexttile(botTile);
            hold(ax2, 'on');
            
            matRad_plotSliceWrapper(ax2, ct, cst, 1, ...
                doseTest, thisPlane, sliceNumber, [], ...
                [], [], [], opts.doseWindow, ...
                [], [], [], 0);
            
            [xlimVals, ylimVals] = matRad_getZoomWindow(isoCenterIx(2), isoCenterIx(1), ct, 0.85);
            applyZoom(ax2, xlimVals, ylimVals);
            
            title(ax2, sprintf('%s\nSlice %d', string(opts.labelTest), sliceNumber), 'FontSize', 9);
        end
        
        totalSlicesShown = totalSlicesShown + nCols;
    end
end

fprintf('✅ Dose comparison complete. Total slice-columns shown: %d\n', totalSlicesShown);

end

%% ===== Helper function =====
function applyZoom(ax, xlimVals, ylimVals)
% Robust zoom application (fallback padding if degenerate)
if xlimVals(1) ~= xlimVals(2) && ylimVals(1) ~= ylimVals(2)
    set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
else
    xlimVals = [xlimVals(1)-30, xlimVals(2)+30];
    ylimVals = [ylimVals(1)-30, ylimVals(2)+30];
    set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
end
end