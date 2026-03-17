function [flashMask, flashOARmask, cstFLASH] = matRad_flashVoxels( ...
    cst, doseCube, doseThreshold, voiSelection, includeHealthy, ...
    minIslandVox3D, minAreaVox2D)
% matRad_flashVoxels - prepare voxel masks and CST entries for FLASH analysis
%
% Syntax:
%   [flashMask, flashOARmask, cstFLASH] = ...
%       matRad_flashVoxels(cst, doseCube, doseThreshold, voiSelection, includeHealthy)
%
% Description:
%   Builds above-threshold voxel masks for selected OAR VOIs (and optionally
%   healthy tissue), and returns CST entries describing those regions.
%
% Inputs:
%   cst            - matRad CST cell array (VOI table)
%   doseCube       - 3D matrix of dose (Gy)
%   doseThreshold  - scalar threshold in Gy (optional, default = 6)
%   voiSelection   - (optional) numeric vector of VOI indices to consider.
%                   If empty, all OARs are used.
%   includeHealthy - logical, whether to include healthy tissue above threshold (default = true)
%   minIslandVox3D - (optional) passed through for reporting/consistency
%   minAreaVox2D   - (optional) passed through for reporting/consistency
%
% Outputs:
%   flashMask    - logical mask of all voxels above threshold (OARs + healthy if includeHealthy)
%   flashOARmask - logical mask of OAR voxels above threshold (selected OARs only)
%   cstFLASH     - CST rows describing FLASH-affected VOIs:
%                 {OARsFLASH_row; (HealthyFLASH_row if includeHealthy)}
%
% Notes:
%   - Depends on:
%       * matRad_VOIOARFindIx(cst)
%       * matRad_VOIDoseThrMask(cst,doseCube,voiNames,doseThreshold)
%       * matRad_VOIHealthy(...)
%
% Author: Joana Leitão + GPT-5, 2025
% -------------------------------------------------------------------------

%% --- Defaults & input checks
if nargin < 3 || isempty(doseThreshold)
    doseThreshold = 6; % Gy
end
if nargin < 4
    voiSelection = [];
end
if nargin < 5 || isempty(includeHealthy)
    includeHealthy = true;
end

if ~isnumeric(doseCube) || ndims(doseCube) ~= 3
    error('doseCube must be a 3D numeric matrix.');
end
if ~iscell(cst) || isempty(cst)
    error('cst must be a non-empty matRad CST cell array.');
end

if nargin < 6 || isempty(minIslandVox3D), minIslandVox3D = 1; end
if nargin < 7 || isempty(minAreaVox2D),   minAreaVox2D   = 1; end

% voiSelection is numeric VOI indices (your convention)
if ~isempty(voiSelection)
    if ~isnumeric(voiSelection) || any(~isfinite(voiSelection)) || any(voiSelection < 1) ...
            || any(voiSelection ~= round(voiSelection))
        error('voiSelection must be empty or a vector of positive integer VOI indices.');
    end
    if any(voiSelection > size(cst,1))
        error('voiSelection contains indices outside cst (size(cst,1) = %d).', size(cst,1));
    end
    voiSelection = unique(voiSelection(:)','stable');
end

%% --- Find OAR VOIs (all)
oarIndicesAll = matRad_VOIOARFindIx(cst);

% Build list of OAR names from cst
oarNamesAll = {};
for k = 1:numel(oarIndicesAll)
    idx = oarIndicesAll(k);
    nameCell = cst{idx,2};
    if iscell(nameCell)
        oarNamesAll{end+1} = char(string(nameCell{1})); %#ok<AGROW>
    else
        oarNamesAll{end+1} = char(string(nameCell)); %#ok<AGROW>
    end
end

%% --- Determine which OARs to use
if isempty(voiSelection)
    % All OARs
    oarNamesToUse = oarNamesAll;
else
    % Subset by VOI indices -> translate to names
    oarNamesToUse = {};
    for j = 1:numel(voiSelection)
        ix = voiSelection(j);
        nm = cst{ix,2};
        if iscell(nm)
            nm = nm{1};
        end
        nm = char(string(nm));
        if ~isempty(nm)
            oarNamesToUse{end+1} = nm; %#ok<AGROW>
        end
    end
end

% Safety: if selection resulted in no names, fall back to all OARs
if isempty(oarNamesToUse)
    oarNamesToUse = oarNamesAll;
end

%% --- Build OAR above-threshold mask
flashOARmask = false(size(doseCube));

try
    maskTry = matRad_VOIDoseThrMask(cst, doseCube, oarNamesToUse, doseThreshold);
    if islogical(maskTry) && isequal(size(maskTry), size(doseCube))
        flashOARmask = maskTry;
    else
        error('Unexpected return from matRad_VOIDoseThrMask - fallback to per-VOI loop.');
    end
catch
    for v = 1:numel(oarNamesToUse)
        nm = oarNamesToUse{v};
        if isempty(nm), continue; end
        try
            m = matRad_VOIDoseThrMask(cst, doseCube, {nm}, doseThreshold);
            if islogical(m) && isequal(size(m), size(doseCube))
                flashOARmask = flashOARmask | m;
            end
        catch
            continue;
        end
    end
end

flashOARmask = logical(flashOARmask);

%% --- Healthy tissue (optional)
cstFLASH = {};

if includeHealthy
    try
        [healthyMask, cstNewTmp, healthyAboveThrMask] = matRad_VOIHealthy(cst, doseCube, doseThreshold, false); %#ok<ASGLU>
        flashMask = flashOARmask | healthyAboveThrMask;
    catch ME
        warning('matRad_VOIHealthy failed: %s', ME.message); %#ok<CHWARN>
        healthyAboveThrMask = false(size(doseCube));
        flashMask = flashOARmask;
    end
else
    flashMask = flashOARmask;
    healthyAboveThrMask = false(size(doseCube));
end

flashMask = logical(flashMask);

%% --- Build CST entries for output (one for OARs, optionally one for healthy)
baseEntry = cst(end,:);

% OARsFLASH entry
oarVoxelIdx = find(flashOARmask);
newOAREntry = baseEntry;
newOAREntry{2} = sprintf('OARsFLASH_{%.1fGy}', doseThreshold);
newOAREntry{3} = 'OAR';
newOAREntry{4} = {oarVoxelIdx};
if numel(newOAREntry) < 5 || isempty(newOAREntry{5})
    newOAREntry{5} = struct();
end
newOAREntry{5}.visibleColor = [1 0.5 0];

cstFLASH = newOAREntry;

% Healthy entry (if requested)
if includeHealthy
    healthyVoxelIdx = find(healthyAboveThrMask);
    newHealthyEntry = baseEntry;
    newHealthyEntry{2} = sprintf('HealthyFLASH_{%.1fGy}', doseThreshold);
    newHealthyEntry{3} = 'OAR';
    newHealthyEntry{4} = {healthyVoxelIdx};
    if numel(newHealthyEntry) < 5 || isempty(newHealthyEntry{5})
        newHealthyEntry{5} = struct();
    end
    newHealthyEntry{5}.visibleColor = [0.75 0.0 0.75];
    cstFLASH = [cstFLASH; newHealthyEntry];
else
    healthyVoxelIdx = [];
end

%% --- Optional: print how many voxels were affected (ONLY for VOI selection)
% Here, "voiSelection" is numeric indices. Only print if user provided it.
if ~isempty(voiSelection)
    nOAR     = numel(oarVoxelIdx);
    nHealthy = numel(healthyVoxelIdx);
    nTotal   = nnz(flashMask);

    % VOI names for nice printing
    selNames = cell(1,numel(voiSelection));
    for j = 1:numel(voiSelection)
        nm = cst{voiSelection(j),2};
        if iscell(nm), nm = nm{1}; end
        selNames{j} = char(string(nm));
    end
    selNames = selNames(~cellfun(@isempty, selNames));
    if isempty(selNames)
        selTxt = sprintf('%d ', voiSelection);
        selTxt = strtrim(selTxt);
    else
        selTxt = strjoin(selNames, ', ');
    end

    fprintf(['FLASH voxels above %.1f Gy in selected VOIs [%s] ' ...
             '(minIslandVox3D=%d, minAreaVox2D=%d): OAR=%d, Healthy=%d, Total(union)=%d\n'], ...
            doseThreshold, selTxt, minIslandVox3D, minAreaVox2D, ...
            nOAR, nHealthy, nTotal);
end

end