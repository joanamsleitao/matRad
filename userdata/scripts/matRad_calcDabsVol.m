function dAbsVol = matRad_calcDabsVol(doseCube, cst, absVolCC, ct)
% matRad_calcDabsVol - Compute D(V_abs): dose to the hottest absolute volume
%
% Syntax:
%   dAbsVol = matRad_calcDabsVol(doseCube, cst, absVolCC, ct)
%
% Description:
%   For each VOI in cst, returns the minimum dose received by the hottest
%   'absVolCC' cc of tissue. Equivalent to D0.03cc, D0.1cc, etc.
%   Follows the same DVH interpolation logic as matRad_calcQI.
%
% Inputs:
%   doseCube  - 3D dose matrix [Gy], same grid as ct
%   cst       - matRad CST cell array
%   absVolCC  - absolute volume threshold [cc], e.g. 0.03
%   ct        - matRad CT struct (needs ct.resolution.x/y/z in mm)
%
% Outputs:
%   dAbsVol   - struct array (one entry per VOI) with fields:
%                 .name       - VOI name
%                 .D_0_03cc   - dose [Gy] to hottest absVolCC cc (field name
%                               is auto-generated from absVolCC value)
%                 .absVolCC   - the queried absolute volume [cc]
%                 .voxVolCC   - voxel volume [cc]
%
% Example:
%   d = matRad_calcDabsVol(doseCube, cst, 0.03, ct);
%   fprintf('Spinal cord D0.03cc = %.2f Gy\n', d(3).D_0_03cc);
%
% Reference entry:
% | - | `matRad_calcDabsVol` | Dose to hottest absolute volume (D0.03cc etc.) | `dAbsVol = matRad_calcDabsVol(doseCube, cst, absVolCC, ct)` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

%% Voxel volume in cc
res = ct.resolution;
voxVolMM3 = res.x * res.y * res.z;   % mm^3
voxVolCC  = voxVolMM3 / 1000;        % 1 cc = 1000 mm^3

%% Build output field name from absVolCC, e.g. 0.03 -> 'D_0_03cc'
fieldLabel = ['D_' regexprep(sprintf('%.4g', absVolCC), '[\.\-]', '_') 'cc'];

%% Compute per VOI
dAbsVol = struct();

for iVoi = 1:size(cst, 1)
    indices    = cst{iVoi, 4}{1};
    doseInVoi  = sort(doseCube(indices), 'descend');   % sorted high -> low
    nVox       = numel(doseInVoi);

    dAbsVol(iVoi).name      = cst{iVoi, 2};
    dAbsVol(iVoi).absVolCC  = absVolCC;
    dAbsVol(iVoi).voxVolCC  = voxVolCC;

    if isempty(doseInVoi)
        dAbsVol(iVoi).(fieldLabel) = NaN;
        continue;
    end

    % Number of voxels that cover absVolCC
    % Use fractional interpolation (same spirit as matRad_calcQI DX)
    nVoxTarget = absVolCC / voxVolCC;   % fractional number of voxels

    if nVoxTarget >= nVox
        % Queried volume larger than the whole VOI -> return min dose
        dAbsVol(iVoi).(fieldLabel) = doseInVoi(end);
    else
        % Interpolate: fractional index into the descending-sorted dose vector
        % nVoxTarget = 1 means the single hottest voxel
        fracIdx = max(nVoxTarget, 1);   % at least 1
        idxLow  = floor(fracIdx);
        idxHigh = ceil(fracIdx);
        w       = fracIdx - idxLow;     % interpolation weight

        if idxLow == idxHigh
            dAbsVol(iVoi).(fieldLabel) = doseInVoi(idxLow);
        else
            dAbsVol(iVoi).(fieldLabel) = (1 - w) * doseInVoi(idxLow) + w * doseInVoi(idxHigh);
        end
    end
end

end