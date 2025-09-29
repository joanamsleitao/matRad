function [doseFLASH, flashMask, report] = matRad_restoreFLASH_detectDMF(doseEff, cst, ixTarget, varargin)
% MATRAD_RESTOREFLASH_DETECTDMF - Reconstruct FLASH physical dose by detecting voxels
%                                  where a DMF was likely applied (dose-only heuristics).
%
% Syntax:
%   [doseFLASH, flashMask, report] = matRad_restoreFLASH_detectDMF(doseEff, cst, ixTarget)
%   [doseFLASH, flashMask, report] = matRad_restoreFLASH_detectDMF(..., 'DMF', 2.0, 'DoseThr', 10, ...
%                                                           'Method', 'valley', 'Params', p, 'DoPlot', true, 'ct', ct)
%
% Inputs:
%   doseEff  - 3D array: dose after DMF application (Gy)
%   cst      - constraint structure table (cell array). Used to exclude targets.
%   ixTarget - indices (vector) into CST identifying target rows to exclude
%
% Name-value optional inputs:
%   'DMF'    - scalar, FLASH modifying factor (default 2.0)
%   'DoseThr'- FLASH dose threshold in Gy (default 10)
%   'Method' - one of {'threshold','valley','morph'} (default 'valley')
%   'Params' - struct of method-specific parameters:
%                for 'valley': .neighSize (odd integer, default 7), .minContrast (Gy, default 1.0),
%                              .minRelContrast (fraction of neighMax, default 0.15)
%                for 'morph' : .minRegionVox (voxels, default 10), .seRadius (structuring element radius default 3)
%                for 'threshold': none (uses dose*DMF >= DoseThr)
%   'DoPlot' - logical, show QC figure (default false)
%   'ct'     - ct struct (optional). If provided used to compute iso-slice for plotting.
%
% Outputs:
%   doseFLASH - reconstructed dose cube (3D) where detected DMF voxels are multiplied by DMF
%   flashMask - logical 3D mask of voxels considered DMF-applied
%   report    - struct containing method, parameters used, voxel counts and dose differences
%
% Notes:
%  - This uses dose-only heuristics (you said you don't have dose-rate).
%  - The function excludes voxels inside the targets listed by ixTarget.
%  - Tweak Params to adjust sensitivity.
%
% Example:
%   [doseFLASH, mask, rep] = matRad_restoreFLASH_detectDMF(doseEff, cst, [ixGTV ixPTV], 'Method','valley',...
%                                                           'DMF',2.0,'DoseThr',10,'DoPlot',true,'ct',ct);
%

%% --- parse inputs
p = inputParser;
p.addRequired('doseEff', @(x) isnumeric(x) && ndims(x)==3);
p.addRequired('cst', @iscell);
p.addRequired('ixTarget', @(x)isnumeric(x) || islogical(x));

p.addParameter('DMF', 2.0, @(x)isnumeric(x) && isscalar(x) && x>0);
p.addParameter('DoseThr', 10, @(x)isnumeric(x) && isscalar(x) && x>=0);
p.addParameter('Method', 'valley', @(s) any(strcmpi(s, {'threshold','valley','morph'})));
p.addParameter('Params', struct(), @isstruct);
p.addParameter('DoPlot', false, @islogical);
p.addParameter('ct', [], @(x)isstruct(x) || isempty(x));
p.parse(doseEff, cst, ixTarget, varargin{:});

DMF      = p.Results.DMF;
doseThr  = p.Results.DoseThr;
method   = lower(p.Results.Method);
params   = p.Results.Params;
doPlot   = p.Results.DoPlot;
ct       = p.Results.ct;

sz = size(doseEff);
doseFLASH = doseEff;                 % initialize
flashMask = false(sz);

%% --- exclude target voxels
targetMask = false(sz);
if ~isempty(ixTarget)
    % ixTarget can be indices into cst rows
    if islogical(ixTarget)
        idxTargets = find(ixTarget);
    else
        idxTargets = ixTarget(:).';
    end
    for k = idxTargets
        if k <= size(cst,1) && ~isempty(cst{k,4}) && ~isempty(cst{k,4}{1})
            vox = cst{k,4}{1};
            targetMask(vox) = true;
        end
    end
end

%% --- base candidate: voxels whose reconstructed pre-DMF dose >= threshold
% If pre-DMF dose would be >= doseThr then (doseEff * DMF) >= doseThr
baseCandidate = (doseEff * DMF) >= doseThr;
baseCandidate(targetMask) = false;   % remove targets

%% --- method-specific detection
switch method
    case 'threshold'
        % Simple: any voxel that would be >= doseThr when multiplied by DMF
        flashMask = baseCandidate;

    case 'valley'
        % Look for voxels that are local valleys inside a high-dose neighborhood.
        % Heuristic: voxel must be baseCandidate AND
        %           neighMax - doseEff >= minContrast (absolute) AND
        %           (neighMax - doseEff) / max(neighMax,eps) >= minRelContrast
        % Neighborhood is a cubic window of size neighSize (odd)
        neighSize = 7;
        minContrast = 1.0;
        minRelContrast = 0.15;
        if isfield(params,'neighSize'), neighSize = params.neighSize; end
        if isfield(params,'minContrast'), minContrast = params.minContrast; end
        if isfield(params,'minRelContrast'), minRelContrast = params.minRelContrast; end
        if mod(neighSize,2)==0, neighSize = neighSize+1; end

        % compute neighborhood max (fast via imdilate)
        se = ones(neighSize,neighSize,neighSize);
        neighMax = imdilate(doseEff, se);

        contrastAbs = neighMax - doseEff;
        contrastRel = contrastAbs ./ max(neighMax, eps);

        % Candidate where contrast sufficient and also baseCandidate
        flashMask = baseCandidate & (contrastAbs >= minContrast) & (contrastRel >= minRelContrast);

        % remove tiny isolated voxels: require neighborhood majority > 0
        se2 = strel('sphere', max(1, round(neighSize/4)));
        flashMask = imopen(flashMask, se2); % remove small speckles

    case 'morph'
        % Morphological depressions inside high-dose connected regions.
        % Steps:
        %  1) threshold doseEff to create high-dose region (pre-DMF threshold using DMF)
        %  2) perform morphological opening/closing to find cavities
        %  3) connected components smaller than minRegionVox are ignored
        minRegionVox = 10;
        seRadius = 3;
        if isfield(params,'minRegionVox'), minRegionVox = params.minRegionVox; end
        if isfield(params,'seRadius'), seRadius = params.seRadius; end

        highRegion = (doseEff * DMF) >= doseThr; % candidate high-dose region
        highRegion(targetMask) = false;

        % smooth region and fill small holes
        se = strel('sphere', seRadius);
        highRegionClosed = imclose(highRegion, se);
        highRegionOpen = imopen(highRegionClosed, se);

        % find holes in the region: holes = region - openedRegion
        holes = highRegionOpen & ~imopen(highRegionOpen, strel('sphere',1));
        % Alternatively compute morphological reconstruction to find cavities:
        distMap = -bwdist(~highRegionOpen);
        % Candidate holes where local dose is well below surrounding:
        holeCandidates = highRegion & ~imdilate(highRegionOpen, strel('sphere',1));
        % But more robust: detect connected components inside a mask of baseCandidate
        cc = bwconncomp(baseCandidate & ~targetMask);
        mask = false(sz);
        for comp = 1:cc.NumObjects
            vox = cc.PixelIdxList{comp};
            % if the region has internal minima (i.e. doseEff min much lower than neigh max)
            regionVals = doseEff(vox);
            regionMax = max(regionVals);
            regionMin = min(regionVals);
            if (regionMax - regionMin) >= (0.5 * regionMax) && numel(vox) >= minRegionVox
                % consider the lower half of voxels in the region as likely DMF-affected
                thrRegion = regionMin + 0.5*(regionMax-regionMin);
                mask(vox(regionVals <= thrRegion)) = true;
            end
        end
        flashMask = mask;

    otherwise
        error('Unknown method %s', method);
end

%% --- Post-filtering tidy-up
% remove any target voxels again (safety)
flashMask(targetMask) = false;

% optionally remove isolated single voxels (speckles)
flashMask = bwareaopen(flashMask, 4); % remove components smaller than 4 voxels

% reassign doseFLASH (multiply only in mask)
doseFLASH = doseEff;
doseFLASH(flashMask) = doseEff(flashMask) * DMF;

%% --- Report
delta = doseFLASH - doseEff;
report = struct();
report.method = method;
report.params = params;
report.DMF = DMF;
report.DoseThr = doseThr;
report.numVoxels = numel(doseEff);
report.numFlash = nnz(flashMask);
report.fracFlash = 100 * report.numFlash / report.numVoxels;
report.totalDoseAdded = sum(delta(:),'omitnan');
if report.numFlash>0
    report.meanAddedPerFlashVoxel = mean(delta(flashMask),'omitnan');
    report.maxAddedPerFlashVoxel  = max(delta(flashMask));
else
    report.meanAddedPerFlashVoxel = 0;
    report.maxAddedPerFlashVoxel = 0;
end

%% --- QC plot
if doPlot
    % choose a Z slice where most detected voxels lie (median z of mask)
    if report.numFlash>0
        [~, zsub] = ind2sub(sz, find(flashMask));
        sliceZ = round(median(zsub));
    else
        sliceZ = round(sz(3)/2);
    end

    figure('Name','FLASH DMF detection QC','Color','w','Units','normalized','Position',[0.1 0.1 0.7 0.7]);

    % left: dose after DMF with mask overlay
    ax1 = subplot(2,2,1);
    imagesc(doseEff(:,:,sliceZ)); axis image off; colormap(ax1, hot);
    title(ax1, sprintf('doseEff (slice %d) - after DMF', sliceZ));
    colorbar;
    hold on;
    h = imagesc(flashMask(:,:,sliceZ));
    set(h,'AlphaData',0.35);
    colormap(gca, gray);

    % middle: reconstructed dose FLASH
    ax2 = subplot(2,2,2);
        % figure; matRad_showSliceFast(ct, cst, doseFLASH);

    imagesc(doseFLASH(:,:,sliceZ)); axis image off; colormap(ax2, hot);
    title(ax2, 'doseFLASH (reconstructed)'); colorbar;

    % right top: difference (restored - eff)
    ax3 = subplot(2,2,3);
    imagesc(doseFLASH(:,:,sliceZ)-doseEff(:,:,sliceZ)); axis image off; colormap(ax3, jet);
    title(ax3, 'difference (reconstructed - eff)'); colorbar;

    % right bottom: zoom the mask bounding box if available
    ax4 = subplot(2,2,4);
    if report.numFlash>0
        [x,y,z] = ind2sub(sz, find(flashMask));
        xmin = max(min(x)-10,1); xmax = min(max(x)+10,sz(1));
        ymin = max(min(y)-10,1); ymax = min(max(y)+10,sz(2));
        imagesc(doseFLASH(ymin:ymax,xmin:xmax,sliceZ)'); axis image off;
        title(ax4,'zoom (reconstructed)'); colorbar;
    else
        text(0.1,0.5,'No FLASH voxels detected','FontSize',12);
        axis off;
    end
end

end
