function hAx = matRad_plotSingleBeamRays(ct, cst, stf, iBeam)
% matRad_plotSingleBeamRays - Plot ray lines for a single beam
%
% Syntax:
%   hAx = matRad_plotSingleBeamRays(ct, cst, stf, iBeam)
%
% Description:
%   Plots each ray of beam iBeam as a line from rayPos to targetPoint.
%
% -------------------------------------------------------------------------

beam = stf(iBeam);
nRays = numel(beam.ray);

fig = figure('Color','w', 'Name', sprintf('Beam %d rays', iBeam));
hAx = axes(fig);
hold(hAx, 'on');

try
    matRad_showSliceFast(hAx, ct, cst, []);
catch
end

cmap = lines(nRays);

for iRay = 1:nRays
    ray = beam.ray(iRay);

    if isfield(ray, 'rayPos') && isfield(ray, 'targetPoint') && ...
       ~isempty(ray.rayPos) && ~isempty(ray.targetPoint)

        p1 = ray.rayPos(:)';
        p2 = ray.targetPoint(:)';

        % plot in XY (or whatever coordinate system rayPos/targetPoint use)
        plot(hAx, [p1(1) p2(1)], [p1(2) p2(2)], '-', ...
            'Color', cmap(iRay,:), 'LineWidth', 1.2);

        plot(hAx, p1(1), p1(2), 'o', ...
            'Color', cmap(iRay,:), 'MarkerFaceColor', cmap(iRay,:), 'MarkerSize', 4);
        plot(hAx, p2(1), p2(2), 's', ...
            'Color', cmap(iRay,:), 'MarkerFaceColor', cmap(iRay,:), 'MarkerSize', 4);
    end
end

title(hAx, sprintf('Beam %d - Rays', iBeam), 'FontWeight','bold');
axis(hAx, 'equal');
hold(hAx, 'off');
end