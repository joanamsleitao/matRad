function [slice] = matRadJoana_ShowSliceFast(ct, cst, doseCube, boolPlotLegend)
%Call matRadJoana_ShowSliceFast(ct, cst, resultGUI.physicalDose)

if ~exist('boolPlotLegend','var') || isempty(boolPlotLegend)
   boolPlotLegend = false;
end

slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
slice = slice(3);
plane = 3;

figure;
axesHandle = gca;
if nargin < 3 || isempty(doseCube)
%     hCt = matRad_plotCtSlice(axesHandle, ct.cubeHU, 1, plane, slice);

    matRadJoana_plotCTSlice(axesHandle, ct, cst, 1, plane, slice);
    matRad_plotAxisLabels(gca,ct,plane,slice,14,[])

else
    matRad_plotSliceWrapper(gca,ct,cst,1,doseCube,3,slice);
end
end