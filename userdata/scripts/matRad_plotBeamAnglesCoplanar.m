function matRad_plotBeamAnglesCoplanar(ax, pln, ct, plane)
% matRad_plotBeamAnglesCoplanar - Plot colored coplanar beam-angle lines
%                                 on an axial CT/CST slice.
%
% Syntax:
%   matRad_plotBeamAnglesCoplanar(ax, pln, ct, plane)
%
% Description:
%   Overlays one colored line per beam onto the current axial slice.
%   Each line starts from the mean isocenter and extends in the beam's
%   gantry angle direction using standard matRad angle mapping.
%   A light gray dashed compass is shown near the image edge.
%   Non-overlapping beam labels are placed at the line tips.
%
% Inputs:
%   ax    - Handle to target axes
%   pln   - matRad plan structure
%   ct    - matRad CT structure
%   plane - View plane index (3 = axial)
%
% Outputs:
%   None
%
% Reference entry:
% | Previous Name | Current Name | Description | Call | Status |
% | --- | --- | --- | --- | --- |
% | matRad_plotProjectedGantryAngles | matRad_plotBeamAnglesCoplanar | Plot colored coplanar beam-angle lines on axial slice | `matRad_plotBeamAnglesCoplanar(ax, pln, ct, 3)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

if plane ~= 3
    return;
end

nBeams = numel(pln.propStf.gantryAngles);
if nBeams == 0
    return;
end

hold(ax, 'on');

% --- Isocenter ---
isoMean = mean(pln.propStf.isoCenter, 1);
cubeIso = matRad_world2cubeIndex(isoMean, ct);

% --- Radius (same as original) ---
r = 0.8 * min([abs([1 ct.cubeDim(1)]-cubeIso(1)) abs([1 ct.cubeDim(2)]-cubeIso(2))]);

% --- Colors ---
cmap = lines(max(nBeams, 1));

% --- Plot beams ---
hLines = gobjects(nBeams, 1);
hTexts = gobjects(nBeams, 1);

for iBeam = 1:nBeams
    ang = pln.propStf.gantryAngles(iBeam);

    % Use exact same formula as original
    x = [cubeIso(2), r * sind(180 - ang) + cubeIso(2)];
    y = [cubeIso(1), r * cosd(180 - ang) + cubeIso(1)];

    % Line
    hLines(iBeam) = plot(ax, x, y, '-.', ...
        'Color', cmap(iBeam, :), ...
        'LineWidth', 1.6);

    % Label at tip
    beamLabel = sprintf('Beam %d (%.0f°)', iBeam, ang);
    hTexts(iBeam) = text(ax, x(2), y(2), beamLabel, ...
        'Color', cmap(iBeam, :), ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'bottom', ...
        'Interpreter', 'none');
end

% --- Compass legend (larger, light gray, dashed) ---
compassRadius = 1.05 * r;

% Circle
theta = 0:360;
xCirc = compassRadius * cosd(theta) + cubeIso(2);
yCirc = compassRadius * sind(theta) + cubeIso(1);
plot(ax, xCirc, yCirc, ':', 'Color', [0.85 0.85 0.85], 'LineWidth', 1.5);

% Cardinal labels
cardinalAngs = [0, 90, 180, 270];
cardinalLbls = {'0°', '90°', '180°', '270°'};

for k = 1:4
    ang = cardinalAngs(k);
    xLbl = 1.15 * compassRadius * sind(180 - ang) + cubeIso(2);
    yLbl = 1.15 * compassRadius * cosd(180 - ang) + cubeIso(1);

    text(ax, xLbl, yLbl, cardinalLbls{k}, ...
        'Color', [0.85 0.85 0.85], ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle');
end

% --- Prevent label overlap ---
% localAvoidLabelOverlap(hTexts, ax);

end

% -------------------------------------------------------------------------
function localAvoidLabelOverlap(hTexts, ax)
% localAvoidLabelOverlap - Adjust text positions to reduce overlap
numTxt = numel(hTexts);
if numTxt <= 1
    return;
end

txtPos = zeros(numTxt, 2);
for i = 1:numTxt
    pos = get(hTexts(i), 'Position');
    txtPos(i, :) = pos(1:2);
end

xlims = get(ax, 'XLim');
ylims = get(ax, 'YLim');
dxUnit = 0.02 * diff(xlims);
dyUnit = 0.02 * diff(ylims);

changed = true;
iter = 0;
while changed && iter < 20
    changed = false;
    iter = iter + 1;

    for i = 1:numTxt
        for j = i+1:numTxt
            d = sqrt(sum((txtPos(i,:) - txtPos(j,:)).^2));
            if d < 1.5 * dxUnit
                % Push apart along x-axis
                shift = sign(txtPos(i,1) - txtPos(j,1) + eps) * dxUnit;
                txtPos(i,1) = txtPos(i,1) + shift;
                txtPos(j,1) = txtPos(j,1) - shift;

                % Also adjust y slightly
                shiftY = dyUnit * 0.5;
                txtPos(i,2) = txtPos(i,2) + shiftY;
                txtPos(j,2) = txtPos(j,2) - shiftY;

                changed = true;
            end
        end
    end
end

% Apply adjusted positions
for i = 1:numTxt
    set(hTexts(i), 'Position', [txtPos(i,:); 0]);
end
end