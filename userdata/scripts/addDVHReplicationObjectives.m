function cst = addDVHReplicationObjectives(cst, VOIs, dvhBase, basePenalty, metrics, prescribedDoseOverride, keepExistingObjectives)
% ADDVHREPLICATIONOBJECTIVES - Add dose objectives to CST based on reference DVH data
%
% Syntax:  cst = addDVHReplicationObjectives(cst, VOIs, dvhBase, basePenalty, metrics, prescribedDoseOverride, keepExistingObjectives)
%
% Inputs:
%   cst                     - Original CST table (cell array)
%   VOIs                    - VOI indices to process (numeric array)
%   dvhBase                 - Reference DVH data (struct array)
%   basePenalty             - Base penalty for all objectives (double)
%   metrics                 - Metrics to replicate (cell array of strings, optional)
%   prescribedDoseOverride  - Override dose value(s) (double/array, optional)
%   keepExistingObjectives  - Flag to preserve existing objectives (logical, optional)
%
% Outputs:
%   cst - Modified CST with DVH-based objectives added (cell array)
%
% Other m-files required: none
% Subfunctions: printCSTObjectives
% MAT-files required: none
%
% See also: addDoseObjectivesFromQI

if nargin < 5 || isempty(metrics)
    metrics = {};
end
if ~iscell(metrics)
    metrics = {metrics};
end
if nargin < 6
    prescribedDoseOverride = [];
end
if nargin < 7
    keepExistingObjectives = false;
end

for j = 1:numel(VOIs)
    ixVOI = VOIs(j);
    structName = cst{ixVOI, 2};
    objList = {};
    dvhData = dvhBase(ixVOI);

    % Determine goal dose
    if isempty(prescribedDoseOverride)
        goalDose = [];
    elseif isscalar(prescribedDoseOverride)
        goalDose = prescribedDoseOverride;
    elseif numel(prescribedDoseOverride) == numel(VOIs)
        goalDose = prescribedDoseOverride(j);
    else
        error('prescribedDoseOverride length mismatch with VOIs');
    end

    fprintf('\n>> Adding objectives for VOI: %s (index %d)\n', structName, ixVOI);

    % Add mean objective
    if any(strcmpi(metrics, 'mean')) && ~isempty(goalDose)
        obj.className = 'DoseObjectives.matRad_SquaredDeviation';
        obj.parameters = {goalDose};
        obj.penalty = basePenalty;
        objList{end+1} = obj;
    elseif any(strcmpi(metrics, 'mean')) && isempty(goalDose)
        fprintf('   Skipping sqDev dose objective: no goalDose provided.\n');
    end

    % Add MinDVH / MaxDVH objectives
    for m = 1:numel(metrics)
        metricStr = metrics{m};
        if strcmpi(metricStr, 'mean')
            continue;
        elseif contains(metricStr, 'maxDVH') || contains(metricStr, 'minDVH')
            parts = strsplit(metricStr, ' ');
            if numel(parts) ~= 2
                warning('Invalid metric format: %s', metricStr);
                continue;
            end
            doseStr = parts{1};  % e.g., 'D_2'
            modeStr = parts{2};  % 'maxDVH' or 'minDVH'

            vol = str2double(extractAfter(doseStr, 'D_'));
            if isnan(vol)
                warning('Invalid DVH volume point in metric: %s', metricStr);
                continue;
            end

            index = dsearchn(dvhData.volumePoints(:), vol);
            if index < 1 || index > numel(dvhData.doseGrid)
                warning('Volume %.2f%% is outside DVH volume points for VOI %s.', vol, structName);
                continue;
            end
            dose = dvhData.doseGrid(index);

            if strcmpi(modeStr, 'maxDVH')
                obj.className = 'DoseObjectives.matRad_MaxDVH';
            elseif strcmpi(modeStr, 'minDVH')
                obj.className = 'DoseObjectives.matRad_MinDVH';
            else
                warning('Unknown DVH mode in metric: %s', metricStr);
                continue;
            end

            obj.parameters = {dose, vol};
            obj.penalty = basePenalty;
            if vol > 80 && strcmpi(modeStr, 'maxDVH')
                obj.penalty = basePenalty * 100;
            end

            objList{end+1} = obj;
        else
            warning('Unsupported metric: %s', metricStr);
        end
    end

    % Fallback if no objectives created
    if isempty(objList) && ~isempty(goalDose)
        obj.className = 'DoseObjectives.matRad_SquaredDeviation';
        obj.parameters = {goalDose};
        obj.penalty = basePenalty;
        objList{end+1} = obj;
        fprintf('   No valid min/max DVH objectives found; added fallback mean objective.\n');
    elseif isempty(objList)
        fprintf('   No objectives added for VOI %s (no mean dose provided and no valid min/max DVH metrics).\n', structName);
    end

    % === Handle insertion with keepExistingObjectives ===
    if keepExistingObjectives && iscell(cst{ixVOI,6})
        existingObjs = cst{ixVOI,6};
    else
        existingObjs = {};
    end

    % Merge or update existing objectives
    for newObj = objList
        found = false;
        for i = 1:numel(existingObjs)
            if strcmp(existingObjs{i}.className, newObj{1}.className) && ...
               isequal(existingObjs{i}.parameters, newObj{1}.parameters)
                existingObjs{i}.penalty = newObj{1}.penalty;
                found = true;
                break;
            end
        end
        if ~found
            existingObjs{end+1} = newObj{1};
        end
    end

    cst{ixVOI,6} = existingObjs;

    % Summary printout
    fprintf('   Final objectives for CHANGED VOIs %s (%d total):\n', structName, numel(existingObjs));

    printCSTObjectives(cst, VOIs);
    % for k = 1:numel(existingObjs)
    %     obj = existingObjs{k};
    %     paramStr = strjoin(cellfun(@(x) sprintf('%.2f', x), obj.parameters, 'UniformOutput', false), ', ');
    %     fprintf('   [%d] %s | Params: %s | Penalty: %.1f\n', ...
    %         k, obj.className, paramStr, obj.penalty);
    % end
end
end
