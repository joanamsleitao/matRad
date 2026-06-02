function kMax = matRad_flashSpotBudget(param)
% matRad_flashSpotBudget - Compute maximum number of spots allowed under FLASH constraint
%
% Syntax:
%   kMax = matRad_flashSpotBudget(Dtarget, DRthr, tSpot)
%   kMax = matRad_flashSpotBudget(6, 40, 0.003)
%
% Description:
%   Given a fixed total dose target, a FLASH dose-rate threshold, and a
%   fixed per-spot delivery time, computes the maximum number of spots
%   that can be delivered while keeping the average dose rate above DRthr.
%
%   The constraint is derived from:
%       D_avg_rate = Dtarget / (kMax * tSpot) >= DRthr
%
%   Rearranged:
%       kMax = floor( Dtarget / (DRthr * tSpot) )
%
%   Example:
%       Dtarget = 6 Gy, DRthr = 40 Gy/s, tSpot = 3 ms
%       kMax = floor(6 / (40 * 0.003)) = floor(50) = 50
%
% Inputs:
%   Dtarget  - [Gy]   Total dose to be delivered to the aimed region
%   DRthr    - [Gy/s] Minimum average dose rate for FLASH eligibility
%   tSpot    - [s]    Fixed delivery time per spot
%
% Outputs:
%   kMax     - Maximum number of spots allowed (positive integer)
%
% Notes:
%   - This is a hard upper bound. Using more than kMax spots will drop
%     the average dose rate below DRthr for a voxel receiving Dtarget.
%   - This function does not account for spatial dose heterogeneity.
%     It is intended as a fast machine-level screening tool (Stage 1,
%     Level 1), not a per-voxel guarantee.
%   - If kMax = 0, the FLASH constraint cannot be met with the given
%     parameters and a warning is issued.
%
% Reference entry:
%   | matRad_flashSpotBudget | matRad_flashSpotBudget | Compute max spot budget k_max from FLASH delivery constraint | kMax = matRad_flashSpotBudget(Dtarget, DRthr, tSpot) | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

Dtarget = param.Dtarget; 
DRthr = param.DRthr;
tSpot= param.tSpot;

% --- Input validation ---
validateattributes(Dtarget, {'numeric'}, {'scalar','positive','finite'}, ...
    'matRad_flashSpotBudget', 'Dtarget');
validateattributes(DRthr,   {'numeric'}, {'scalar','positive','finite'}, ...
    'matRad_flashSpotBudget', 'DRthr');
validateattributes(tSpot,   {'numeric'}, {'scalar','positive','finite'}, ...
    'matRad_flashSpotBudget', 'tSpot');

% --- Compute budget ---
kMax = floor(Dtarget / (DRthr * tSpot));

% --- Guard: warn if constraint is unsatisfiable ---
if kMax < 1
    warning('matRad_flashSpotBudget:infeasible', ...
        ['FLASH constraint cannot be met: kMax = 0.\n' ...
         'Consider increasing Dtarget (%.1f Gy), decreasing DRthr (%.1f Gy/s), ' ...
         'or increasing tSpot (%.4f s).'], Dtarget, DRthr, tSpot);
    kMax = 0;
end

% --- Report ---
fprintf('[matRad_flashSpotBudget] Dtarget=%.1f Gy | DRthr=%.1f Gy/s | tSpot=%.1f ms --> kMax = %d spots\n', ...
    Dtarget, DRthr, tSpot*1e3, kMax);

end