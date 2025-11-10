function relevantSlices = matRad_getSlices(cst, ct, doseCube, doseLim, margin)
% matRad_getRelevantSlices - Identify slices with relevant dose around isocenter
%
% Syntax:
%   relevantSlices = matRad_getRelevantSlices(cst, ct, doseCube)
%   relevantSlices = matRad_getRelevantSlices(cst, ct, doseCube, margin)
%
% Inputs:
%   cst       - Constraint structure table (for iso center)
%   ct        - CT structure (for coordinate conversion)
%   doseCube  - 3D dose matrix
%   margin    - (optional) slices to extend beyond nonzero dose [default: 10]
%   minDose   - minDose threshold
%
% Outputs:
%   relevantSlices - vector of slice indices containing dose around iso center
%

if nargin < 4
    doseLim = 0;
end

if numel(doseLim) > 1
    minDose = doseLim(1);
    maxDose = doseLim(2);
else
    minDose = doseLim;
    maxDose = [];
end

if nargin < 5
    margin = 0;
end

nSlices = size(doseCube,3);

% Central slice (isocenter)
isoCube = matRad_world2cubeIndex(matRad_getIsoCenter(cst, ct, 0), ct);
centralSlice = isoCube(3);

% Find slices that contain dose above refDose
doseMask = squeeze(any(any(doseCube > minDose, 1), 2));  % 1 x nSlices logical

if ~isempty(maxDose)
    doseMaskMax = squeeze(any(any(doseCube < maxDose, 1), 2));  % 1 x nSlices logical
    mask = doseMaskMax .* doseMask;
end

firstSlice = find(doseMask,1,'first');
lastSlice  = find(doseMask,1,'last');

if isempty(firstSlice)  % No dose anywhere
    relevantSlices = centralSlice;
else
    lowerSlice = max(firstSlice - margin, 1);
    upperSlice = min(lastSlice + margin, nSlices);
    relevantSlices = lowerSlice:upperSlice;
end

end
