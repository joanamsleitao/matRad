function [doseFLASH, flashMask, report] = matRad_FLASH_restoredoseOnly(doseEff, DMF, doseThr, doPlot, sliceIdx)
% Reconstruct physical FLASH dose from a FLASH-modified dose cube
% using only the DMF and dose threshold (no dose-rate available).
%
% INPUTS
%   doseEff  : 3D array, FLASH-modified dose (after DMF applied)
%   DMF      : scalar, FLASH modifying factor (e.g. 2.0)
%   doseThr  : scalar, FLASH dose threshold in Gy (default = 10)
%   doPlot   : logical, if true make QC plot (default = false)
%   sliceIdx : index for z-slice to plot (default = middle slice)
%
% OUTPUTS
%   doseFLASH : 3D array, reconstructed pre-DMF FLASH dose
%   flashMask : logical 3D array, voxels assumed FLASH-eligible
%   report    : struct with summary stats

if nargin < 3 || isempty(doseThr)
    doseThr = 10; % Gy
end
if nargin < 4 || isempty(doPlot)
    doPlot = false;
end
if nargin < 5 || isempty(sliceIdx)
    sliceIdx = round(size(doseEff,3)/2);
end

% Build FLASH eligibility mask (dose-only heuristic)
flashMask = (doseEff * DMF) >= doseThr;

% Reconstruct: multiply back only in FLASH voxels
doseFLASH = doseEff;
doseFLASH(flashMask) = doseEff(flashMask) * DMF;

% Report
numVox   = numel(doseEff);
numF     = nnz(flashMask);
fracF    = 100 * numF / numVox;
delta    = doseFLASH - doseEff;
sumDelta = sum(delta(:),'omitnan');

report = struct();
report.DMF           = DMF;
report.DoseThreshold = doseThr;
report.numVoxels     = numVox;
report.numFLASH      = numF;
report.percFLASH     = fracF;
report.totalDoseGain = sumDelta;
report.meanGainFLASH = mean(delta(flashMask),'omitnan');
report.maxGainFLASH  = max(delta(flashMask),[],'omitnan');

fprintf('FLASH restore (dose-only): DMF=%.1f, DoseThr=%.1f Gy\n', DMF, doseThr);
fprintf('Voxels above threshold: %d (%.2f%%)\n', numF, fracF);
fprintf('Total added dose by DMF inversion: %.3f Gy (mean per FLASH voxel: %.3f Gy)\n', ...
    report.totalDoseGain, report.meanGainFLASH);

%% QC PLOT
if doPlot
    figure('Name','FLASH Restoration QC','Color','w');
    imagesc(doseEff(:,:,sliceIdx));
    colormap(gray); axis equal tight;
    hold on;
    h = imagesc(flashMask(:,:,sliceIdx));
    set(h,'AlphaData',0.4); % transparency
    colormap(gca,gray);
    caxis([0 max(doseEff(:))]);
    title(sprintf('DoseEff + FLASH mask (slice %d)',sliceIdx));
    colorbar;
end
end
