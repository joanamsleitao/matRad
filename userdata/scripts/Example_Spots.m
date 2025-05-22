% =========================================================================
% This script demonstrates key matRad functions for visualizing and analyzing
% proton spot and ray distributions using CT and beam setup data.
% =========================================================================
% 0. Load ct, cst, pln, stf, dij (?) and resultGUI
load('C:\Users\joana\OneDrive\Ambiente de Trabalho\Spots_WorkspaceBase\workspace.mat', 'ct', 'cst', 'pln', 'stf', 'resultGUI')
% 

% 2. Compute geometric spot positions
% -----------------------------------
% Adds physical spot positions (from beam model) to each ray in stf.
stf = matRad_computeSpotPositions_Geo(ct, stf);

% 3. Run Siddon ray tracing for physical path and voxel intersections
% --------------------------------------------------------------------
% This adds ray tracing results (e.g., WEPL, path voxels) to each ray.
stf = matRad_computeSpotPositions_Siddon(ct, stf);

% 1. Compute spot weights and influence matrix (Dij)
% --------------------------------------------------
% This function returns the dose influence matrix (Dij) and weights vector
% for each spot, based on a simple dose prescription or plan.
weights = resultGUI.w;
[stf, wMatrix] = matRad_calcSpotWeightsAndMatrix(stf, weights);

% 4. Plot all spots on a 2D CT slice (e.g., axial)
% ------------------------------------------------
% Visualizes the projected spot positions from all beams and rays, with:
% - Color: energy layers
% - Shape: beam number
% - Diamonds: geometric positions

figure; set(gcf,  'Units' ,  'Normalized' ,  'OuterPosition' , [0 0 1 1]);
matRadJoana_ShowSliceFast(ct, cst, resultGUI.physicalDose);
ax = gca;
% markerSize = 6, showRayTracing = 1, useGeoSpots = 1
medianCube = matRad_plotSpotsSlice(ax, ct, stf, 6);
[xlimVals, ylimVals] = matRad_getZoomWindow(medianCube(1), medianCube(2), ct, 60);
set(gca, 'XLim', xlimVals, 'YLim', ylimVals);

% 5. Zoom into median spot location
% ---------------------------------
% Gets a proportional zoom window centered on the median spot.
[xlimVals, ylimVals] = matRad_getZoomWindow(medianCube(1), medianCube(2), ct, 30);
xlim(ax, xlimVals);
ylim(ax, ylimVals);
axis equal;
title('All Spot Positions (Zoomed In)');

% Optional: overlay dose (if x is available)
% dose = dij * x;
% Add your code here to display dose as an image or contour

pause(2);  % Pause before showing individual ray

% 6. Plot a single ray’s spot positions
% -------------------------------------
% Choose one ray (beam and ray index)
iBeam = 1;
iRay = 50;

figure;
ax2 = gca;
% This function plots all spots in a ray, with energy and ray legends
% It also supports plotting Siddon paths and geo spots.
medianCubeRay = matRad_plotSingleRay(ax2, ct, stf, iBeam, iRay, 6, weights, 1, 1);

% Zoom into the single ray’s center
[xlimValsRay, ylimValsRay] = matRad_getZoomWindow(medianCubeRay(1), medianCubeRay(2), ct, 20);
xlim(ax2, xlimValsRay);
ylim(ax2, ylimValsRay);
axis equal;
title(sprintf('Beam %d, Ray %d Spot View (Zoomed)', iBeam, iRay));

% =========================================================================
% End of example
% =========================================================================
