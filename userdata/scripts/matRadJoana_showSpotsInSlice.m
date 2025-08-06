function matRadJoana_showSpotsInSlice(ct, cst, stf, doseCube, weights)
figure; set(gcf,  'Units' ,  'Normalized' ,  'OuterPosition' , [0 0 1 1]);
matRadJoana_ShowSliceFast(ct, cst, doseCube);
ax = gca;
markerSize = 5;
medianCube = matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights);
[xlimVals, ylimVals] = matRad_getZoomWindow(medianCube(1), medianCube(2), ct, 30);
set(gca, 'XLim', xlimVals, 'YLim', ylimVals);
title('All Spot Positions (Zoomed In)');

end