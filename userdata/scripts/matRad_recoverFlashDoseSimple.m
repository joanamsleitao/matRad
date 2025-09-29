function [doseFLASH, doseDiff, flashVoxels] = matRad_recoverFlashDoseSimple(ct, cst, doseEff, DMF, FLASHthresh, doPlot)
% matRad_recoverFlashDoseSimple
%   Reconstruct the dose before DMF reduction using a threshold-based approach.
%
% INPUTS
%   ct         - CT struct
%   cst        - contour struct
%   doseEff    - dose cube after DMF
%   DMF        - FLASH modifying factor (e.g., 2.0)
%   FLASHthresh- dose threshold [Gy] above which FLASH was assumed active
%   doPlot     - boolean, whether to show QC plots
%
% OUTPUTS
%   doseFLASH     - reconstructed dose cube (pre-DMF)
%   doseDiff      - difference between pre- and post-DMF
%   flashVoxels   - logical mask of voxels affected by FLASH (DMF applied)

%% Step 1: Identify FLASH-effect voxels
flashVoxels = (doseEff * DMF > FLASHthresh);

%% Step 2: Compute dose difference
doseDiff = zeros(size(doseEff));
doseDiff(flashVoxels) = doseEff(flashVoxels) * (DMF - 1);

%% Step 3: Reconstruct doseFLASH
doseFLASH = doseEff + doseDiff;

%% Step 4: QC plot
if doPlot
    slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = slice(3);

    figure('Name','FLASH Recovery QC','Color','w','Units','normalized','Position',[0 0 0.8 0.6]);

    % Original DMF dose
    ax1 = subplot(1,3,1);
    matRad_showSliceFast(ct, cst, doseEff, slice);
    title(ax1,'DMF-altered dose');

    % Dose difference (doseFLASH - doseEff)
    ax2 = subplot(1,3,2);
    matRad_showSliceFast(ct, cst, doseDiff, slice);
    title(ax2,'Dose difference (recovered FLASH)');

    % Reconstructed FLASH dose
    ax3 = subplot(1,3,3);
    matRad_showSliceFast(ct, cst, doseFLASH, slice);
    hold on;
    % % Overlay FLASH voxels
    % maskSlice = flashVoxels(:,:,slice);
    % h = imagesc(maskSlice);
    % set(h,'AlphaData',0.3*maskSlice);
    % colormap(ax3,'hot');
    % title(ax3,'Reconstructed FLASH dose + mask overlay');
end

%% Step 5: Info
fprintf('Number of FLASH-effect voxels: %d\n', nnz(flashVoxels));
fprintf('Mean dose difference in affected voxels: %.3f Gy\n', mean(doseDiff(flashVoxels)));
fprintf('Mean dose overall: %.3f → %.3f Gy\n', mean(doseEff(:)), mean(doseFLASH(:)));

end
