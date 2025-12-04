function [flashMask, flashOARmask, cstFLASH] = matRad_flashVoxels(cst, doseCube, doseThreshold, voiSelection, includeHealthy)
% matRad_flashVoxels - prepare voxel masks and CST entries for FLASH analysis
%
% Syntax:
%   [flashMask, flashOARmask, cstFLASH] = ...
%       matRad_flashVoxels(cst, doseCube, doseThreshold, voiSelection, includeHealthy)
%
% Inputs:
%   cst            - matRad CST cell array (VOI table)
%   doseCube       - 3D matrix of dose (Gy)
%   doseThreshold  - scalar threshold in Gy (optional, default = 6)
%   voiSelection   - cell array of VOI names to consider (optional, default = all OARs)
%   includeHealthy - logical, whether to compute healthy tissue above-threshold (optional, default = true)
%
% Outputs:
%   flashMask      - binary mask of all voxels above threshold (OARs + healthy if includeHealthy)
%   flashOARmask   - binary mask of OAR voxels above threshold (selected OARs only)
%   cstFLASH       - CST rows (one or two) describing the FLASH-affected VOIs:
%                      {OARsFLASH_row; (HealthyFLASH_row if includeHealthy)}
%
% Notes:
%   - This function relies on the following helper functions existing on path:
%       * matRad_VOIOARFindIx(cst)        -> returns indices of OAR VOIs in cst
%       * matRad_VOIDoseThrMask(...)   -> returns mask for given VOI name(s) above threshold
%       * matRad_VOIHealthy(...)       -> returns [cstNew, healthyMask, healthyAboveThrMask]
%   - No printing or file I/O is performed.
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

% Validate doseCube
if ~isnumeric(doseCube) || ndims(doseCube) ~= 3
    error('doseCube must be a 3D numeric matrix.');
end

% Validate cst
if ~iscell(cst) || isempty(cst)
    error('cst must be a non-empty matRad CST cell array.');
end

%% --- Find OAR VOIs (all) and apply voiSelection filter if provided
oarIndicesAll = matRad_VOIOARFindIx(cst);   % expected to return indices of OAR rows in cst

% Build list of OAR names from cst
oarNamesAll = {};
for k = 1:numel(oarIndicesAll)
    idx = oarIndicesAll(k);
    if numel(cst) >= idx && numel(cst(idx,:)) >= 2
        nameCell = cst{idx,2};
        if iscell(nameCell)
            oarNamesAll{end+1} = nameCell{1}; %#ok<AGROW>
        elseif ischar(nameCell)
            oarNamesAll{end+1} = nameCell;
        else
            oarNamesAll{end+1} = ''; %#ok<AGROW>
        end
    else
        oarNamesAll{end+1} = '';
    end
end

% Determine which OARs to use
if isempty(voiSelection)
    oarNamesToUse = oarNamesAll;
else
    % ensure voiSelection is cellstr
    if ischar(voiSelection)
        voiSelection = {voiSelection};
    end
    % keep only those OAR names that are in voiSelection (case-insensitive match)
    oarNamesToUse = {};
    for i = 1:numel(oarNamesAll)
        nm = oarNamesAll{i};
        for j = 1:numel(voiSelection)
            if ~isempty(nm) && ~isempty(voiSelection(j)) ...
                    && strcmpi(nm, cst{voiSelection(j), 2})
                oarNamesToUse{end+1} = nm; %#ok<AGROW>
                break;
            end
        end
    end
    % if none matched, try partial / case-insensitive matching (fallback)
    if isempty(oarNamesToUse)
        for i = 1:numel(oarNamesAll)
            nm = lower(oarNamesAll{i});
            for j = 1:numel(voiSelection)
                if contains(nm, lower(voiSelection(j)))
                    oarNamesToUse{end+1} = oarNamesAll{i}; %#ok<AGROW>
                    break;
                end
            end
        end
    end
    % final fallback: if still empty, use all OARs
    if isempty(oarNamesToUse)
        oarNamesToUse = oarNamesAll;
    end
end

%% --- Build OAR above-threshold mask
% Initialize
flashOARmask = false(size(doseCube));

% Try to call matRad_VOIDoseThrMask for the whole list at once if that helper supports it.
% Otherwise, call per-VOI and OR the results.
try
    % Some implementations accept a cell array of names; catch if not supported.
    maskTry = matRad_VOIDoseThrMask(cst, doseCube, oarNamesToUse, doseThreshold);
    if islogical(maskTry) && isequal(size(maskTry), size(doseCube))
        flashOARmask = maskTry;
    else
        % Unexpected return; fall back to per-VOI loop
        error('Unexpected return from matRad_VOIDoseThrMask - fallback to per-VOI loop.');
    end
catch
    % Per-VOI loop (robust)
    for v = 1:numel(oarNamesToUse)
        nm = oarNamesToUse{v};
        if isempty(nm); continue; end
        try
            m = matRad_VOIDoseThrMask(cst, doseCube, {nm}, doseThreshold);
            if islogical(m) && isequal(size(m), size(doseCube))
                flashOARmask = flashOARmask | m;
            else
                % ignore unexpected returns
            end
        catch
            % If a single VOI fails, skip it (robustness)
            continue;
        end
    end
end

%% --- Healthy tissue (optional)
cstFLASH = {}; % will be cell array of one or two rows compatible with cst row shape

if includeHealthy
    % matRad_VOIHealthy returns [cstNew, healthyMask, healthyAboveThrMask] per your provided signature
    try
        [cstNewTmp, healthyMask, healthyAboveThrMask] = matRad_VOIHealthy(cst, doseCube, doseThreshold, false);
        % healthyAboveThrMask: logical mask of healthy voxels > threshold (excluding targets)
        % Merge OAR and healthy above-threshold masks
        flashMask = flashOARmask | healthyAboveThrMask;
    catch ME
        % If call fails, be conservative: flashMask = flashOARmask
        warning('matRad_VOIHealthy failed: %s', ME.message); %#ok<CHWARN>
        healthyAboveThrMask = false(size(doseCube));
        flashMask = flashOARmask;
        cstNewTmp = cst; %#ok<NASGU>
    end
else
    % if not including healthy, flashMask is same as flashOARmask
    flashMask = flashOARmask;
    healthyAboveThrMask = false(size(doseCube));
end

%% --- Build CST entries for output (one for OARs, optionally one for healthy)
% Copy a base row from cst to preserve structure for new entries
baseEntry = cst(end,:); % row with same number of columns/structure

% OARsFLASH entry
oarVoxelIdx = find(flashOARmask);
newOAREntry = baseEntry;
% Name column assumed at {2}, Type at {3}, voxel indices at {4} per your matRad style
newOAREntry{2} = sprintf('OARsFLASH_{%.1fGy}', doseThreshold);
newOAREntry{3} = 'OAR';
newOAREntry{4} = {oarVoxelIdx};
newOAREntry{5}.visibleColor = [1 0.5 0];

cstFLASH = newOAREntry; % start

% Healthy entry (if requested)
if includeHealthy
    healthyVoxelIdx = find(healthyAboveThrMask);
    newHealthyEntry = baseEntry;
    newHealthyEntry{2} = sprintf('HealthyFLASH_{%.1fGy}', doseThreshold);
    newHealthyEntry{3} = 'OAR';
    newHealthyEntry{4} = {healthyVoxelIdx};
    newHealthyEntry{5}.visibleColor = [0.75 0.0 0.75]; % [0.5 0.75 0.75]
    % cstFLASH should contain both entries as rows (cell array with 1xN columns)
    % Format matching original cst: stack rows vertically
    cstFLASH = [cstFLASH; newHealthyEntry];
end

% Return cstFLASH as a cell array shaped like one/two rows of cst
end
