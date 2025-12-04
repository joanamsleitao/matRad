function hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesTarget, alteredSlices, plane)
% matRad_showAllPlanes - Visualize CT, CST, and optionally dose in 3 planes
%                        and highlight altered slices if provided
%
% Syntax:
%   hFig = matRad_showAllPlanes(ct, cst)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesTarget)
%   hFig = matRad_showAllPlanes(ct, cst, doseCube, nSlicesTarget, alteredSlices)
%
% Description:
%   Displays CT, CST, and optionally dose in the three anatomical planes.
%   If 'alteredSlices' is provided, those slices are visually highlighted
%   (title color + asterisk marker) in the axial plane.
%
% Inputs:
%   ct            - matRad CT struct
%   cst           - matRad CST (cell array of VOIs)
%   doseCube      - (optional) dose cube to overlay
%   nSlicesTarget - (optional) total target number of slices to show per plane (default: 30)
%   alteredSlices - (optional) indices of altered slices (only relevant for axial plane)
%
% Outputs:
%   hFig - struct with figure handles per plane and figure batch
%
% -------------------------------------------------------------------------
% Author: Joana Leitão & ChatGPT (2025)
% -------------------------------------------------------------------------

if nargin < 3 || isempty(doseCube)
    doseCube = [];
    doseWindow = [];
else
    doseWindow = [0 max(doseCube(:)) * 1.001]; % Safe dose range if present
end

if nargin < 4 || isempty(nSlicesTarget)
    nSlicesTarget = 30;
end

if nargin < 5 || isempty(plane)
    plane = 1:3;
end

if nargin < 5
    alteredSlices = [];
end

maxSlicesPerFigure = 10; % maximum tiles per figure
matRad_cfg = MatRad_Config.instance();
planeNames = {'axial','coronal','sagittal'};
cubeDim = ct.cubeDim;

% Isocenter for reference
if ~isempty(cst)
    isoCenter = matRad_world2cubeIndex(matRad_getIsoCenter(cst, ct, 0), ct);
else
    isoCenter = round(cubeDim ./ 2);
end

cstHandle = cst;

for thisPlane = plane
    nSlices = cubeDim(thisPlane);
    step = max(1, round(nSlices / nSlicesTarget));
    sliceIdx = 1:step:nSlices;
    numSlices = numel(sliceIdx);

    nFigs = ceil(numSlices / maxSlicesPerFigure);

    for f = 1:nFigs
        startIdx = (f-1)*maxSlicesPerFigure + 1;
        endIdx = min(f*maxSlicesPerFigure, numSlices);
        currentSlices = sliceIdx(startIdx:endIdx);

        % Create figure
        hFig.(planeNames{thisPlane})(f).fig = figure('Color', 'w', ...
            'Name', sprintf('CT & CST - %s plane (set %d)', planeNames{thisPlane}, f), ...
            'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

        nTiles = numel(currentSlices);
        nRows = ceil(nTiles / 5);
        nCols = min(nTiles, 5);

        t = tiledlayout(hFig.(planeNames{thisPlane})(f).fig, nRows, nCols, ...
            'TileSpacing', 'compact', 'Padding', 'compact');
        title(t, sprintf('%s plane (slices %d–%d)', ...
            planeNames{thisPlane}, currentSlices(1), currentSlices(end)), ...
            'Color', matRad_cfg.gui.highlightColor, 'FontWeight', 'bold');

        for i = 1:numel(currentSlices)
            nexttile;
            sliceNumber = currentSlices(i);
            hold on;

            % Plot slice
            matRad_plotSliceWrapper(gca, ct, cstHandle, 1, doseCube, ...
                thisPlane, sliceNumber);

            % Highlight altered slices in the axial plane
            if thisPlane == 3 && ismember(sliceNumber, alteredSlices)
                title(sprintf('Slice %d *', sliceNumber), ...
                    'Color', [0.9 0.4 0.0], 'FontWeight', 'bold'); % orange color
            else
                title(sprintf('Slice %d', sliceNumber), ...
                    'Color', matRad_cfg.gui.textColor);
            end
        end
    end
end

if isempty(alteredSlices)
    disp('✅ CT + CST slices displayed (no altered slices provided).');
else
    disp(['✅ CT + CST slices displayed — altered slices highlighted (n = ' num2str(numel(alteredSlices)) ').']);
end

end
