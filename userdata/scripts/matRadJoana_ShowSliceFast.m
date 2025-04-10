function matRadJoana_ShowSliceFast(ct, cst, doseCube)
%Call matRadJoana_ShowSliceFast(ct, cst, resultGUI.physicalDose)

slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
slice = slice(3);
plane = 3;
figure; matRad_plotSliceWrapper(gca,ct,cst,1,doseCube,3,slice);

end