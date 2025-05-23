function matRad_plotEnergyLayerPositions(ax, ct, stf, markerSize)
% Plots a representative point (median position) for each energy layer in each beam

if nargin < 4
    markerSize = 10;
end

colors = lines(10);
shapes = {'o','+','s','^','v','x','d','p','h','*'};

hold(ax, 'on');

for iBeam = 1:numel(stf)
    shape = shapes{mod(iBeam-1, numel(shapes)) + 1};
    energyMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

    for iRay = 1:numel(stf(iBeam).ray)
        ray = stf(iBeam).ray(iRay);
        for iSpot = 1:numel(ray.energy)
            energy = ray.energy(iSpot);
            pos = ray.rayTracerInfo.perSpot(iSpot).spotCube;
            if isKey(energyMap, energy)
                energyMap(energy) = [energyMap(energy); pos'];
            else
                energyMap(energy) = pos';
            end
        end
    end

    % Plot one point per energy layer
    energyList = keys(energyMap);
    for i = 1:length(energyList)
        energy = energyList{i};
        colorIdx = mod(i-1, size(colors,1)) + 1;
        spots = energyMap(energy);
        medianSpot = median(spots, 1);
        plot(ax, medianSpot(1), medianSpot(2), shape, ...
             'Color', colors(colorIdx,:), ...
             'MarkerSize', markerSize, ...
             'MarkerFaceColor', colors(colorIdx,:), ...
             'LineWidth', 1.5);
    end
end

legend(ax, "off"); % optional: turn on if you want to build custom legends

end
