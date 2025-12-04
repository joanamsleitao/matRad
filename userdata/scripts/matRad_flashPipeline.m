function [doseCubeModified, cstModified, flashMask, logFileName, ...
    hFigSlicesCenter, hFigSlicesMaxDiff, hFigDVH] = ...
    matRad_flashPipeline(ct, cst, doseCube, doseThreshold, DMF, voiSelection, includeHealthyTissues)
% MATRAD_FLASHPIPELINE - Full FLASH dose modification and visualization pipeline
%
% INPUTS:
%   cst                  - matRad CST cell array
%   doseCube             - 3D dose cube [Gy]
%   doseThreshold        - dose threshold for FLASH modification [Gy]
%   DMF                  - dose modifying factor
%   voiSelection         - cell array of VOI names or indices to include
%   includeHealthyTissues- boolean, include non-target tissues (default: false)
%
% OUTPUTS:
%   doseCubeModified     - modified dose cube
%   cstModified          - modified CST
%   flashMask            - logical mask of modified voxels
%   logFileName          - name of log output (optional)
%   hFigSlicesCenter     - figure handle for axial center slice comparison
%   hFigSlicesMaxDiff    - figure handle for axial slice max difference
%   hFigDVH              - figure handle for DVH comparison

%% Defaults
if ~exist('includeHealthyTissues','var'), includeHealthyTissues = false; end
if ~exist('voiSelection','var'), voiSelection = []; end

%% 1) Identify FLASH voxels
[flashMask, flashOARmask, cstExtraLines] = ...
    matRad_flashVoxels(cst, doseCube, doseThreshold, voiSelection, includeHealthyTissues);

% Update CST
cstModified = [cst; cstExtraLines];

%% 2) Apply DMF to FLASH voxels
doseCubeModified = matRad_flashApplyDMF(doseCube, flashMask, DMF);

%% 3) Log
logFileName = matRad_flashLog(cstModified, DMF, doseThreshold, flashMask);

%% 4) Slice & DVH visualization
zoom = 0.5;

[hFigSlicesCenter, hFigSlicesMaxDiff, hFigDVH] = ...
    matRad_compareTwoDoses(doseCube, doseCubeModified, ct, cstModified, zoom);

%% Done
fprintf('FLASH pipeline complete.\nModified voxels: %d\n', nnz(flashMask));

end