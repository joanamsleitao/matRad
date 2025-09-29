function matRad_showSpotsInSlice(ct, cst, stf, doseCube, weights, slice)
% MATRAD_SHOWSPOTSINSLICE
%   Displays all proton spot positions overlaid on a dose distribution slice,
%   zoomed in around the median spot location.
%
% SYNTAX:
%   matRad_showSpotsInSlice(ct, cst, stf, doseCube, weights)
%
% DESCRIPTION:
%   This function:
%     1) Plots a CT/dose slice.
%     2) Overlays all spot positions from the scanning beam delivery system.
%     3) Automatically zooms in around the median spot location.
%
% INPUTS:
%   ct        - matRad CT structure
%   cst       - matRad structure table
%   stf       - matRad steering file structure
%   doseCube  - 3D dose distribution
%   weights   - Spot weights (fluence or MU scaling per spot)
%
% OUTPUTS:
%   None (generates figure)
%
% -------------------------------------------------------------------------

if ~exist('slice', 'var') || isempty(slice)
    slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = slice(3);
end

%% -------------------- Figure Setup --------------------
figure('Units', 'normalized', ...
       'OuterPosition', [0 0 1 1]);
   
%% -------------------- Dose Slice Plot --------------------
% Show CT + dose overlay
matRad_showSliceFast(ct, cst, doseCube, slice);
ax = gca; % Get current axes handle

%% -------------------- Plot Spot Positions --------------------
markerSize = 8;
% Overlay spots and get median XY coordinates (in world coords)
% medianCoords = matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights);
medianCoords = matRad_plotSpotsSlice(ax, ct, stf, markerSize, weights, [], [], slice);
%% -------------------- Zoom to Spot Region --------------------
% Calculate zoomed window around median spot position (±30 mm margin)
[xlimVals, ylimVals] = matRad_getZoomWindow(medianCoords(1), medianCoords(2), ct, 30);
set(ax, 'XLim', xlimVals, 'YLim', ylimVals);

%% -------------------- Title --------------------
title('All Spot Positions (Zoomed In)');

end
