function [doseFLASH, doseDiff, flashMask] = matRad_recoverFlashDose(ct, cst, doseEff, DMF, FLASHthresh, doPlot)
% matRad_recoverFlashDose
%   Reconstruct original FLASH dose distribution from DMF-altered dose cube.
%
%%
% DMF = 2;
% FLASHthresh = 10;
% [doseFLASH, flashMask] = matRad_recoverFlashDose(ct, cst, doseFLASH, DMF, FLASHthresh, 1);
% INPUTS
%   ct         - CT struct
%   cst        - contour struct (with voxel indices in cst{i,4}{1})
%   doseEff    - dose cube AFTER DMF applied
%   DMF        - FLASH dose modifying factor (e.g. 2.0)
%   FLASHthresh- dose threshold [Gy] above which FLASH was assumed active
%   doPlot     - boolean flag for QC plotting
%
% OUTPUTS
%   doseFLASH  - reconstructed dose cube (before DMF reduction)
%   doseDiff   - difference between doseFLASH and doseEff
%   flashMask  - logical mask of voxels where DMF was applied (and now reverted)

%% Step 1: Build mask of target voxels (PTV + GTV)
targetMask = false(size(doseEff));
numVOI = size(cst, 1);
for i = 1:numVOI
    if contains(cst{i,3},'Target','IgnoreCase',true)
        targetMask(cst{i,4}{1}) = true;
    end
end

%% Step 2: Identify FLASH-affected voxels
% Voxels outside target where the dose *before DMF* would exceed threshold
doseOriginal = doseEff * DMF;                  % pre-DMF dose estimate
flashMask = (doseOriginal > FLASHthresh) & ... % would have been above threshold
            (doseEff < 7) & ...                 % currently below threshold due to DMF
            ~targetMask;                        % exclude targets
%% Step 3: Apply neighborhood filter (at least 3 neighbors)
% neighborKernel = ones(3,3,3);
% neighborKernel(2,2,2) = 0; % exclude center voxel
% neighborCount = convn(double(flashMask), neighborKernel, 'same');
% flashMask = flashMask & (neighborCount >= 3);

%% Step 3: Compute dose difference and reconstruct doseFLASH
doseDiff = zeros(size(doseEff));
doseDiff(flashMask) = doseOriginal(flashMask) - doseEff(flashMask);
doseFLASH = doseEff + doseDiff;

%% Step 4: QC info
fprintf('Number of FLASH-effect voxels: %d\n', nnz(flashMask));
fprintf('Mean dose difference in affected voxels: %.3f Gy\n', mean(doseDiff(flashMask)));
fprintf('Overall mean dose: %.3f → %.3f Gy\n', mean(doseEff(:)), mean(doseFLASH(:)));

%% Step 5: QC plot
if doPlot
    slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = slice(3);
    doseWindow = [0 max(doseFLASH(:))];

    figure('Name','FLASH Recovery QC','Color','w','Units','normalized','Position',[0 0 0.8 0.6]);
    matRad_showSliceFast(ct, cst, doseDiff, slice);

    % Left: DMF-altered dose
    ax1 = subplot(1,2,1);
    matRad_showSliceFast(ct, cst, doseEff, slice, doseWindow);
    title(ax1, sprintf('DMF-altered dose (slice %d)', slice));

    % Right: Recovered FLASH dose
    ax2 = subplot(1,2,2);
    matRad_showSliceFast(ct, cst, doseFLASH, slice, doseWindow);
    hold on;

    % % Overlay FLASH-effect voxels
    % maskSlice = flashMask(:,:,slice);
    % h = imagesc(maskSlice);
    % set(h,'AlphaData',0.3*maskSlice); 
    % colormap(ax2,'hot');
    % title(ax2, 'Recovered FLASH dose (mask overlay)');
end
end
