function [maskExternalFixed, cstOut, alteredSlices] = matRad_fixExternalMask(ct, cst, HUrange, sliceList)
% matRad_fixExternalMask - Repair missing voxels or gaps in External contour.
%
% Syntax:
%   [cstOut, maskExternalFixed, alteredSlices] = matRad_fixExternalMask(ct, cst, ixExternal, ctIndex, sliceList, HUrange)
%
% Inputs:
%   ct           - matRad CT struct
%   cst          - matRad CST cell array
%   ixExternal   - index of External VOI in CST
%   ctIndex      - index of CT cube used in cst{ixExternal,4}
%   sliceList    - list of slices to check/fix (default: all)
%   HUrange      - [min max] HU values for body (default: [-100 500])
%
% Outputs:
%   cstOut            - updated CST (with new "External_fixed" VOI)
%   maskExternalFixed - full 3D logical mask for the repaired External
%   alteredSlices     - list of slice numbers that were modified
%
% ------------------------------------------------------------------------
% Notes:
%   - Fills holes, adds missing voxels (within HU range), removes stray bits.
%   - The new CST line is appended as "External_fixed".
%   -> How to use
%       [maskExternalFixed, cstOut] = matRad_fixExternalMask(ct, cst);
%       ixExternal = matRad_VOIFindIx(cst, {'Body', 'body', 'external', 'External', 'skin'});
%       cst{ixExternal, 4}{1} = find(maskExternalFixed);  % update voxel indices
%
%
% Author: Joana Leitão
% ------------------------------------------------------------------------

if nargin < 4 || isempty(sliceList)
    sliceList = 1:ct.cubeDim(3);
end

if nargin < 3
    HUrange = [-100 500];
    %     HUrange = [-200 500];
end

ctIndex = ct.numOfCtScen;
ixExternal = matRad_VOIFindIx(cst, {'Body', 'body', 'external', 'External', 'skin'});

% --- Initialize
maskExternal = zeros(ct.cubeDim);
maskExternal(cst{ixExternal,4}{ctIndex}) = 1;
maskExternalFixed = maskExternal;  % start from original
alteredSlices = [];

fprintf('\nChecking External structure integrity...\n');
for s = sliceList
    ctSlice   = squeeze(ct.cubeHU{ctIndex}(:,:,s));
    maskSlice = maskExternal(:,:,s);

    % Define tissue region by HU threshold
    bodyMask = ctSlice > HUrange(1) & ctSlice < HUrange(2);

    % Voxels missing from external but within body
    missingVoxels = bodyMask & ~maskSlice;

    % Voxels present in external but outside HU range (too air or bone)
    excessVoxels = maskSlice & ~bodyMask;

    % if s < 126
    % Combine to define corrected mask
    if any(missingVoxels(:)) || any(excessVoxels(:))
        maskFixed = maskSlice;
        maskFixed(missingVoxels) = true;   % add missing
        maskFixed(excessVoxels)  = false;  % remove stray

        % Morphological cleanup
        maskFixed = imfill(maskFixed, 'holes');
        maskFixed = bwareaopen(maskFixed, 30);
        se = strel('disk', 1);
        maskFixed = imopen(maskFixed, se);
        maskFixed = imclose(maskFixed, se);

        % Keep only the largest connected component (the true body)
        cc = bwconncomp(maskFixed);
        if cc.NumObjects > 1
            % Find largest region by voxel count
            numPix = cellfun(@numel, cc.PixelIdxList);
            [~, idxLargest] = max(numPix);
            maskClean = false(size(maskFixed));
            maskClean(cc.PixelIdxList{idxLargest}) = true;
            maskFixed = maskClean;
        end
        % end

        % Save fixed slice
        maskExternalFixed(:,:,s) = maskFixed;
        alteredSlices(end+1) = s; %#ok<AGROW>
    end


    % if s > 127
    %     cstOut = cst;
    %     newLine = cst(ixExternal,:);
    %     newLine{2} = [newLine{2} '_fixed'];  % new name
    %     newLine{4}{ctIndex} = find(maskExternalFixed);  % update voxel indices
    %     newLine{5}.visibleColor = [0 0 1];
    %     cstOut = [cstOut; newLine];
    %
    %     figure; matRad_showSliceFast(ct, cstOut, [], s);
    %     g = 1;
    % end
end

% --- Create new CST entry
cstOut = cst;
newLine = cst(ixExternal,:);
newLine{2} = [newLine{2} '_fixed'];  % new name
newLine{4}{ctIndex} = find(maskExternalFixed);  % update voxel indices
newLine{5}.visibleColor = [0.9 0 1];
cstOut = [cstOut; newLine];


% figure; matRad_showSliceFast(ct, cstOut, [], [131]);

% --- Summary
if isempty(alteredSlices)
    fprintf('No slices needed correction.\n');
else
    fprintf('External structure fixed on slices: %s\n', num2str(alteredSlices));
    fprintf('New CST line added: "%s"\n', newLine{2});
end

end
