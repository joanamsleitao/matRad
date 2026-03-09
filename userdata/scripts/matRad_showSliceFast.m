function [slice, hleg, hCMap] = matRad_showSliceFast(ct, cst, doseCube, slice, ...
    doseWindow, boolPlotLegend, levelZoom, isoDoseLevels, doseColorMap)
% MATRAD_SHOWSLICEFAST - Quickly displays CT slice with dose overlay
%
% Syntax:  [slice, hleg] = matRad_showSliceF(ct, cst, doseCube, slice, doseWindow)
%
% Inputs:
%   ct          - CT structure (struct)
%   cst         - CST cell array (cell array)
%   doseCube    - Dose cube to display (3D array, optional)
%   slice       - Slice number to display (integer, optional)
%   doseWindow  - Dose display window [min max] (vector, optional)
%
% Outputs:
%   slice       - Displayed slice number (integer)
%   hleg        - Handle to legend (handle)
%
% Other m-files required: matRad_plotSliceWrapper.m, matRadJoana_plotCTSlice.m
% Subfunctions: none
% MAT-files required: none
%
% See also: matRad_plotSliceWrapper, matRadJoana_plotCTSlice
%

if ~exist('doseCube', 'var') || isempty(doseCube)
    doseCube = [];
end

if ~exist('doseColorMap', 'var') || isempty(doseColorMap)
    doseColorMap = [];
end

if ~exist('slice', 'var') || isempty(slice)
    isoCenterIx = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = isoCenterIx(3);
else
    isoCenterIx = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    isoCenterIx(3) = slice;
end

if (~exist('doseWindow', 'var') || isempty(doseWindow)) && (exist('doseCube'))
    doseWindow = [min(doseCube(:)), max(doseCube(:))];
end

if ~exist('boolPlotLegend', 'var') || isempty(boolPlotLegend)
    boolPlotLegend = 1;
end

if ~exist('levelZoom', 'var') || isempty(levelZoom)
    levelZoom = [];
end

if ~exist('isoDoseLevels', 'var') || isempty(isoDoseLevels)
    isoDoseLevels = [];
end

plane = 3;
cubeIdx = 1;
% figure;
axesHandle = gca;
if isempty(doseCube)
    %     hCt = matRad_plotCtSlice(axesHandle, ct.cubeHU, 1, plane, slice);
    % [~,hDose,hCt,hContour,hIsoDose] = ...
        matRad_plotSliceWrapper(gca, ct, cst, cubeIdx, ...
        doseCube, plane, slice, [], ...
        [], [], [], [],...
        0, [], [], boolPlotLegend);
    % matRad_plotSliceWrapper(axesHandle,ct,cst,cubeIdx, ...
    % dose,plane,slice, thresh, ...
    % alpha,contourColorMap, doseColorMap, doseWindow,
    % doseIsoLevels, voiSelection,colorBarLabel, boolPlotLegend, ...
    % varargin)


    % matRad_plotCtSlice(gca, ct.cubeHU,cubeIdx,plane,slice); 
    % matRad_plotAxisLabels(gca,ct,plane,slice,14,[])

else
    colorBarLabel = 'Dose [Gy]';
    % [ctHandle,cMap,window] = matRad_plotCtSlice(axesHandle,ctCube,cubeIdx,plane,slice,cMap,window)
    % matRad_plotSliceWrapper(axesHandle, ct, cst, 1, doseCube,3,slice,...
    %     [], [], [],...
    %     [], doseWindow, [], [],...
    %     colorBarLabel, boolPlotLegend);
    
       [~,~,hCt,hContour,hIsoDose] = matRad_plotSliceWrapper(gca, ct, cst, cubeIdx, ...
        doseCube, plane, slice, [], ...
        [], [], doseColorMap, doseWindow,...
        isoDoseLevels, [], colorBarLabel, boolPlotLegend);
    % matRad_plotSliceWrapper(axesHandle,ct,cst,cubeIdx, ...
    % dose,plane,slice, thresh, ...
    % alpha,contourColorMap, doseColorMap, doseWindow,
    % doseIsoLevels, voiSelection,colorBarLabel, boolPlotLegend, ...
    % varargin)
end

if boolPlotLegend == 1
    hleg = axesHandle.Legend;
    hleg.FontSize = 10;
    hleg.Location = 'bestoutside';
end

% Zoom
if ~isempty(levelZoom)
    [xlimVals, ylimVals] = matRad_getZoomWindow(isoCenterIx(2), isoCenterIx(1), ct, levelZoom);
    if xlimVals(1) ~= xlimVals(2) && ylimVals(1) ~= ylimVals(2)
        set(axesHandle, 'XLim', xlimVals, 'YLim', ylimVals);
    else
        xlimVals = [xlimVals(1)-30, xlimVals(2)+30];
        ylimVals = [ylimVals(1)-30, ylimVals(2)+30];
        set(axesHandle, 'XLim', xlimVals, 'YLim', ylimVals);
    end
end

fontsize(14, 'points');

end