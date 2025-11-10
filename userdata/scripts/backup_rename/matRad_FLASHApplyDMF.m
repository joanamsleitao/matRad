function doseCubeMod = matRad_FLASHApplyDMF(cst, doseCube, DMF, voiSelection, doseAboveThrMask, outputTxtFile)
% matRad_applyDoseModifyingFactor - Apply FLASH DMF to voxels above dose threshold
%
% Syntax:
%   doseCubeMod = matRad_applyDoseModifyingFactor(cst, doseCube, DMF, voiSelection, doseAboveThrMask)
%   doseCubeMod = matRad_applyDoseModifyingFactor(..., outputTxtFile)
%
% Inputs:
%   cst               - CST structure
%   doseCube          - 3D dose matrix
%   DMF               - scalar or struct with per-VOI DMF
%   voiSelection      - VOI names to apply DMF to
%   doseAboveThrMask  - logical mask of voxels where dose > threshold
%   outputTxtFile     - optional path to write summary report
%
% Output:
%   doseCubeMod       - modified doseCube
%
% Notes:
%   - If doseAboveThrMask is empty, DMF applies to all VOI voxels.
%   - If DMF is struct, field names must match VOI names.
% -------------------------------------------------------------------------

doseCubeMod = doseCube;

if nargin < 6, outputTxtFile = []; end
if nargin < 5 || isempty(doseAboveThrMask)
    doseAboveThrMask = true(size(doseCube)); % apply everywhere
end

if nargin < 4 || isempty(voiSelection)
    voiSelection = cst(~contains(lower(cst(:,2)),'ptv'),2);
end

if ~isempty(outputTxtFile)
    fid = fopen(outputTxtFile,'w');
    fprintf(fid, 'VOI_Name\tDMF\tVoxels_Modified\n');
else
    fid = [];
end

fprintf('--- Applying FLASH DMF (Threshold-aware) ---\n');

for i = 1:size(cst,1)
    voiName = cst{i,2};
    if ~ismember(voiName, voiSelection)
        continue;
    end

    indices = cst{i,4}{1};

    % Limit to dose-above-threshold voxels
    validIdx = indices(doseAboveThrMask(indices));

    if isempty(validIdx)
        fprintf('  %-20s -> no voxels above threshold, skipped.\n', voiName);
        continue;
    end

    % Determine DMF
    if isstruct(DMF)
        if isfield(DMF, voiName)
            dmfVal = DMF.(voiName);
        else
            warning('No DMF defined for %s. Skipping.', voiName);
            continue;
        end
    else
        dmfVal = DMF;
    end

    doseCubeMod(validIdx) = doseCubeMod(validIdx) * dmfVal;

    fprintf('  %-20s -> DMF %.3f applied to %d voxels\n', voiName, dmfVal, numel(validIdx));

    if ~isempty(fid)
        fprintf(fid, '%s\t%.3f\t%d\n', voiName, dmfVal, numel(validIdx));
    end
end

if ~isempty(fid)
    fclose(fid);
    fprintf('Summary written to %s\n', outputTxtFile);
end

fprintf('--- Done ---\n');
end
