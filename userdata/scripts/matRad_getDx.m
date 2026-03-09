function dGy = matRad_getDx(cst, doseCube, ixVoi, x)
% matRad_getDx - Get Dx (Gy) for one VOI (one CST row / index)
%
% Syntax:
%   dGy = matRad_getDx(cst, doseCube, ixVoi, x)
%
% Description:
%   Returns Dx in Gy for a specific VOI, where Dx is the dose received by
%   x% of the VOI volume (near-maximum for small x, near-minimum for large x).
%
%   This mirrors the Dx definition used inside matRad_calcQI:
%       DX(x) = matRad_interp1(linspace(0,1,N), sort(doseInVoi), (100-x)/100)
%
% Inputs:
%   cst      - matRad CST cell array
%   doseCube - 3D dose matrix (Gy)
%   ixVoi    - scalar index into CST rows (the "specific cst line")
%   x        - scalar or vector of percentages in (0..100)
%              Example: x = 2 returns D2; x = [2 95 98] returns D2/D95/D98
%
% Outputs:
%   dGy - Dx value(s) in Gy, same size as x. Returns NaN(s) if VOI is empty.
%
% Reference entry:
% | `matRad_getDx` | `matRad_getDx` | Get Dx for one VOI (CST row) | `d = matRad_getDx(cst,dose,ix,[2 50 95])` | 🟢 |
%
% -------------------------------------------------------------------------
% Author: Joana Leitão
% -------------------------------------------------------------------------

% Checks
if nargin < 4
    error('matRad_getDx requires inputs: cst, doseCube, ixVoi, x.');
end
if ~isscalar(ixVoi) || ~isfinite(ixVoi) || ixVoi < 1 || ixVoi > size(cst,1)
    error('ixVoi must be a valid scalar CST row index (1..%d).', size(cst,1));
end
if ~isnumeric(x) || isempty(x) || any(~isfinite(x(:)))
    error('x must be numeric and finite.');
end
if any(x(:) <= 0) || any(x(:) >= 100)
    error('x must be strictly between 0 and 100 (e.g., 2, 95, 98).');
end

% VOI indices
if ~iscell(cst) || size(cst,2) < 4
    error('cst must be a CST cell array with at least 4 columns.');
end
idxCell = cst{ixVoi,4};
if isempty(idxCell) || ~iscell(idxCell) || isempty(idxCell{1})
    dGy = NaN(size(x));
    return;
end
indices = idxCell{1};
if isempty(indices)
    dGy = NaN(size(x));
    return;
end

% Dose samples
doseInVoi = sort(doseCube(indices));
N = numel(doseInVoi);
if N == 0
    dGy = NaN(size(x));
    return;
end

% Dx as used in matRad_calcQI
q = (100 - x) .* 0.01;                 % query positions in [0..1]
q = max(min(q, 1), 0);                 % clamp for safety (even though x in (0,100))
dGy = matRad_interp1(linspace(0,1,N), doseInVoi, q);

% Preserve shape of x
dGy = reshape(dGy, size(x));

end