% =========================================================================
% This script demonstrates key matRad functions for visualizing and analyzing
% proton spot and ray distributions using CT and beam setup data.
% =========================================================================
% 0. Load ct, cst, pln, stf, dij (?) and resultGUI
% load('C:\Users\joana\OneDrive\Ambiente de Trabalho\Spots_WorkspaceBase\workspace.mat', 'ct', 'cst', 'pln', 'stf', 'resultGUI')
% 
%%
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
[stf, ~] = matRad_calcSpotWeightsAndMatrix(stf, weights);

%%
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
xlim(xlimVals);
ylim(ylimVals);
% axis equal;
title('All Spot Positions (Zoomed In)');

%% 
% 6. Plot a single ray’s spot positions
% -------------------------------------
% Choose one ray (beam and ray index)
iBeam = 1;
iRay = 2;

figure; set(gcf,  'Units' ,  'Normalized' ,  'OuterPosition' , [0 0 1 1]);
matRadJoana_ShowSliceFast(ct, cst, resultGUI.physicalDose);
ax2 = gca;
% This function plots all spots in a ray, with energy and ray legends
% It also supports plotting Siddon paths and geo spots.
medianSpotCube = matRad_plotSingleRay(ax2, stf, iRay, 6, weights, 1);

% Zoom into the single ray’s center
[xlimValsRay, ylimValsRay] = matRad_getZoomWindow(medianSpotCube(1), medianSpotCube(2), ct, 20);
xlim(ax2, xlimValsRay);
ylim(ax2, ylimValsRay);

title(sprintf('Beam %d, Ray %d Spot View (Zoomed)', iBeam, iRay));

%%
% 7. Plot representative spot per energy layer (per beam)
% --------------------------------------------------------
% Shows one spot per energy layer (most weighted), using color for energy and
% shape for beam. Optionally shows Siddon ray paths.

figure; set(gcf,  'Units' ,  'Normalized' ,  'OuterPosition' , [0 0 1 1]);
matRadJoana_ShowSliceFast(ct, cst, resultGUI.physicalDose);
ax3 = gca;

matRad_plotEnergyLayerPerWeight(ax3, ct, stf, 8);
[xlimVals, ylimVals] = matRad_getZoomWindow(254, 292, ct, 30);
set(ax3, 'xlim', xlimVals)
set(ax3, 'ylim', ylimVals)
title('Representative Spots per Energy Layer (Per Beam)');

%%
% % Meaningless
% % 8. Plot histogram of spot counts per energy layer (per beam)
% % ------------------------------------------------------------
% % Visualizes how many spots exist per energy for each beam.
% figure;
% ax4 = gca;
% matRad_plotEnergyLayerHistogram(ax4, stf);
% 
% %%
% % Meaningless
% figure;
% ax5 = gca;
% matRad_plotEnergyLayerWeightsHistogram(ax5, stf, 'perBeam');   % Shows ray-level stacking

%%
figure;
ax6 = gca;
matRad_plotEnergyLayerHistogramWeightAndCounts(ax6, stf);  % Default, as before

% =========================================================================
% End of example
% =========================================================================

%%

iBeam = 1; % selected beam

figure; 
ax = gca;
set(gcf,  'Units' ,  'Normalized' ,  'OuterPosition' , [0 0 1 1]);

% Show the dose slice background
matRadJoana_ShowSliceFast(ct, cst, resultGUI.physicalDose);

% Correct title call
title(ax, sprintf('Dose + Geo Spots (Beam %d)', iBeam));

% Overlay: Energy layer most-weighted spots for beam 1
matRad_plotEnergyLayerPerWeight(ax, ct, stf, 6, [], false, iBeam);

% Overlay: Geo spot positions for all rays of the selected beam
medianSpotCube = matRad_plotGeoSpot(ax, stf, iBeam);

% Optional: If you want to plot geo spots ray by ray instead, do this:
% nRays = numel(stf(iBeam).ray);
% for iRay = 1:nRays
%     medianSpotCube = matRad_plotGeoSpot(ax, stf, iBeam, iRay);
% end

% Optional: add ray labels
nRays = numel(stf(iBeam).ray);
for iRay = 1:nRays
    spot = stf(iBeam).ray(iRay).spotsInfoGeo(1).spotCube;
    text(ax, spot(1), spot(2), sprintf('%d', iRay), ...
        'FontSize', 6, 'Color', 'w', 'HorizontalAlignment', 'center');
end
    