function cb = matRad_doseMapBins(ax, dMin, dMax, nBinsTotal)
% matRad_setDoseCbarBins - Set colorbar ticks/labels for binned dose cmap with plateau >=21
%
% Syntax:
%   cb = matRad_setDoseCbarBins(gca, 0, dMax, 10)
%
% Description:
%   Matches the colorbar to a colormap that has:
%     - (nBinsTotal-1) bins spanning 0..21 Gy uniformly
%     - last bin for >=21 Gy (plateau)
%
% Inputs:
%   ax         - target axes handle (e.g., gca)
%   dMin       - caxis lower limit (recommend 0)
%   dMax       - caxis upper limit (typically max dose shown)
%   nBinsTotal - total bins incl plateau (2..10)
%
% Output:
%   cb - colorbar handle
%
% Reference entry:
% | `matRad_setDoseCbarBins` | `matRad_setDoseCbarBins` | Colorbar ticks/labels for binned dose cmap | `cb=matRad_setDoseCbarBins(gca,0,dMax,10)` | 🟢 |

if nargin < 4 || isempty(nBinsTotal), nBinsTotal = 10; end
nBinsTotal = max(2, min(10, round(nBinsTotal)));

thr = 21;

% Ensure axes is current target
axes(ax);

% Colorbar
cb = colorbar(ax);

% Determine how many color rows are below/above 21 (must match the cmap logic)
N = 256;
fracBelow = min(1, max(0, thr / dMax));
nBelow = max(1, round(fracBelow * N));
nAbove = N - nBelow;

% Colorbar value range is [dMin..dMax] (because you use caxis)
% The "below" region corresponds to [dMin..min(thr,dMax)] visually.
belowLo = dMin;
belowHi = min(thr, dMax);

% Dose edges for bins below 21
nBelowBins = nBinsTotal - 1;

if belowHi > belowLo
    edgesBelow = linspace(belowLo, belowHi, nBelowBins+1);  % dose edges
else
    edgesBelow = belowLo * ones(1, nBelowBins+1);
end

% Build tick positions at centers of each bin in *data units*
tickVals = zeros(1, nBinsTotal);
tickLabs = strings(1, nBinsTotal);

for k = 1:nBelowBins
    a = edgesBelow(k);
    b = edgesBelow(k+1);
    tickVals(k) = a;
    tickLabs(k) = {round(a, 1)};%sprintf('%.f', a);
end

% Plateau tick: place in the middle of the plateau region [thr..dMax]
if dMax > thr
    tickVals(end) = 0.5*(thr + dMax);
    tickLabs(end) = sprintf('≥%.0f', thr);
else
    % No plateau visible; still label top as 21 cap
    tickVals(end) = dMax;
    tickLabs(end) = sprintf('≥%.0f', thr);
end

cb.Ticks = tickVals;
cb.TickLabels = cellstr(tickLabs);

cb.Label.String = 'Dose (Gy)';
cb.TickDirection = 'out';

end