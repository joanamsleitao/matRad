function [slice, hleg] = matRadJoana_ShowSliceFast(ct, cst, doseCube, slice, doseWindow, boolPlotLegend)
% MATRADJOANA_SHOWSLICEFAST - Quickly displays CT slice with dose overlay
%
% Syntax:  [slice, hleg] = matRadJoana_ShowSliceFast(ct, cst, doseCube, slice, doseWindow)
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

if ~exist('slice', 'var') || isempty(slice)
    slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = slice(3);
end

if ~exist('doseWindow', 'var') || isempty(doseWindow)
    doseWindow = [min(doseCube(:)), max(doseCube(:))];
end

if ~exist('boolPlotLegend', 'var') || isempty(boolPlotLegend)
    boolPlotLegend = 1;
end

plane = 3;

% figure;
axesHandle = gca;
if nargin < 3 || isempty(doseCube)
    %     hCt = matRad_plotCtSlice(axesHandle, ct.cubeHU, 1, plane, slice);

    matRadJoana_plotCTSlice(axesHandle, ct, cst, 1, plane, slice,...
        [], [], [], [], [], ...
        [], [], [],  boolPlotLegend)
    matRad_plotAxisLabels(gca,ct,plane,slice,14,[])

else
    matRad_plotSliceWrapper(axesHandle,ct,cst,1,doseCube,3,slice,...
        [], [], [],...
        [], doseWindow, [], [],...
        [],boolPlotLegend);
end
hleg = axesHandle.Legend;
hleg.FontSize = 10;
hleg.Location = 'bestoutside';
end