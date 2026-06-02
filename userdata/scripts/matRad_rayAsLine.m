function hOut = matRad_rayAsLine(ax, stf, iBeamTarget, iRayTarget, lineWidth, showLegend)
% matRad_rayAsLine - Visualize one ray as a polyline through all spots
%
% Syntax:
%   hOut = matRad_rayAsLine(ax, stf, iBeamTarget, iRayTarget)
%   hOut = matRad_rayAsLine(ax, stf, iBeamTarget, iRayTarget, lineWidth)
%   hOut = matRad_rayAsLine(ax, stf, iBeamTarget, iRayTarget, lineWidth, showLegend)
%
% Description:
%   Plots one ray as a line through all of its spots in order.
%   Spot positions are extracted using matRad_extractRayPoints(ray),
%   which should return spotCube-based coordinates.
%
%   The first and last spots are highlighted:
%     - first spot : x
%     - last spot  : triangle (^)
%
%   The line color is based on the ray energy if available.
%
% Inputs:
%   ax           - Target axes handle
%   stf          - matRad steering file struct
%   iBeamTarget  - Beam index to plot
%   iRayTarget   - Ray index within the selected beam
%   lineWidth    - (optional) line width, default: 1.8
%   showLegend   - (optional) true/false, show legend, default: true
%
% Outputs:
%   hOut - struct with graphics handles:
%          .line
%          .first
%          .last
%
% Reference entry:
% | `matRad_plotRay` | `matRad_rayAsLine` | Plot one ray as a polyline through all spots | `hOut = matRad_rayAsLine(ax, stf, iBeamTarget, iRayTarget)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% Defaults
if ~exist('lineWidth','var') || isempty(lineWidth)
    lineWidth = 1.8;
end
if ~exist('showLegend','var') || isempty(showLegend)
    showLegend = true;
end

% Validation
if isempty(ax) || ~isvalid(ax)
    error('matRad_rayAsLine:InvalidAxes', ...
        'Invalid or missing axes handle.');
end

if iBeamTarget < 1 || iBeamTarget > numel(stf)
    error('matRad_rayAsLine:InvalidBeam', ...
        'iBeamTarget=%d is outside valid range 1..%d.', iBeamTarget, numel(stf));
end

nRaysBeam = numel(stf(iBeamTarget).ray);
if iRayTarget < 1 || iRayTarget > nRaysBeam
    error('matRad_rayAsLine:InvalidRay', ...
        'iRayTarget=%d is outside valid range 1..%d for beam %d.', ...
        iRayTarget, nRaysBeam, iBeamTarget);
end

hold(ax, 'on');

ray = stf(iBeamTarget).ray(iRayTarget);

% Extract positions and energies using your independent helper
[spotPos, spotEnergy] = matRad_extractRayPoints(ray);

hOut = struct('line', gobjects(1), 'first', gobjects(1), 'last', gobjects(1));

if isempty(spotPos) || size(spotPos,1) < 2
    warning('matRad_rayAsLine:NoPositions', ...
        'Not enough spot positions found for beam %d ray %d.', iBeamTarget, iRayTarget);
    return;
end

% Normalize to Nx3 if needed
if size(spotPos, 2) == 2
    spotPos(:,3) = NaN;
elseif size(spotPos, 2) > 3
    spotPos = spotPos(:,1:3);
end

% Remove invalid rows
validRows = all(isfinite(spotPos(:,1:2)), 2);
spotPos = spotPos(validRows, :);

if size(spotPos,1) < 2
    warning('matRad_rayAsLine:NoValidPositions', ...
        'Not enough valid spot coordinates found for beam %d ray %d.', ...
        iBeamTarget, iRayTarget);
    return;
end

% Choose a representative energy for the ray color
energy = NaN;
if ~isempty(spotEnergy)
    spotEnergy = spotEnergy(:);
    if ~isempty(spotEnergy)
        energy = spotEnergy(find(isfinite(spotEnergy), 1, 'first'));
    end
end

% Energy color map
try
    energyColorMap = matRad_machineColorMap(stf);
catch
    energyColorMap = containers.Map('KeyType','double','ValueType','any');
end

if isa(energyColorMap, 'containers.Map') && ~isnan(energy) && isKey(energyColorMap, energy)
    c = energyColorMap(energy);
else
    c = [0.2 0.2 0.2];
end

% Plot full polyline through all spots
hOut.line = plot(ax, spotPos(:,1), spotPos(:,2), '-', ...
    'Color', c, ...
    'LineWidth', lineWidth, ...
    'HandleVisibility', 'off');

% Mark first and last spots
p1 = spotPos(1, :);
p2 = spotPos(end, :);

hOut.first = plot(ax, p1(1), p1(2), 'x', ...
    'Color', c, ...
    'MarkerSize', 8, ...
    'LineWidth', 1.4, ...
    'HandleVisibility', 'off');

hOut.last = plot(ax, p2(1), p2(2), '^', ...
    'Color', c, ...
    'MarkerFaceColor', c, ...
    'MarkerSize', 7, ...
    'LineWidth', 1.2, ...
    'HandleVisibility', 'off');

% Optional legend
if showLegend
    hLegend = plot(ax, NaN, NaN, '-', ...
        'Color', c, ...
        'LineWidth', lineWidth);
    legend(ax, hLegend, sprintf('Beam %d Ray %d', iBeamTarget, iRayTarget), ...
        'Location', 'bestoutside', ...
        'Interpreter', 'none', ...
        'FontSize', 10);
end

axis(ax, 'equal');
axis(ax, 'tight');

end