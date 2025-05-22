function [slice] = matRadJoana_ShowSliceFast(ct, cst, doseCube, slice)
%Call matRadJoana_ShowSliceFast(ct, cst, resultGUI.physicalDose)

if ~exist('slice','var') || isempty(slice)
    slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = slice(3);
else
    slice = slice;
end

plane = 3;

% figure;
axesHandle = gca;
if nargin < 3 || isempty(doseCube)
    %     hCt = matRad_plotCtSlice(axesHandle, ct.cubeHU, 1, plane, slice);

    matRadJoana_plotCTSlice(axesHandle, ct, cst, 1, plane, slice);
    matRad_plotAxisLabels(gca,ct,plane,slice,14,[])

else
    % matRad_plotSliceWrapper(gca,ct,cst,1,doseCube,3,slice);
matRad_plotSliceWrapper(gca,ct,cst,1,doseCube,3,slice, [], [], [], [], [], [0 30]);

end
end