function ax = matRad_plotDoseELsum(ct, cst, stf, topELStruct, sliceIdx)
% matRad_plotDoseELsum - Sum dose from all energy layers and plot with spots
%
% Syntax:
%   ax = matRad_plotDoseELsum(ct, cst, stf, topELStruct)
%   ax = matRad_plotDoseELsum(ct, cst, stf, topELStruct, sliceIdx)
%
% Description:
%   Sums the dose cubes from all energy layers in topELStruct and plots
%   the combined dose distribution (CT + summed dose) overlaid with all
%   spots from all layers in a single axis. If sliceIdx is not provided,
%   automatically selects the slice with maximum summed dose.
%
% Inputs:
%   ct          - CT struct
%   cst         - CST cell array
%   stf         - beam geometry struct
%   topELStruct - struct with per-EL dose cubes and weights:
%                     topELStruct.(ELname).RBExDose
%                     topELStruct.(ELname).w
%   sliceIdx    - (optional) CT slice index to display. If empty or omitted,
%                 uses slice with maximum summed dose.
%
% Output:
%   ax - axis handle of the created plot
%
% Example:
%   ax = matRad_plotDoseELsum(ct, cst, stf, topELStruct_top5);
%   ax = matRad_plotDoseELsum(ct, cst, stf, topELStruct_top5, 150);
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_plotDoseELsum` | `matRad_plotDoseELsum` | Sum & plot dose + spots from multiple ELs in a single slice | `ax = matRad_plotDoseELsum(ct, cst, stf, topELStruct, sliceIdx)` | 🟢 |
% -------------------------------------------------------------------------

ELNames = fieldnames(topELStruct);
nEL = numel(ELNames);

% -------------------------------------------------------------------------
% Sum doses from all layers
% -------------------------------------------------------------------------
firstDose = topELStruct.(ELNames{1}).RBExDose;
doseSum   = zeros(size(firstDose), 'like', firstDose);

for j = 1:nEL
    layer = ELNames{j};
    doseL = topELStruct.(layer).RBExDose;
    doseSum = doseSum + doseL;
end

% -------------------------------------------------------------------------
% Choose slice: either provided or auto-select based on max dose
% -------------------------------------------------------------------------
if nargin < 5 || isempty(sliceIdx)
    % Auto-select: slice with maximum dose
    maxDosePerSlice = squeeze(max(max(doseSum, [], 1), [], 2));
    [~, sliceIdx] = max(maxDosePerSlice);
end

% -------------------------------------------------------------------------
% Create figure and plot summed dose
% -------------------------------------------------------------------------
figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
ax = axes;

matRad_showSliceFast(ct, cst, doseSum, sliceIdx);
hold(ax, 'on');

% -------------------------------------------------------------------------
% Overlay spots from all layers (combined weights)
% -------------------------------------------------------------------------
% Combine all weights into a single vector for plotting
totalNumOfBixels = sum([stf.totalNumOfBixels]);
wCombined = zeros(totalNumOfBixels, 1);

for j = 1:nEL
    layer = ELNames{j};
    wEL   = topELStruct.(layer).w;
    wCombined = wCombined + wEL; % sum weights from all layers
end

% Plot all spots at once with combined weights
markerSize = 15;
medianCoords = matRad_plotSpotsSlice(ax, ct, stf, markerSize, wCombined, [], [], sliceIdx);

% -------------------------------------------------------------------------
% Zoom around spot cluster
% -------------------------------------------------------------------------
if ~any(isnan(medianCoords))
    [xlimVals, ylimVals] = matRad_getZoomWindow(medianCoords(1), medianCoords(2), ct, 30);
    if xlimVals(2) > xlimVals(1) && ylimVals(2) > ylimVals(1)
        set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
    end
end

% -------------------------------------------------------------------------
% Title
% -------------------------------------------------------------------------
title(ax, sprintf('Summed dose of %d ELs; slice = %d; max = %.2f Gy', ...
                  nEL, sliceIdx, max(doseSum(:))), ...
      'FontSize', 12);

hold(ax, 'off');

end