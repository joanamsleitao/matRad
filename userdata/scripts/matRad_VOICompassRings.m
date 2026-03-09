function [cst, ringInfo, ixAdded] = matRad_VOICompassRings(ct, cst, ring_mm, ixRefVOI, compassDir, marginInner_mm, sectorWidth_deg, visualize)
% matRad_VOICompassRings - Create compass-sector VOI rings (N, NE, E, SE, S, SW, W, NW)
%
% Syntax:
%   [cst, ringInfo, ixAdded] = matRad_VOICompassRings(ct, cst, ring_mm, ixRefVOI, compassDir)
%   [cst, ringInfo, ixAdded] = matRad_VOICompassRings(ct, cst, ring_mm, ixRefVOI, compassDir, marginInner_mm)
%   [cst, ringInfo, ixAdded] = matRad_VOICompassRings(ct, cst, ring_mm, ixRefVOI, compassDir, marginInner_mm, sectorWidth_deg)
%   [cst, ringInfo, ixAdded] = matRad_VOICompassRings(ct, cst, ring_mm, ixRefVOI, compassDir, marginInner_mm, sectorWidth_deg, visualize)
%
% Description:
%   Creates VOIs that are *angular sectors* of isotropic rings around a
%   reference VOI, defined by a compass direction:
%
%       N, NE, E, SE, S, SW, W, NW
%
%   or long forms like "north", "southwest", etc.
%
%   The construction is:
%     1) Build an isotropic ring between marginInner_mm and ring_mm (mm)
%        using matRad_addMargin (outer - inner).
%     2) Compute the vector from the VOI center to each voxel (in mm).
%     3) Keep only voxels whose direction falls within a sector of width
%        sectorWidth_deg around the chosen compass direction.
%
%   For example, "SW" with sectorWidth_deg = 45 means angles in
%   [202.5°, 247.5°] around the PTV, and the outermost point is at 225°
%   (45° between south and west), as you described.
%
% Inputs:
%   ct              - matRad CT struct
%   cst             - matRad CST cell array
%   ring_mm         - Ring outer margin(s) [mm], positive values
%                     (each entry defines one isotropic ring shell)
%   ixRefVOI        - Reference VOI index (integer). If empty, first 'PTV'
%                     VOI (cst(:,3) == 'PTV') is used.
%   compassDir      - Compass direction (char/string), case-insensitive:
%                        'N','S','E','W','NE','NW','SE','SW'
%                        or 'north','southwest', etc.
%   marginInner_mm  - (optional) inner margin [mm] from VOI (default 0).
%                     The ring covers distances (marginInner_mm, ring_mm].
%   sectorWidth_deg - (optional) full angular width of sector [deg],
%                     default 45.0 (±22.5° around compassDir).
%   visualize       - (optional) logical flag for visualization on mid slice
%
% Outputs:
%   cst      - Updated CST with new compass-sector VOIs appended
%   ringInfo - Struct array with metadata per ring:
%                .name
%                .margin_mm
%                .compassDir
%                .sectorWidth_deg
%                .voxelsAdded
%                .mask
%                .linearIndices
%   ixAdded  - Row indices of the added VOIs in CST (row vector)
%
% Notes:
%   - Only positive ring_mm are supported here (outer rings).
%   - This function is angular / radial. For one-sided slabs (pure “east”
%     without radial constraint) use matRad_VOIDirRings instead.
%
% Requires:
%   matRad_addMargin.m
%
% See also:
%   matRad_VOICreateRings, matRad_addMargin
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% Reference list entry:
% | `matRad_VOICreateCompass` | `matRad_VOICompassRings` | Create compass-sector rings around a VOI (N, NE, E, SE, S, SW, W, NW) | `[cst, ringInfo, ixAdded] = matRad_VOICompassRings(ct, cst, ring_mm, ixRefVOI, compassDir, marginInner_mm, sectorWidth_deg, visualize)` | 🟡 |
% -------------------------------------------------------------------------

%% --- Input handling -----------------------------------------------------
if nargin < 4 || isempty(ixRefVOI)
    ixRefVOI = find(strcmpi(cst(:,3), 'PTV'), 1);
    if isempty(ixRefVOI)
        error('matRad_VOICompassRings:NoPTV', ...
            'No PTV VOI found as default. Please specify ixRefVOI.');
    end
end

if nargin < 5 || isempty(compassDir)
    error('matRad_VOICompassRings:NoDirection', ...
        'compassDir must be specified (e.g. ''N'',''SW'',''southwest'').');
end

if nargin < 6 || isempty(marginInner_mm)
    marginInner_mm = 0;
end
if marginInner_mm < 0
    error('matRad_VOICompassRings:NegativeInnerMargin', ...
        'marginInner_mm must be >= 0.');
end

if nargin < 7 || isempty(sectorWidth_deg)
    sectorWidth_deg = 45.0;
end
if sectorWidth_deg <= 0 || sectorWidth_deg > 180
    error('matRad_VOICompassRings:BadSectorWidth', ...
        'sectorWidth_deg must be in (0, 180].');
end

if nargin < 8 || isempty(visualize)
    visualize = false;
end

ring_mm = ring_mm(:)'; % row vector
if any(ring_mm <= 0)
    error('matRad_VOICompassRings:NonPositiveRings', ...
        'All ring_mm values must be > 0.');
end

% Sort rings by increasing radius
[~, order] = sort(ring_mm);
ring_mm = ring_mm(order);

if marginInner_mm >= min(ring_mm)
    warning('matRad_VOICompassRings:LargeInnerMargin', ...
        'Inner margin (%.1f mm) >= smallest ring (%.1f mm). Check configuration.', ...
        marginInner_mm, min(ring_mm));
end

%% --- Base VOI mask ------------------------------------------------------
baseIndices = cst{ixRefVOI,4}{1};
voiName     = cst{ixRefVOI,2};

voiMask = false(ct.cubeDim);
voiMask(baseIndices) = true;

sz = ct.cubeDim;

%% --- VOI center-of-mass in voxel space ---------------------------------
% (Use voxel indices; we convert to mm later with resolution)
[rowIdx, colIdx, ~] = ind2sub(sz, baseIndices);
comRow = mean(rowIdx);
comCol = mean(colIdx);

% Precompute X/Y in mm, relative to VOI COM (ignoring z for angle)
[YY, XX, ~] = ndgrid(1:sz(1), 1:sz(2), 1:sz(3));
xRel_mm = (XX - comCol) * ct.resolution.x;  % columns -> x
yRel_mm = (YY - comRow) * ct.resolution.y;  % rows    -> y

% Radial distance (mm) from VOI COM (used only for direction; ring itself
% is controlled by matRad_addMargin)
r_mm = sqrt(xRel_mm.^2 + yRel_mm.^2);

%% --- Direction unit vector and cosine threshold -------------------------
[dirUnit, dirLabel] = local_parseCompassDir(compassDir);
halfAngleRad  = (sectorWidth_deg / 2) * pi/180;
cosThreshold  = cos(halfAngleRad);

fprintf('--- Compass Ring Generation (%s, %g deg sector) ---\n', dirLabel, sectorWidth_deg);

ringInfo = struct('name', {}, 'margin_mm', {}, 'compassDir', {}, ...
                  'sectorWidth_deg', {}, 'voxelsAdded', {}, ...
                  'mask', {}, 'linearIndices', {});
ixAdded = [];

%% --- Loop over ring radii ----------------------------------------------
for i = 1:numel(ring_mm)
    outer_mm = ring_mm(i);
    inner_mm = min(marginInner_mm, outer_mm - eps);

    % --- Isotropic outer and inner masks using matRad_addMargin ----------
    offsetOuter = struct('x', outer_mm, 'y', outer_mm, 'z', outer_mm);
    outerMask = matRad_addMargin(voiMask, cst, ct.resolution, offsetOuter, true);

    if inner_mm > 0
        offsetInner = struct('x', inner_mm, 'y', inner_mm, 'z', inner_mm);
        innerMask = matRad_addMargin(voiMask, cst, ct.resolution, offsetInner, true);
        ringIsoMask = outerMask & ~innerMask;
    else
        ringIsoMask = outerMask & ~voiMask;
    end

    % --- Directional sector selection ------------------------------------
    % Vector from COM to voxel: r = [xRel_mm, yRel_mm]
    % We keep voxels where:
    %   - dot(r, dirUnit) > 0 (in front of direction)
    %   - angle between r and dirUnit <= sectorWidth_deg/2
    %
    % cos(theta) = dot(r,dirUnit) / |r|
    dotProd = xRel_mm*dirUnit(1) + yRel_mm*dirUnit(2);

    valid = (r_mm > 0);                % avoid division by zero at COM
    cosTheta = zeros(sz, 'like', xRel_mm);
    cosTheta(valid) = dotProd(valid) ./ r_mm(valid);

    dirMask = (dotProd > 0) & (cosTheta >= cosThreshold);

    % Final ring mask: isotropic ring + directional constraint
    ringMask = ringIsoMask & dirMask;
    ringIndices = find(ringMask);

    % --- Update CST ------------------------------------------------------
    newRow = size(cst,1) + 1;
    ixAdded = [ixAdded; newRow]; %#ok<AGROW>

    ringName = sprintf('%s_%sRing%imm_%gdeg', ...
                       voiName, dirLabel, round(outer_mm), sectorWidth_deg);

    cst{newRow,1} = newRow;
    cst{newRow,2} = ringName;
    cst{newRow,3} = 'TARGET';
    cst{newRow,4} = {ringIndices};
    cst{newRow,5} = cst{ixRefVOI,5};
    cst{newRow,5}.visibleColor = rand(1,3);
    cst{newRow,5}.Priority     = newRow;

    % --- Metadata --------------------------------------------------------
    ringInfo(i).name           = ringName;
    ringInfo(i).margin_mm      = outer_mm;
    ringInfo(i).compassDir     = dirLabel;
    ringInfo(i).sectorWidth_deg = sectorWidth_deg;
    ringInfo(i).voxelsAdded    = numel(ringIndices);
    ringInfo(i).mask           = ringMask;
    ringInfo(i).linearIndices  = ringIndices;

    fprintf('Ring %d (%s): outer=%.1f mm, inner=%.1f mm, voxels=%d\n', ...
        i, ringName, outer_mm, inner_mm, numel(ringIndices));
end

fprintf('----------------------------------------------\n');

%% --- Visualization ------------------------------------------------------
if visualize
    sliceIdx = round(sz(3)/2);
    figure; matRad_showSliceFast(ct, cst, [], sliceIdx);
    title(sprintf('Compass rings (%s, %g°) around %s on CT slice %d', ...
        dirLabel, sectorWidth_deg, voiName, sliceIdx));
end

ixAdded = ixAdded';

end % main function matRad_VOICompassRings


% -------------------------------------------------------------------------
% Local helper: parse compass direction into 2D unit vector
% -------------------------------------------------------------------------
function [v, label] = local_parseCompassDir(compassDir)

d = lower(strtrim(char(compassDir)));

switch d
    case {'n','north'}
        v = [0, -1]; label = 'N';
    case {'s','south'}
        v = [0,  1]; label = 'S';
    case {'e','east'}
        v = [ 1, 0]; label = 'E';
    case {'w','west'}
        v = [-1, 0]; label = 'W';

    case {'ne','northeast','north-east'}
        v = [ 1, -1]; label = 'NE';
    case {'nw','northwest','north-west'}
        v = [-1, -1]; label = 'NW';
    case {'se','southeast','south-east'}
        v = [ 1, 1];  label = 'SE';
    case {'sw','southwest','south-west'}
        v = [-1, 1];  label = 'SW';

    otherwise
        error('local_parseCompassDir:UnknownDirection', ...
            'Unknown compass direction "%s". Use N, NE, E, SE, S, SW, W, NW.', d);
end

% Normalize to unit length
v = v ./ norm(v);

end