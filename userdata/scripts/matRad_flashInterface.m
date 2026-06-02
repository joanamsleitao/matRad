function [cst, ixInterface, maskInterface] = matRad_flashInterface(ct, cst, ixTarget, ixOAR, dilate_mm)
% matRad_flashInterface - Define the FLASH aiming interface region (R_aim)
%                         as target voxels within a dilated margin of the OAR
%
% Syntax:
%   [cst, ixInterface, maskInterface] = matRad_flashInterface(ct, cst, ixTarget, ixOAR)
%   [cst, ixInterface, maskInterface] = matRad_flashInterface(ct, cst, ixTarget, ixOAR, dilate_mm)
%
% Description:
%   Defines R_aim = Target ∩ dilate(OAR, dilate_mm).
%   This is the "danger interface" — target voxels that are geometrically
%   close to the OAR and therefore the most clinically relevant region
%   for FLASH delivery (high dose, high dose rate, OAR sparing).
%
%   The dilation is performed in 3D using a spherical structuring element
%   of radius dilate_mm, applied to the binary OAR mask. The intersection
%   with the target mask gives R_aim.
%
%   The resulting region is appended to cst as a new VOI row named
%   'Interface', with its voxel indices stored in cst{end, 4}{1}.
%   ixInterface is the CST row index of this new entry (= original
%   size(cst,1) + 1).
%
%   If the resulting interface is empty, a warning is issued and the full
%   target is returned as fallback.
%
% Inputs:
%   ct         - matRad CT struct (used for voxel size and grid dimensions)
%   cst        - matRad CST cell array
%   ixTarget   - row index of the target VOI in cst (e.g. GTV or PTV)
%   ixOAR      - row index of the OAR VOI in cst (e.g. SpinalCord)
%   dilate_mm  - (optional) dilation radius in mm (default: 5)
%
% Outputs:
%   cst           - updated CST with new 'Interface' VOI appended as last row
%                   cst{ixInterface, 4}{1} contains the voxel linear indices
%   ixInterface   - CST row index of the new 'Interface' VOI
%                   (= original size(cst,1) + 1)
%   maskInterface - binary 3D mask of R_aim (same size as ct grid)
%
% Notes:
%   - Dilation uses imdilate (Image Processing Toolbox). If unavailable,
%     a fallback using bwdist is used instead.
%   - dilate_mm should reflect the clinical margin of concern (e.g. 3–7 mm
%     depending on anatomy and planning margins).
%   - cst{ixInterface, 4}{1} is used directly in matRad_flashScreenEL to
%     count spot contributions to R_aim without computing a full dose cube.
%
% Reference entry:
%   | matRad_flashInterface | matRad_flashInterface | Define FLASH aiming interface region R_aim as Target ∩ dilate(OAR), append to CST | `[cst, ixInterface, maskInterface] = matRad_flashInterface(ct, cst, ixTarget, ixOAR, dilate_mm)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% --- Default dilation radius ---
if nargin < 5 || isempty(dilate_mm)
    dilate_mm = 5;
end

% --- Input validation ---
validateattributes(ixTarget,  {'numeric'}, {'scalar','integer','positive'}, ...
    'matRad_flashInterface', 'ixTarget');
validateattributes(ixOAR,     {'numeric'}, {'scalar','integer','positive'}, ...
    'matRad_flashInterface', 'ixOAR');
validateattributes(dilate_mm, {'numeric'}, {'scalar','positive','finite'}, ...
    'matRad_flashInterface', 'dilate_mm');

% --- Grid dimensions and voxel size ---
gridSize = ct.cubeDim;                          % [nX nY nZ]
voxSize  = ct.resolution;                       % struct with .x .y .z in mm

% --- Build binary masks from CST indices ---
maskTarget = false(gridSize);
maskOAR    = false(gridSize);

maskTarget(cst{ixTarget, 4}{1}) = true;
maskOAR(cst{ixOAR,    4}{1}) = true;

% --- Dilate OAR mask by dilate_mm ---
% Compute structuring element radius in voxels (anisotropic grid support)
rVox = [dilate_mm / voxSize.x, ...
        dilate_mm / voxSize.y, ...
        dilate_mm / voxSize.z];

if license('test','image_toolbox')
    % Preferred: imdilate with ellipsoidal SE
    [gx, gy, gz] = ndgrid(-ceil(rVox(1)):ceil(rVox(1)), ...
                           -ceil(rVox(2)):ceil(rVox(2)), ...
                           -ceil(rVox(3)):ceil(rVox(3)));
    SE = (gx/rVox(1)).^2 + (gy/rVox(2)).^2 + (gz/rVox(3)).^2 <= 1;
    maskOARdil = imdilate(maskOAR, SE);
else
    % Fallback: bwdist (distance transform, no toolbox needed)
    distFromOAR = bwdist(maskOAR);                    % voxel units
    % Convert threshold to voxels using mean voxel size
    meanVoxSize = mean([voxSize.x, voxSize.y, voxSize.z]);
    maskOARdil  = distFromOAR <= (dilate_mm / meanVoxSize);
end

% --- Intersect with target ---
maskInterface = maskTarget & maskOARdil;

% --- Guard: fallback to full target if interface is empty ---
if ~any(maskInterface(:))
    warning('matRad_flashInterface:emptyInterface', ...
        ['R_aim is empty with dilate_mm=%.1f mm.\n' ...
         'Falling back to full target mask.\n' ...
         'Consider increasing dilate_mm or checking VOI indices.'], dilate_mm);
    maskInterface = maskTarget;
end

% --- Extract linear indices ---
voxInterface = find(maskInterface);

% --- Append Interface VOI to CST ---
% New row index is one beyond the current last row
ixInterface = size(cst, 1) + 1;

% Replicate structure from target row as template, then overwrite key fields
cst(ixInterface, :)    = cst(ixTarget, :);
cst{ixInterface, 1}    = ixInterface - 1;   % VOI ID (0-based convention)
cst{ixInterface, 2}    = 'Interface';        % VOI name
cst{ixInterface, 3}    = 'OAR';             % type: treated as OAR (no objectives)
cst{ixInterface, 4}    = {voxInterface};     % voxel indices cell
cst{ixInterface, 5}    = struct('Priority', 1, 'Visible', 1, 'visibleColor', [1 0.5 0]);
if size(cst, 2) >= 6
    cst{ixInterface, 6} = {};               % no dose objectives
end

% --- Report ---
nVox       = numel(voxInterface);
nVoxTarget = sum(maskTarget(:));
fprintf(['[matRad_flashInterface] R_aim defined: %d voxels ' ...
         '(%.1f%% of target) | OAR dilated by %.1f mm | CST row: %d\n'], ...
    nVox, 100*nVox/nVoxTarget, dilate_mm, ixInterface);

end