function hFig = matRad_plotRaysOverview(ax, stf)
% matRad_plotRaysOverview - Plot the middle spot of first, middle and last
%                           ray per beam, connected by a line per beam.
%                           Shape = ray position (first/mid/last).
%                           Color = beam index.
%
% Syntax:
%   hFig = matRad_plotRaysOverview(ax, stf)
%
% Description:
%   For each beam in stf, selects the first, middle and last ray by local
%   index. From each selected ray, only the middle spot is plotted.
%   The three spots of the same beam are connected by a line (same color).
%   Shape encodes ray position (first/mid/last), color encodes beam index.
%   No weights used — uniform marker size.
%
% Inputs:
%   ax  - Handle to target axes (pass [] to use gca)
%   stf - matRad steering file struct (1 x nBeams)
%
% Outputs:
%   hFig - handle to the figure
%
% Reference entry:
% | — | `matRad_plotRaysOverview` | Middle spot of first/mid/last ray per beam, connected by line; shape=position, color=beam | `hFig = matRad_plotRaysOverview(ax, stf)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if ~exist('ax','var') || isempty(ax)
    ax = gca;
end

hold(ax, 'on');

nBeams     = numel(stf);
beamColors = lines(nBeams);

posLabels = {'First ray', 'Middle ray', 'Last ray'};
posShapes = {'o', 's', '^'};

beamLegHandles = gobjects(nBeams, 1);
posLegHandles  = gobjects(3, 1);
posLegDone     = false(3, 1);

for iBeam = 1:nBeams
    nRays = stf(iBeam).numOfRays;
    c     = beamColors(iBeam, :);

    iMid         = round((nRays + 1) / 2);
    selectedRays = unique([1, iMid, nRays]);
    nSel         = numel(selectedRays);

    % --- Pre-collect middle spot positions for connecting line ---
    spotCoords = nan(nSel, 2);
    for iPosIdx = 1:nSel
        iRay     = selectedRays(iPosIdx);
        ray      = stf(iBeam).ray(iRay);
        iSpotMid = round((numel(ray.energy) + 1) / 2);
        spot     = getSpotPos(ray, iSpotMid);
        if ~isempty(spot)
            spotCoords(iPosIdx, :) = spot(1:2);
        end
    end

    % Draw connecting line (behind markers, same beam color)
    plot(ax, spotCoords(:,1), spotCoords(:,2), '-', ...
        'Color',     c, ...
        'LineWidth', 1.2);

    % --- Plot markers on top ---
    for iPosIdx = 1:nSel
        iRay = selectedRays(iPosIdx);

        if     iRay == 1    ; posIdx = 1;
        elseif iRay == nRays; posIdx = 3;
        else                ; posIdx = 2;
        end

        shape = posShapes{posIdx};

        if any(isnan(spotCoords(iPosIdx,:)))
            continue;
        end

        h = plot(ax, spotCoords(iPosIdx,1), spotCoords(iPosIdx,2), shape, ...
            'Color',           c, ...
            'MarkerFaceColor', c, ...
            'MarkerSize',      9, ...
            'LineWidth',       1.6);

        beamLegHandles(iBeam) = h;

        if ~posLegDone(posIdx)
            posLegHandles(posIdx) = plot(ax, NaN, NaN, shape, ...
                'Color',           'k', ...
                'MarkerFaceColor', 'k', ...
                'MarkerSize',      9, ...
                'LineWidth',       1.6);
            posLegDone(posIdx) = true;
        end
    end
end

% --- Legend ---
legendHandles = [];
legendLabels  = {};

for iBeam = 1:nBeams
    if isgraphics(beamLegHandles(iBeam))
        hDummy = plot(ax, NaN, NaN, '-o', ...
            'Color',           beamColors(iBeam,:), ...
            'MarkerFaceColor', beamColors(iBeam,:), ...
            'MarkerSize', 7, 'LineWidth', 1.4);
        legendHandles(end+1) = hDummy;                         %#ok<AGROW>
        legendLabels{end+1}  = sprintf('Beam %d (%.0f°)', ... %#ok<AGROW>
            iBeam, stf(iBeam).gantryAngle);
    end
end

for iPosIdx = 1:3
    if posLegDone(iPosIdx)
        legendHandles(end+1) = posLegHandles(iPosIdx); %#ok<AGROW>
        legendLabels{end+1}  = posLabels{iPosIdx};      %#ok<AGROW>
    end
end

if ~isempty(legendHandles)
    legend(ax, legendHandles, legendLabels, ...
        'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 10);
end

title(ax, 'Ray overview: middle spot of first / middle / last ray per beam', ...
    'Interpreter', 'none', 'FontSize', 12);

hFig = ancestor(ax, 'figure');
end


% -------------------------------------------------------------------------
function spot = getSpotPos(ray, iSpot)
spot = [];
if isfield(ray, 'rayTracerInfo') && isfield(ray.rayTracerInfo, 'perSpot') ...
        && numel(ray.rayTracerInfo.perSpot) >= iSpot ...
        && isfield(ray.rayTracerInfo.perSpot(iSpot), 'spotCube')
    spot = ray.rayTracerInfo.perSpot(iSpot).spotCube;
    return;
end
if isfield(ray, 'spotsInfoGeo') && numel(ray.spotsInfoGeo) >= iSpot ...
        && isfield(ray.spotsInfoGeo(iSpot), 'spotCube')
    spot = ray.spotsInfoGeo(iSpot).spotCube;
end
end