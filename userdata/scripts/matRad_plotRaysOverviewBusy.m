function hFig = matRad_plotRaysOverviewBusy(ax, stf)
% matRad_plotRaysOverview - Plot first, middle and last ray for each beam
%                           on a shared CT/dose slice. Same ray position
%                           (first/mid/last) shares the same marker shape
%                           across all beams. Each beam gets a unique color.
%
% Syntax:
%   hFig = matRad_plotRaysOverview(ax, stf)
%   hFig = matRad_plotRaysOverview(ax, stf, doseCube, ct, cst)
%
% Description:
%   For each beam in stf, selects the first, middle and last ray by local
%   index. Plots all spots of each selected ray on the given axes.
%   Ray position (first/mid/last) determines marker shape (shared across
%   beams). Beam index determines marker color (unique per beam).
%   No weights are used — all spots are plotted at uniform marker size.
%   A legend is generated with one entry per beam (color) and one entry
%   per ray position (shape).
%
% Inputs:
%   ax       - Handle to target axes (if empty, uses gca)
%   stf      - matRad steering file struct (1 x nBeams)
%   doseCube - (optional) dose cube to pass to matRad_showSliceFast
%   ct       - (optional) CT struct, required if doseCube is provided
%   cst      - (optional) CST cell array, required if doseCube is provided
%
% Outputs:
%   hFig - handle to the figure
%
% Reference entry:
% | — | `matRad_plotRaysOverview` | Plot first/mid/last ray per beam on shared slice; shape=ray position, color=beam | `hFig = matRad_plotRaysOverview(ax, stf, doseCube, ct, cst)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% --- Defaults ---
if ~exist('ax','var') || isempty(ax)
    ax = gca;
end

% --- Setup ---
hold(ax, 'on');

nBeams    = numel(stf);
beamColors = lines(nBeams);

% Ray position labels and shapes
posLabels = {'First ray', 'Middle ray', 'Last ray'};
posShapes = {'o', 's', '^'};   % circle=first, square=mid, triangle=last

% Storage for legend
beamLegHandles = gobjects(nBeams, 1);
posLegHandles  = gobjects(3, 1);
posLegDone     = false(3, 1);

% --- Main loop ---
for iBeam = 1:nBeams
    nRays = stf(iBeam).numOfRays;
    c     = beamColors(iBeam, :);

    % Compute first / middle / last indices
    iMid = round((nRays + 1) / 2);
    selectedRays = unique([1, iMid, nRays]);   % unique handles nRays==1 or 2

    for iPosIdx = 1:numel(selectedRays)
        iRay = selectedRays(iPosIdx);

        % Map iRay back to position label index (1=first, 2=mid, 3=last)
        if iRay == 1
            posIdx = 1;
        elseif iRay == nRays
            posIdx = 3;
        else
            posIdx = 2;
        end

        shape = posShapes{posIdx};

        % Get ray and tracer info
        ray = stf(iBeam).ray(iRay);

        if ~isfield(ray, 'rayTracerInfo') || ~isfield(ray.rayTracerInfo, 'perSpot')
            % Fallback: try spotsInfoGeo
            if ~isfield(ray, 'spotsInfoGeo')
                continue;
            end
            useGeo = true;
        else
            useGeo = false;
        end

        numSpots = numel(ray.energy);
        hFirst   = [];   % first plotted handle for this beam (for legend)

        for iSpot = 1:numSpots
            % Get spot cube position
            spot = [];
            if ~useGeo
                tracer = ray.rayTracerInfo;
                if numel(tracer.perSpot) >= iSpot && isfield(tracer.perSpot(iSpot), 'spotCube')
                    spot = tracer.perSpot(iSpot).spotCube;
                end
            end
            if isempty(spot) && isfield(ray, 'spotsInfoGeo') && numel(ray.spotsInfoGeo) >= iSpot
                if isfield(ray.spotsInfoGeo(iSpot), 'spotCube')
                    spot = ray.spotsInfoGeo(iSpot).spotCube;
                end
            end
            if isempty(spot)
                continue;
            end

            h = plot(ax, spot(1), spot(2), shape, ...
                'Color',     c, ...
                'MarkerSize', 6, ...
                'LineWidth',  1.4);

            if isempty(hFirst)
                hFirst = h;
            end
        end

        % Beam legend handle: use first plotted handle of this beam
        % (overwrite each time — last ray position plotted wins, but color is same)
        if ~isempty(hFirst)
            beamLegHandles(iBeam) = hFirst;
        end

        % Position legend: invisible dummy with black color, correct shape
        if ~posLegDone(posIdx)
            posLegHandles(posIdx) = plot(ax, NaN, NaN, shape, ...
                'Color',     'k', ...
                'MarkerSize', 8, ...
                'LineWidth',  1.6);
            posLegDone(posIdx) = true;
        end
    end
end

% --- Legend ---
legendHandles = [];
legendLabels  = {};

% Beam entries (colored)
for iBeam = 1:nBeams
    if isgraphics(beamLegHandles(iBeam))
        % Make a clean dummy with filled marker for visibility
        hDummy = plot(ax, NaN, NaN, 'o', ...
            'Color',           beamColors(iBeam,:), ...
            'MarkerFaceColor', beamColors(iBeam,:), ...
            'MarkerSize', 8, 'LineWidth', 1.4);
        legendHandles(end+1) = hDummy;                          %#ok<AGROW>
        legendLabels{end+1}  = sprintf('Beam %d (%.0f°)', ...   %#ok<AGROW>
            iBeam, stf(iBeam).gantryAngle);
    end
end

% Position entries (black shapes)
for iPosIdx = 1:3
    if posLegDone(iPosIdx)
        legendHandles(end+1) = posLegHandles(iPosIdx);  %#ok<AGROW>
        legendLabels{end+1}  = posLabels{iPosIdx};       %#ok<AGROW>
    end
end

if ~isempty(legendHandles)
    legend(ax, legendHandles, legendLabels, ...
        'Location',    'bestoutside', ...
        'Interpreter', 'none', ...
        'FontSize',    10);
end

title(ax, 'Ray overview: first / middle / last ray per beam', ...
    'Interpreter', 'none', 'FontSize', 13);

hFig = ancestor(ax, 'figure');
end