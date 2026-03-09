function t = matRad_plotDoseEL(ct, cst, stf, topELStruct, qiStruct, nTarget, nRows, nCols)
% matRad_plotDoseEL  Visualize dose distributions per energy layer
%
% Syntax:
%   t = matRad_plotDoseEL(ct, cst, stf, topELStruct, qiByEL, nTarget)
%   t = matRad_plotDoseEL(ct, cst, stf, topELStruct, qiByEL, nTarget, nRows, nCols)
%   t = matRad_plotDoseEL(ct, cst, stf, topELStruct, qiMaxByELTarget)
%   t = matRad_plotDoseEL(ct, cst, stf, topELStruct, qiMaxByELTarget, [], nRows, nCols)
%
% Description:
%   Plots dose distributions for each energy layer in topELStruct, overlaid
%   with spots, choosing a slice around a reference dose in the target VOI.
%
%   The 5th input, qiStruct, can be:
%     1) qiByEL:        full metric struct (EL-major, VOI-minor),
%                       where qiByEL.(layer).(voiName).max exists.
%        -> In this case, you MUST provide nTarget (VOI name).
%
%     2) qiMaxByELTarget: struct containing only max doses
%                       qiMaxByELTarget.(layer).(voiName) = maxDose.
%        -> If each layer has exactly ONE VOI field, that VOI is used and
%           nTarget can be omitted or empty.
%        -> If any layer has multiple VOI fields, and nTarget is provided,
%           that VOI is used (if present). If nTarget is omitted/empty,
%           an error is thrown (ambiguous).
%
% Inputs:
%   ct          - CT struct
%   cst         - CST cell array (full VOI set)
%   stf         - beam geometry struct
%   topELStruct - struct with per-EL dose cubes and weights
%   qiStruct    - either:
%                   (a) qiByEL.(ELname).(voiName).max
%                or (b) qiMaxByELTarget.(ELname).(voiName) = maxDose
%   nTarget     - (optional) string with name of target VOI (e.g. 'GTV')
%   nRows       - (optional) number of rows in subplot grid
%   nCols       - (optional) number of columns in subplot grid
%
% Output:
%   t - tiledlayout handle
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

ELNames = fieldnames(topELStruct);

% Detect struct type: qiByEL vs qiMaxByELTarget
% We infer by looking at one layer and one VOI field:
layerProbe = ELNames{1};
voiFieldsProbe = fieldnames(qiStruct.(layerProbe));

if isempty(voiFieldsProbe)
    error('qiStruct for layer %s has no VOI fields.', layerProbe);
end

% Check if qiStruct contains "mean" field to decide if this is qiByEL
% (qiByEL has full metrics: .mean, .std, .max, etc.; qiMaxByELTarget only scalar)
isQiByEL = isstruct(qiStruct.(layerProbe).(voiFieldsProbe{1})) && ...
           isfield(qiStruct.(layerProbe).(voiFieldsProbe{1}), 'mean');

% Input consistency checks
if isQiByEL
    % qiByEL case: we require nTarget
    if nargin < 6 || isempty(nTarget)
        error('For qiByEL input, nTarget (VOI name) must be provided.');
    end
else
    % qiMaxByELTarget case: nTarget is optional
    if nargin < 6
        nTarget = [];
    end
end

% Choose subplot layout
if nargin < 8 || isempty(nRows) || isempty(nCols)
    r = 2;
    c = 2;
else
    r = nRows;
    c = nCols;
end

figure('Color','w', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
t = tiledlayout(r,c);

for j = 1:numel(ELNames)
    layer = ELNames{j};
    dose  = topELStruct.(layer).RBExDose;
    wEL   = topELStruct.(layer).w;

    % ---------------------------------------------------------------------
    % Select reference dose depending on struct type
    % ---------------------------------------------------------------------
    if isQiByEL
        % Full qiByEL: must use explicit target
        if ~isfield(qiStruct.(layer), nTarget)
            warning('Assuming target name matchesVOI "%s" not found in qiByEL for layer "%s".', nTarget, layer);
        end
        refDose = qiStruct.(layer).(nTarget).max;

    else
        % qiMaxByELTarget: may have one VOI per layer
        voiFields = fieldnames(qiStruct.(layer));

        if numel(voiFields) == 1 && (isempty(nTarget) || ~isfield(qiStruct.(layer), nTarget))
            % Only one VOI in this layer, and no (or invalid) nTarget:
            % just use that single VOI's max for this layer
            singleVOI = voiFields{1};
            refDose = qiStruct.(layer).(singleVOI);
            warning('Assuming target name matches "%s".', voiFields{1});
        else
            % More than one VOI for this layer OR a valid nTarget was given
            if isempty(nTarget)
                error(['qiMaxByELTarget for layer "%s" contains multiple VOIs (%s). ' ...
                       'Please provide nTarget to disambiguate.'], ...
                       layer, strjoin(voiFields, ', '));
            end

            if ~isfield(qiStruct.(layer), nTarget)
                error('VOI "%s" not found in qiMaxByELTarget for layer "%s".', nTarget, layer);
            end

            refDose = qiStruct.(layer).(nTarget);
        end
    end
    % ---------------------------------------------------------------------

    % Get relevant slices around that reference dose
    allSlices = matRad_getRelevantSlices(cst, ct, dose, refDose);

    mDose = zeros(numel(allSlices),1);
    for g = 1:numel(allSlices)
        dose_slice = squeeze(dose(:,:, allSlices(g)));
        mDose(g) = max(dose_slice(:));
    end
    [~, ixSlice] = max(mDose);
    slice = allSlices(ixSlice);

    % Plot dose slice with spots
    ax = nexttile;
    matRad_showSliceFast(ct, cst, dose, slice);
    markerSize = 8;
    medianCoords = matRad_plotSpotsSlice(ax, ct, stf, markerSize, wEL, [], [], slice);

    % Zoom around spot cluster
    [xlimVals, ylimVals] = matRad_getZoomWindow(medianCoords(1), medianCoords(2), ct, 30);
    if xlimVals(2) > xlimVals(1) && ylimVals(2) > ylimVals(1)
        set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
    end

    % Prettier EL name
    layerStr = regexprep(regexprep(layer, 'EL_', 'EL '), '_', '.');
    title(['EL = ', layerStr, '; slice = ', num2str(slice), ...
           '; maxDose = ', num2str(round(max(dose(:)), 2)) ' Gy'])

    if mod(j, 4) == 0
        figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
        t = tiledlayout(r,c);
    end
end

end