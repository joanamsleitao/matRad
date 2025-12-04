function doseCubeMod = matRad_flashApplyDMF(doseCube, flashMask, DMF)
% matRad_flashApplyDMF - Apply FLASH DMF to a precomputed voxel mask
%
% Syntax:
%   doseCubeMod = matRad_flashApplyDMF(doseCube, flashMask)
%   doseCubeMod = matRad_flashApplyDMF(doseCube, flashMask, DMF)
%
% Inputs:
%   doseCube  - 3D dose matrix
%   flashMask - logical mask of voxels to modify
%   DMF       - scalar (optional, default = 0.75)
%
% Output:
%   doseCubeMod - modified doseCube
%
% Notes:
%   - No printing, no CST, no VOI selection required.
%   - All operations are element-wise.
%
% Author: Joana Leitão + GPT-5, 2025
% -------------------------------------------------------------------------

if nargin < 3 || isempty(DMF)
    DMF = 0.75;
end

% Copy original doseCube
doseCubeMod = doseCube;

% Apply DMF only to voxels in the mask
doseCubeMod(flashMask) = doseCubeMod(flashMask) * DMF;

end