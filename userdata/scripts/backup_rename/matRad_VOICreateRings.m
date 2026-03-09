function [cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize, keepInnerVolume)
% matRad_VOICreateRings - Create concentric ring VOIs around (or inside) a reference structure
%
% Syntax:
%   [cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm)
%   [cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI)
%   [cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm)
%   [cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize)
%   [cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize, keepInnerVolume)
%
% Description:
%   Creates concentric ring VOIs around (expansion) or inside (contraction)
%   a reference structure.
%
%   - Positive margins: create *outer* rings (expansion shells outside the VOI)
%   - Negative margins: create *inner* rings (erosion shells inside the VOI)
%
%   For negative margins, by default the function returns the *ring shell*
%   (original VOI minus eroded VOI). If keepInnerVolume = true, it returns
%   the *eroded volume itself* (intersection with original VOI).
%
% Inputs:
%   ct                 - matRad CT structure
%   cst                - matRad CST cell array
%   ring_mm            - Ring margin(s) [mm] (double array; can be negative for contraction)
%   ixRefVOI           - Reference VOI index (integer, optional; defaults to first PTV)
%   marginPTVRing_mm   - Inner margin from PTV [mm] (double, optional; default: 0)
%                        Only applies to expansion rings (positive ring_mm)
%   visualize          - Visualization flag (logical, optional; default: false)
%   keepInnerVolume    - For negative margins: if true, keep the eroded volume
%                        (intersect with original); if false (default), keep
%                        the ring shell (setdiff). Ignored for positive margins.
%
% Outputs:
%   cst                - Updated CST with ring VOIs (cell array)
%   ringInfo           - Ring metadata structure (struct array)
%   ixAdded            - Indices of added VOIs in cst (row vector)
%
% Notes:
%   - Positive margins create *outer* rings (expansion).
%   - Negative margins create *inner* rings (erosion/contraction).
%       * Default (keepInnerVolume=false): ring = original ∩ ~eroded (shell)
%       * If keepInnerVolume=true: ring = eroded (inner volume only)
%   - marginPTVRing_mm defines an inner cutoff (ignored for negative rings).
%
% Reference List Entry:
%   | `N/A` | `matRad_VOICreateRings` | Create concentric ring VOIs around or inside a reference structure | `[cst, ringInfo, ixAdded] = matRad_VOICreateRings(ct, cst, ring_mm, ixRefVOI, marginPTVRing_mm, visualize, keepInnerVolume)` | 🟢 |
%
% Requires: matRad_addMargin.m
%
% -------------------------------------------------------------------------
% Author: Joana Leitão + GPT-5.1
% Date: 2025-12-07_0000
% -------------------------------------------------------------------------

    %% Input validation and defaults
    if nargin < 4 || isempty(ixRefVOI)
        ixRefVOI = find(strcmpi(cst(:,3), 'PTV'), 1);
        if isempty(ixRefVOI)
            error('matRad_VOICreateRings:NoPTV', ...
                'No PTV VOI found as default. Please specify ixRefVOI.');
        end
    end

    if nargin < 5 || isempty(marginPTVRing_mm)
        marginPTVRing_mm = 0;
    else
        if marginPTVRing_mm >= min(abs(ring_mm))
            warning('matRad_VOICreateRings:LargeMargin', ...
                'Margin from PTV (%.1f mm) close to or larger than smallest ring (%.1f mm). Check configuration.', ...
                marginPTVRing_mm, min(abs(ring_mm)));
        end
    end

    if nargin < 6 || isempty(visualize)
        visualize = false;
    end

    if nargin < 7 || isempty(keepInnerVolume)
        keepInnerVolume = false; % Default: return ring shell for negative margins
    end

    %% Initialize
    ixAdded = [];
    baseIndices = cst{ixRefVOI,4}{1};
    voiName = cst{ixRefVOI,2};

    % Convert linear indices to mask
    voiMask = false(ct.cubeDim);
    voiMask(baseIndices) = true;

    ringInfo = struct('name', {}, 'margin_mm', {}, 'voxelsAdded', {}, 'mask', {}, 'linearIndices', {});

    % Sort by absolute magnitude (preserving sign for naming)
    [~, order] = sort(abs(ring_mm));
    ring_mm = ring_mm(order);

    voxelSize = [ct.resolution.x ct.resolution.y ct.resolution.z];
    
    fprintf('--- Ring Generation Summary ---\n');
    fprintf('Reference VOI: %s (index %d, %d voxels)\n', voiName, ixRefVOI, numel(baseIndices));
    if keepInnerVolume
        fprintf('Mode: keepInnerVolume = true (negative margins return eroded volume)\n');
    else
        fprintf('Mode: keepInnerVolume = false (negative margins return ring shell)\n');
    end

    %% Generate rings
    for i = 1:length(ring_mm)
        offset_mm = ring_mm(i);
        
        if offset_mm == 0
            warning('matRad_VOICreateRings:ZeroMargin', ...
                'Ring margin of 0 mm specified. Skipping.');
            continue;
        end

        ringType = 'outer';
        if offset_mm < 0
            ringType = 'inner';
        end

        % === Expansion (outer ring) ===
        if offset_mm > 0
            offset = struct('x', offset_mm, 'y', offset_mm, 'z', offset_mm);
            outerMask = matRad_addMargin(voiMask, cst, ct.resolution, offset, true);
            
            if marginPTVRing_mm > 0
                inner = struct('x', marginPTVRing_mm, 'y', marginPTVRing_mm, 'z', marginPTVRing_mm);
                innerMask = matRad_addMargin(voiMask, cst, ct.resolution, inner, true);
                ringMask = outerMask & ~innerMask;
            else
                ringMask = outerMask & ~voiMask;
            end

        % === Contraction (inner ring) ===
        else
            % Use morphological erosion with a spherical structuring element
            % Radius in voxels for each dimension
            radiusVox = abs(offset_mm) ./ voxelSize;
            
            % Create anisotropic spherical structuring element
            [X, Y, Z] = ndgrid(-ceil(radiusVox(1)):ceil(radiusVox(1)), ...
                               -ceil(radiusVox(2)):ceil(radiusVox(2)), ...
                               -ceil(radiusVox(3)):ceil(radiusVox(3)));
            
            % Ellipsoid equation: (x/rx)^2 + (y/ry)^2 + (z/rz)^2 <= 1
            se = ((X./radiusVox(1)).^2 + (Y./radiusVox(2)).^2 + (Z./radiusVox(3)).^2) <= 1;
            
            % Erode the mask
            erodedMask = imerode(voiMask, se);
            
            % Choose output based on keepInnerVolume flag
            if keepInnerVolume
                % Keep only the eroded volume (intersect with original)
                ringMask = erodedMask & voiMask;
            else
                % Keep the ring shell (original minus eroded)
                ringMask = voiMask & ~erodedMask;
            end
            
            fprintf('  Erosion: radius = [%.2f %.2f %.2f] voxels\n', radiusVox);
        end

        ringIndices = find(ringMask);

        if isempty(ringIndices)
            warning('matRad_VOICreateRings:EmptyRing', ...
                'Ring %d (%s, %.1f mm) resulted in 0 voxels. Skipping.\n  Possible reasons: margin too large, VOI too small, or anisotropic voxels.', ...
                i, ringType, offset_mm);
            continue;
        end

        %% Update CST
        newRow = size(cst,1) + 1;
        ixAdded = [ixAdded; newRow]; %#ok<AGROW>
        
        % Naming convention
        if offset_mm < 0
            if keepInnerVolume
                ringName = sprintf('%s_Inner%imm', voiName, abs(round(offset_mm)));
            else
                ringName = sprintf('%s_negRing%imm', voiName, abs(round(offset_mm)));
            end
        else
            ringName = sprintf('%s_Ring%imm', voiName, abs(round(offset_mm)));
        end
        
        cst{newRow, 1} = newRow;
        cst{newRow, 2} = ringName;
        cst{newRow, 3} = 'TARGET';
        cst{newRow, 4} = {ringIndices};
        cst{newRow, 5} = cst{ixRefVOI, 5};
        cst{newRow, 5}.visibleColor = rand(1, 3);
        cst{newRow, 5}.Priority = newRow;

        %% Store metadata
        ringInfo(i).name = ringName;
        ringInfo(i).margin_mm = offset_mm;
        ringInfo(i).voxelsAdded = numel(ringIndices);
        ringInfo(i).mask = ringMask;
        ringInfo(i).linearIndices = ringIndices;

        %% Display info
        voxelOffset = round(abs(offset_mm) ./ voxelSize);
        voxelsDiag = round(norm(voxelOffset));
        fprintf('Ring %d (%s, %s): %.1f mm = [%d %d %d] voxels (~%d diagonally) → %d voxels added\n', ...
            i, ringName, ringType, offset_mm, ...
            voxelOffset(1), voxelOffset(2), voxelOffset(3), voxelsDiag, ...
            numel(ringIndices));
    end

    fprintf('--------------------------------\n');

    %% Visualization
    if visualize
        sliceIdx = round(ct.cubeDim(3)/2);
        figure;
        matRad_showSliceFast(ct, cst);
        title(sprintf('Rings (±) around %s on CT slice %d', voiName, sliceIdx), ...
            'Interpreter', 'none');
    end

    ixAdded = ixAdded';
end