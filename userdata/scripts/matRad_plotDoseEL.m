function t = matRad_energyLayer_plotDoseEL(ct, cst, stf, topELStruct, qiByEL, nTarget, nRows, nCols)
% matRad_plotDosePerEL  Visualize dose distributions per energy layer
%
%   matRad_plotDosePerEL(ct, cst, stf, topELStruct, qiByEL, cstSmall, nTarget)
%   plots dose distributions for each energy layer in topELStruct, overlayed
%   with spots, choosing a slice around the maximum dose in the target VOI.
%
%   INPUTS:
%       ct          - CT struct
%       cst         - cst cell array (full VOI set)
%       stf         - beam geometry struct
%       topELStruct - struct with per-EL dose cubes and weights
%       qiByEL      - struct of per-VOI quality indices by EL
%       cstSmall    - reduced cst (subset with target + OARs)
%       nTarget     - string with name of target VOI in cstSmall (e.g. 'GTV')
%       nRows       - (optional) number of rows in subplot grid
%       nCols       - (optional) number of columns in subplot grid
%
%   Example:
%       matRad_plotDosePerEL(ct, cst, stf, topELStruct, qiByEL, cstSmall, 'GTV');
%
%   If nRows/nCols are not given, a sqrt-based grid layout is chosen.
%

ELNames = fieldnames(topELStruct);

% Choose subplot layout
if nargin < 8 || isempty(nRows) || isempty(nCols)
    r = round(sqrt(numel(ELNames)));
    c = ceil(sqrt(numel(ELNames)));
else
    r = nRows;
    c = nCols;
end

figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
t = tiledlayout(r,c);

for j = 1:numel(ELNames)
    layer = ELNames{j};
    dose  = topELStruct.(layer).RBExDose;
    wEL   = topELStruct.(layer).w;

    % Choose slice around max dose in target VOI
    refDose = qiByEL.(layer).(nTarget).max;
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
    
    xlimValsOg = get(ax, 'XLim');
    ylimValsOg = get(ax, 'YLim');

    % Zoom around spot cluster
    [xlimVals, ylimVals] = matRad_getZoomWindow(medianCoords(1), medianCoords(2), ct, 30);
        
    if xlimVals(2) > xlimVals(1) && ylimVals(2) > ylimVals(1)
        set(ax, 'XLim', xlimVals, 'YLim', ylimVals);
    end
    title(['EL = ', layer, '; slice = ', num2str(slice), ...
           '; maxDose = ', num2str(max(dose(:))) ' Gy'])
end

end
