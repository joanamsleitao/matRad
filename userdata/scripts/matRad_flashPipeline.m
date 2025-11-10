function [doseCubeMod, maskStruct, cstOut] = matRad_flashPipeline( ...
    cst, doseCube, DMF, voiSelection, doseThreshold, outputTxtFile, ...
    includeHealthyTissue, returnMasks, applyMode)
% matRad_flashPipeline - Apply FLASH Dose Modifying Factor (DMF)
%                             to dose voxels above a dose threshold.
%
% DESCRIPTION:
%   This function implements a complete FLASH dose-modification pipeline.
%   It applies a Dose Modifying Factor (DMF) to specific regions in the dose
%   cube (either OARs, healthy tissue, or both) for voxels receiving a dose
%   above a given threshold.
%
%   It optionally generates new CST entries for healthy tissue regions and
%   can return or save binary masks indicating where FLASH effects were applied.
%
%   Three operational modes are supported:
%
%       'OAR'      – apply DMF only to selected VOIs (typically OARs)
%       'Healthy'  – apply DMF to all non-target healthy tissue voxels above threshold
%       'Combined' – apply DMF to both OARs and healthy tissue voxels
%
% SYNTAX:
%   [doseCubeMod, maskStruct, cstOut] = matRad_flashPipeline( ...
%       cst, doseCube, DMF, voiSelection, doseThreshold)
%
%   [doseCubeMod, maskStruct, cstOut] = matRad_flashPipeline( ...
%       cst, doseCube, DMF, voiSelection, doseThreshold, outputTxtFile, ...
%       includeHealthyTissue, returnMasks, applyMode)
%
% INPUTS:
%   cst                - matRad structure
%   doseCube           - 3D dose matrix
%   DMF                - scalar dose modifying factor (e.g. 0.85)
%   voiSelection       - cell array of VOI names to apply DMF (for 'OAR' mode)
%   doseThreshold      - dose threshold (Gy) for FLASH activation
%   outputTxtFile      - optional text file to log results
%   includeHealthyTissue - logical; if true, add HealthyTissue VOIs to CST
%   returnMasks        - logical; if true, return masks only (no dose modification)
%   applyMode          - string, one of:
%                        'OAR' | 'Healthy' | 'Combined' (default = 'OAR')
%
% OUTPUTS:
%   doseCubeMod - modified dose cube (if returnMasks = false)
%   maskStruct  - struct with logical masks used for modification:
%                   .doseAboveThr   – OARs above threshold
%                   .healthyMask    – all healthy voxels (non-targets)
%                   .healthyAboveThr – healthy voxels above threshold
%   cstOut      - updated CST (with optional new healthy tissue VOIs)
%
% -------------------------------------------------------------------------
% EXAMPLES:
%
% 1) Standard OAR-only FLASH:
%       doseOAR = matRad_flashPipeline(cst, doseCube, 0.85, ...
%                 {'Heart','L Lung'}, 10);
%
% 2) Healthy tissue FLASH:
%       [doseHealthy, masks, cstNew] = matRad_flashPipeline( ...
%           cst, doseCube, 0.85, {'Heart'}, 10, 'flash_healthy.txt', ...
%           true, false, 'Healthy');
%
% 3) Combined OAR + healthy tissue FLASH:
%       [doseCombined, masks, cstNew] = matRad_flashPipeline( ...
%           cst, doseCube, 0.85, {'Heart','L Lung'}, 10, ...
%           'flash_combined.txt', true, false, 'Combined');
%
% 4) Masks-only mode (no dose modification):
%       [~, masks] = matRad_flashPipeline(cst, doseCube, 0.85, ...
%           {'L Lung'}, 10, [], true, true, 'Combined');
%       imshow3D(masks.healthyAboveThr);
%
% -------------------------------------------------------------------------
% AUTHORSHIP:
%   Joana Leitão + GPT-5 (2025)
% -------------------------------------------------------------------------

if nargin < 9, applyMode = 'OAR'; end
if nargin < 8, returnMasks = false; end
if nargin < 7, includeHealthyTissue = false; end
if nargin < 6, outputTxtFile = []; end

applyMode = lower(applyMode);

% Step 0: Optionally identify healthy tissue regions
cstOut = cst;
healthyMask = [];
healthyAboveThrMask = [];

if includeHealthyTissue
    [cstOut, healthyMask, healthyAboveThrMask] = ...
        matRad_VOIIrradiatedHealthyTissue(cst, doseCube, doseThreshold, false);
end

% Step 1: Identify OAR voxels above threshold
doseAboveThrMask = matRad_VOIDoseThrMask(cstOut, doseCube, voiSelection, doseThreshold, true);

% Store masks
maskStruct = struct( ...
    'doseAboveThr', doseAboveThrMask, ...
    'healthyMask', healthyMask, ...
    'healthyAboveThr', healthyAboveThrMask ...
);

% Step 2: Combine masks based on mode
switch applyMode
    case 'oar'
        finalMask = doseAboveThrMask;
        targetName = 'Selected OARs';

    case 'healthy'
        if isempty(healthyAboveThrMask)
            warning('Healthy tissue masks not available — includeHealthyTissue must be true.');
            finalMask = false(size(doseCube));
        else
            finalMask = healthyAboveThrMask;
        end
        targetName = 'Healthy tissue voxels above threshold';

    case 'combined'
        finalMask = doseAboveThrMask | healthyAboveThrMask;
        targetName = 'OARs + Healthy tissue voxels above threshold';

    otherwise
        error('Invalid applyMode. Choose "OAR", "Healthy", or "Combined".');
end

% Step 3: Either apply DMF or just return masks
if returnMasks
    doseCubeMod = [];
    fprintf('Returning FLASH masks only (dose not modified).\n');
else
    fprintf('--- Applying FLASH DMF (Mode: %s) ---\n', upper(applyMode));
    doseCubeMod = doseCube;
    doseCubeMod(finalMask) = doseCube(finalMask) .* DMF;
    fprintf('  DMF %.3f applied to %d voxels (%s)\n', DMF, nnz(finalMask), targetName);

    if ~isempty(outputTxtFile)
        fid = fopen(outputTxtFile, 'a');
        fprintf(fid, 'Mode: %s | DMF: %.3f | Threshold: %.1f Gy | Voxels modified: %d\n', ...
            upper(applyMode), DMF, doseThreshold, nnz(finalMask));
        fclose(fid);
    end
    fprintf('--- Done ---\n');
end
end