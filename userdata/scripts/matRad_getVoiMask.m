function mask = matRad_getVoiMask(ct, cst, voiName, slice)
% MATRAD_GETVOIMASK - Returns a binary mask for a VOI
%
%   mask = matRad_getVoiMask(ct, cst, voiName)
%   mask = matRad_getVoiMask(ct, cst, voiName, ctIndex)
%   mask = matRad_getVoiMask(ct, cst, voiName, ctIndex, slice)
%
% Inputs:
%   ct         - matRad CT struct
%   cst        - matRad cst cell array
%   voiName    - string or char, name of the structure to extract
%   ctIndex    - optional, index of CT cube (default = 1)
%   slice      - optional, if given, returns mask only for this axial slice
%
% Output:
%   mask       - 3D (or 2D if slice provided) logical mask

if nargin < 4 || isempty(slice)
    slice = matRad_world2cubeIndex(matRad_getIsoCenter(cst,ct,0),ct);
    slice = slice(3);
end

ctIndex = ct.numOfCtScen;

% find the structure index
ixVoi = find(strcmpi(voiName, {cst{:,1}}), 1);
if isempty(ixVoi)
    error('VOI "%s" not found in cst.', voiName);
end

% full 3D mask
mask = false(ct.cubeDim);
mask(cst{ixVoi,4}{ctIndex}) = true;

% optionally, return a single slice
if nargin >= 5 && ~isempty(slice)
    mask = squeeze(mask(:,:,slice));  % assuming axial
end
end
